# aria-dashboard -- generator + UI (v1.0, 2026-09-07)

Centralized status for the house: agents, rotation, burn, affect,
services, host. JSON-first; the HTML is a render for the always-on
screen (sophon display, sci-fi cortex visual).

## Layout
- `bin/aria-dashboard.sh` -- generator. Reads audit/ + probes, writes
  `/var/lib/caddy/aria-dashboard/dashboard.json` (+ `json` symlink)
  and syncs `dashboard/ui/*` into the served dir. Repo version IS the
  running version (unit ExecStarts this file from the sophon clone).
- `dashboard/ui/` -- index.html, app.js, style.css. Vanilla JS, canvas
  cortex, no build step.

## Endpoint
- Public: `https://aria.randazzo.ar` (UI) and `/json` (schema
  aria-dashboard/v1). Caddy on rammstein proxies to sophon:8095;
  sophon caddy serves the dir (WG-bound :8095).
- Agents: query `http://10.66.0.5:8095/json` directly (no DNS).

## Privacy contract (public-unauthenticated)
Counts, states, ages, model names, cycle numbers ONLY.
NEVER: secrets, REQUESTS.log tails/specs (prompt fragments), journal
or thinking text, tenant data. If a field would embarrass a public
gist, it does not ship.

## Deploy (sophon, root)
1. `cp knowledge/aria/systemd/aria-dashboard.timer /etc/systemd/system/`
   `cp knowledge/aria/systemd/aria-dashboard.service /etc/systemd/system/`
2. `systemctl daemon-reload && systemctl enable --now aria-dashboard.timer`
3. First run: `systemctl start aria-dashboard.service`
4. SELinux: `semanage port -a -t http_port_t -p tcp 8095` (once);
   dir is under /var/lib/caddy (httpd_sys_content_t via caddy's own
   context inheritance -- verify with `ls -Z`).
5. Caddy site (sophon): :8095 handle /json -> file dashboard.json,
   rest -> file_server root /var/lib/caddy/aria-dashboard.
6. rammstein: caddy_sites entry (Ansible) + DNS (done 2026-09-07).

## Differential test (before trusting)
- `curl -s http://10.66.0.5:8095/json | jq .schema` -> aria-dashboard/v1
- Kill generator, check UI shows STALE banner after 15 min.
- Compare burn24h sum vs manual USAGE.log window sum.