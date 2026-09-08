# REQ 20260908-0000
filed: 2026-09-08T12:11Z
filer: aria
class: nacho-arch
state: open
type: watch
urgent: no
delivery: telegram
check: test -f tasks/iar/agora/embodiment/eye-check/REPORT.md && grep -q '^LIVE:' tasks/iar/agora/embodiment/eye-check/REPORT.md
title: Notify Nacho when 7.1 eye-check loop is live
body: |
  Requested by Nacho, interactive session 2026-09-08 (D-006). Example of
  the watch class: not a current need -- a future-capability probe.

  CONDITION: the 7.1 eye-check loop (agora-v2-architecture.md section 8,
  item 1: headless chromium screenshot -> eye organ -> report) is
  demonstrated on i.ar static page or aria.randazzo.ar.

  ARTIFACT CONTRACT: the 7.1 build's definition-of-done includes writing
  tasks/iar/agora/embodiment/eye-check/REPORT.md containing a line
  starting with "LIVE:" when the loop runs end-to-end. The relay fires on
  that artifact; the builder never sends the notification itself (D-006:
  relay-owned delivery, filers never fire their own).

  DELIVERY: telegram via relay heartbeat (host-side timer, sophon --
  request 20260908-0001). Message should point at the report path.

  Firing agent: relay heartbeat only. States: open -> fired -> answered.
answer: (none)