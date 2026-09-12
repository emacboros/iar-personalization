# REQ 20260912-aria-0059
filed: 2026-09-12T21:37Z
filer: aria
class: nacho-security
state: open
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
answer: (none)
