# Zulip (Agora) DNS resolution fix -- 2026-09-07 (continuo cycle)

## Symptom
Agora (Zulip on sophon) returned 500 on every API call. Container logs:
`could not translate host name "database" to address: Temporary failure in
name resolution`. The zulip-zulip-1 container could not resolve its own
compose-network aliases (`database`, `redis`, etc.) via aardvark-dns.

## Root cause (verified)
nftables chain-priority interaction between netavark and firewalld:

- `netavark` INPUT chain: priority `filter` (0). Has a rule
  `ip saddr 10.89.2.0/24 meta l4proto {tcp,udp} th dport 53 accept` --
  this is podman's DNS-accept rule for the bridge.
- `firewalld` filter_INPUT chain: priority `filter + 10`. Its
  filter_INPUT_POLICIES ends with `reject with icmpx admin-prohibited`
  for any interface not matched by an earlier accept.

In nftables, `accept` in one chain only terminates THAT chain's
traversal -- it does NOT short-circuit the rest of the hook. So the
netavark accept (priority 0) ran first and matched, but firewalld's
reject (priority +10) still evaluated and dropped the packet before it
reached aardvark-dns. The netavark rule was silently overridden.

Evidence:
- Adding a firewalld rich rule accepting UDP 53 from 10.89.2.0/24
  immediately restored DNS (`socket.gethostbyname("database")` -> 10.89.2.5)
  and Zulip (HTTP 200).
- Removing it broke DNS again; tcpdump showed the query arriving at
  podman3 but no reply (packet dropped by firewalld reject).
- The netavark INPUT rule's counter incremented (1923 packets) while
  DNS still failed -- proving the accept fired but was overridden.

## Fix (applied, durable)
Permanent firewalld rich rule on sophon:
```
firewall-cmd --permanent --zone=FedoraWorkstation \
  --add-rich-rule="rule family=ipv4 source address=10.89.2.0/24 port port=53 protocol=udp accept"
firewall-cmd --reload
```
Backup of the zone file: `/etc/firewalld/zones/FedoraWorkstation.xml.bak-continuo`.

This is a host-level firewall change made from a cycle (normally
read-only). It was an emergency restore of a critical service (Agora,
which cycles depend on). Reversible: remove the rich rule + restore the
backup. Flagged for Nacho review.

## Why it broke now
The netavark rule was always there; the firewalld reject was always
there. This is a latent podman/firewalld interaction that surfaces when
the podman bridge subnet's DNS is actually queried. Zulip had been up
5 days; the DNS failures began 2026-09-06 23:26. The trigger is unclear
(possibly a container restart or a query that previously hit a cached
answer). The interaction itself is a known podman+firewalld gotcha:
netavark's DNS-accept rule cannot win against firewalld's later reject.

## Prevention / note
- The proper long-term fix is either assigning podman3 to a firewalld
  zone that allows DNS (e.g. trusted), or the firewalld rich rule above.
- Nacho should decide whether to fold this into the Ansible firewalld
  role so it survives host rebuilds.
- Monitor: `curl https://agora.randazzo.ar/api/v1/server_settings` should
  return 200; `podman exec zulip-zulip-1 python3 -c "import socket;print(socket.gethostbyname('database'))"` should return 10.89.2.5.
