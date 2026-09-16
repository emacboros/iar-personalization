# REQ 20260912-aria-0059
filed: 2026-09-12T21:37Z
filer: aria
class: nacho-security
state: answered
urgent: no
title: frigate 8971 (+8554/8555) internet-exposed via firewall high-port range
body: |
  Finding (c267): frigate's published port 8971 (nginx UI) is reachable
  from the internet through sophon's firewall (FedoraWorkstation zone
  allows 1025-65535/tcp on enp10s0). Observed today: 45.138.12.14 (171
  requests), 195.178.110.67 (12), plus a few one-offs -- scanner
  payloads (.env, wp-config, phpinfo, git config). They get 200s on
  static paths (frigate's SPA index serves for unknown paths) and 401s
  on /api/* -- auth held, no breach. But the surface is live.
  
  Options (your call, none urgent):
  1. Bind 8971 to WG-only (podman publish 10.66.0.5:8971 instead of
     0.0.0.0) -- cleanest; you lose direct-LAN access unless you keep a
     LAN binding too.
  2. firewalld: restrict the high-port range or add a drop rule for
     8971 from non-WG sources.
  3. Leave it (auth is holding; scanners get noise).
  
  Note the same zone allows 1025-65535 for everything else published --
  go2rtc 8554/8555 are also exposed the same way (RTSP creds are
  thingino:thingino in URLs; they were NOT observed being probed today,
  but the surface exists).
answer: OPTION 1 chosen 2026-09-16 (interactive session). All four published ports (8971, 8554 tcp, 8555 tcp+udp) now bind 10.66.0.5 (WG) only. camaras.randazzo.ar STAYS public (caddy -> WG -> 8971, unaffected). Executed: live compose.yml edited + container recreated 18:48Z; ansible template + defaults updated (frigate_bind_addr: 10.66.0.5, commit bd2b598, pushed rammstein+sophon-bare; github push failed -- key issue, needs Nacho). Verified: LAN direct 8971/8554 closed, WG path 200, caddy 200, 7/8 cameras up (exterior_4 power-dead 0063), detections flowing, MSE live view unaffected (142 ws hits, zero webrtc consumers). 0064 folds here: RTSP-port probe surface closed for non-WG sources.
## ADDENDUM (2026-09-13 01:27Z, aria c275): scanner activity continues; auth holding

Fresh 6h read of frigate nginx access (via podman logs, 18:00-22:19
local window): the exposure is still live and still being probed.

- 18:00:49 local: GET /.env -> 200 (2655 bytes = SPA index; benign
  static-serve, no leak) from a Chrome-UA scanner.
- 19:28:45 local: GET / from Palo Alto Networks Cortex XSOAR scanner
  (self-identified; documented scan).
- 21:25:19 local: GET /.git/config -> 200 (SPA index again) from
  172.86.81.82.
- 22:19:27-36 local: metabase-cve-2026-72898-detect/1.0 from
  2a01:4f8:1c1a:9a65::1 + 91.99.239.28 -- GET /api/session/properties
  and POST /api/session/reset_password x3. ALL /api paths -> 401.
  Auth held; no breach. Notably these arrived VIA
  camaras.randazzo.ar (Caddy proxy), i.e. the public domain path, not
  only the direct 8971 route.

Pattern unchanged since filing: scanners get 200s on static SPA
paths and 401s on /api. The ask stands (bind 8971 WG-only, or
firewalld restrict, or accept). New data point: the Caddy-proxied
public path (camaras.randazzo.ar) is ALSO being probed -- so option
1 (WG-only bind) alone would not close the public surface; the
Caddy route would still expose it. If you want the surface closed,
the firewalld/Caddy-layer decision matters too.
evidence-addendum (aria c311, 2026-09-14 ~09:00Z):
  New scanner burst: 34.156.22.222 (Google Cloud), 91 requests in the
  nginx ring (05:50:13-16 local 09-14), Chrome/128 UA, GET / + ~20
  .env-variant paths (laravel, vendor, wp-content, server, sendgrid,
  panel, media, env.txt, env.production.js...). Same class as the
  original finding: 200s on static paths, auth holding on /api/*.
  Third distinct scanner IP observed. Surface still live; still your
  call (options unchanged above).
