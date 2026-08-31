# SecPlatform Split-Brain (found 2026-08-31, cycle 44)

## The finding

Production traffic for app.i.ar / app-bo.i.ar / auth.i.ar does NOT
hit the sophon stack. It hits a full stack copy running ON
rammstein, fronted by Cloudflare. The sophon stack (sp-prod-*) is
idle: its bff-client has served ZERO real requests since Aug 21
02:50 UTC (only 10s-cadence health checks; the only non-health
lines since Aug 17 are my own probes from this cycle).

## Evidence chain (all from sophon, read-only)

1. sophon postgres audit_log: 127 rows, span Aug 16 17:32 ->
   Aug 21 02:50 UTC, then silence. Last row: vuln.retest by
   poc.acme@customers.local at 02:50:00.447.
2. sophon KC event_entity: 171 events, same span (Aug 16 ->
   Aug 21 02:49). events_expiration=0, so nothing purged -- the
   silence after Aug 21 is real, not retention.
3. sophon bff-client req log: ids 116000+ all /health, 10s
   cadence. Non-health since Aug 17: 6 lines, all mine today.
4. Live probe: GET https://app.i.ar/api/auth/login through CF
   returns 302 with FRESH state+PKCE per request => a LIVE bff
   serves production. sophon bff req ids did not move during the
   probe => the live bff is not sophon's.
5. rammstein:8443 (SNI app.i.ar) serves the full app: /api/me
   401 with BFF helmet headers, /api/auth/login fresh 302s,
   /api/health 200. Latency from sophon ~125-135ms (WG RTT +
   processing) vs 1-3ms for sophon ports => the stack is ON
   rammstein.
6. sophon KC issuer and rammstein KC issuer are identical
   strings (configured hostname), but latency distinguishes:
   8443 well-known 135ms vs sophon:8080 2.5ms => rammstein runs
   its OWN Keycloak.
7. CF evidence: server: cloudflare headers, cf-ray, 2a09:bac1::/32
   client IPs in sophon KC events from Aug 18 onward => Cloudflare
   was in the path BEFORE Aug 21. sophon KC events Aug 16-17 come
   from 181.28.154.180 (Telecom Argentina residential) = direct
   pre-CF era.

## Timeline reconstructed

- Aug 16-17: direct-to-origin era. Real client IPs (181.x) hit
  sophon. 110 events from 181.28.154.180 including 76 LOGIN_ERRORs
  (invalid_client_credentials sweeps, user_not_found probes for
  test/nonexistent@..., 2 temporary lockouts) -- pattern reads as
  the developer iterating on config from a home IP, not an attack
  (successful logins of owner@sec.local + poc.acme follow from the
  same IP).
- Aug 18+: CF edge IPs (2a09:bac1::/32) appear => Cloudflare added
  ~Aug 18, still proxying to SOPHON at that point.
- Aug 21 02:49-02:50 UTC: last sophon-served login + audit row.
  After this, traffic switches to the rammstein stack.
- Aug 17 01:31 AR: current sophon containers started (2 weeks up).
  Aug 21+ sophon = idle except health checks.

## What my injected knowledge gets wrong now

- "No Cloudflare" -- FALSE. CF is in the path (server: cloudflare,
  CF IPv6 clients, CF challenge pages on auth.i.ar root).
- "Caddy on rammstein terminates TLS and reverse-proxies over
  WireGuard to sophon" -- FALSE for SecPlatform. rammstein serves
  the whole app locally (port 8443 origin for CF).
- "SecPlatform prod runs on sophon via podman compose" -- the
  sophon compose stack exists and is healthy but serves no traffic.

## Open questions (need rammstein access or Nacho)

1. What DB does the rammstein stack use? Its own postgres on a
   2c/4GB VPS, or sophon's? (If its own: user data now lives on
   the VPS, and the backup story for it is unknown -- rammstein
   backups were not in my map either.)
2. Is the rammstein stack deployed from the same repo/Ansible role,
   or hand-rolled? The sophon service (secplatform-prod.service)
   still runs and would "restore" an idle stack on reboot.
3. Which stack is authoritative going forward? If rammstein is
   prod now, the sophon stack + its 127 audit rows + 12 KC users
   are a stale fork that will drift further.
4. The KC data split: sophon KC has 12 users + 171 events ending
   Aug 21. rammstein KC has whatever happened since. If the
   rammstein stack was seeded fresh, any user created after
   Aug 21 exists ONLY there.
5. My iar-prod knowledge file (and infra overview) needs a rewrite
   once the real topology is confirmed.

## Method note

The tell was a log that kept being healthy while its service was
unused: 51k log lines, all health checks, req ids advancing --
"alive" and "used" are different claims. Cross-check: does the
request counter move when I send traffic? The 401-with-helmet
response from rammstein:8443 initially looked like "the sophon BFF
answered without logging" -- impossible; the resolution was that a
SECOND identical stack existed. When evidence contradicts, suspect
the map, not the territory.