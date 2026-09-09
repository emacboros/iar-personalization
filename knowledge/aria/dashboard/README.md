# aria-dashboard -- generator + UI (v2.1, 2026-09-10, interactive w/ Nacho)

Centralized status for the house: agents, rotation, burn, affect,
services, host, AND the live connectome (D-013). JSON-first; the HTML
is a render for the always-on screen (sophon display). Every visual
element maps to a data source -- the D-013 rule. The v1 decorative
cortex mesh is gone; the graph is built from measured co-firing,
file-touch, and shared-file edges in dashboard.json (schema
aria-dashboard/v2).

## Layout
- `bin/aria-dashboard.sh` -- generator. Reads audit/ + probes, writes
  `/var/lib/caddy/aria-dashboard/dashboard.json` (+ `json` symlink)
  and syncs `dashboard/ui/*` into the served dir. Repo version IS the
  running version (unit ExecStarts this file from the sophon clone).
- `dashboard/ui/` -- index.html, app.js, style.css. Vanilla JS, canvas
  cortex, no build step.

## Endpoint
- Public: `https://aria.randazzo.ar` (UI) and `/json` (schema
  aria-dashboard/v2). Caddy on rammstein proxies to sophon:8095;
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

## The mouth (oracle)
- `bin/aria-oracle.sh` + `systemd/aria-oracle.service`: stateless chat on
  sophon localhost:8096 (User=caddy, no tools, reads only context.txt).
  Public path: rammstein TLS -> sophon caddy :8095 -> localhost:8096.
  Rate limit lives IN the service (token bucket 10 req/60s per IP) --
  caddy core has no rate_limit directive. Model granite4.2:3b, 16k ctx,
  no logging of Q/A. Repo version IS the running version.

## Board semantics (v2.1)
- `board()`: working = a commit touched the task in the last 12h;
  thinking = task exists, idle >= 12h; done = top-level task dir
  removed < 7d (house convention: remove_task on completion) +
  standing-patrol artifacts. State derives from GIT HISTORY and the
  removal convention, never mtimes or hand-edited status fields.
  (v1.9 used file mtimes -- a pull or a sprint burst made a parked
  task look "working"; Nacho caught it 09-10.)

## Open questions (v2.1)
- `open_questions()`: the relay/open/ queue -- questions awaiting
  Nacho, oldest first. Ships header fields only (id/class/urgent/
  title/age_h); bodies NEVER ship (bodies can carry prompt
  fragments; the public-gist rule). The UI renders this as the
  open-questions tab: when the list grows, it's time for an
  interactive session.
- The oracle context blob gains the same list (top 10).

## The connectome layer (v2)
- `connectome()` in the generator: 24h window over sophon audit logs
  ONLY (cycle traffic -- Nacho-ratified session X; the weekly
  snapshot in knowledge/aria/connectome/ stays the full-population
  instrument, both hosts). Emits: cofire edges (tool pairs within 5s,
  top-12 per agent, weight = count), file-touch top-10 per agent,
  shared_files (touched by BOTH citizens -- the corpus callosum),
  token percentiles (p50/p90/p99/max per agent), fires_24h
  (tail-anchored stop=length), silence_24h (max PARSE gap + >600s
  count), fence_rejections_24h, burn_series (24 hourly tokens_in
  buckets from REQUESTS.log PARSE lines -- sophon CYCLE traffic;
  USAGE.log burn24h additionally includes interactive sessions).
- UI mapping: nodes = agents (pinned midline) + tools + files;
  edges = measured cofire/file/callosum with weight-scaled width;
  ambient pulses walk real edges weighted by real weight; rotation
  turn = callosum pulse burst; new fire = red pulse. Board panel =
  board() digest. HUD adds ctx p50/p90, fires, max silence, fence.
- Canvas blindness: the headless eye-check cannot see the canvas
  (rAF timing -- see knowledge/aria/eye-check-wiring.md). Canvas
  witness = human eyes. DOM witness = the eye.

## Differential test (before trusting)
- `curl -s http://10.66.0.5:8095/json | jq .schema` -> aria-dashboard/v1
- Kill generator, check UI shows STALE banner after 15 min.
- Compare burn24h sum vs manual USAGE.log window sum.