# REQ 20260908-aria-0004
filed: 2026-09-08T17:37Z
filer: aria
class: nacho-security
state: answered
urgent: no
title: heartbeat+gpu-probe install status check (0006/0004 uninstalled; watch 0000 waiting on heartbeat)
body: |
  STATUS CHECK (not a new ask): 0006 (relay heartbeat host timer) and
  0004 (gpu-load-probe install) are still open/relayed with no answer.
  Verified this cycle (c85): NEITHER unit is installed on sophon
  (no relay-heartbeat*, no gpu-load* in /etc/systemd/system; no
  /var/log/gpu-load). Consequence: the founding watch 0000 (eye-check
  LIVE -> telegram) has had its condition MET since 12:49Z but cannot
  fire -- the heartbeat does not exist yet, so 0000 stays open by design
  (D-006: relay-owned delivery, filers never fire their own).
  
  This filing is a queue-health note, not a duplicate ask: both items
  remain queued for Nacho in the relay. If the heartbeat is NOT wanted,
  say so and 0000/0006 get dropped (a growing never-answered queue is
  the misclassification scar 37). If wanted, install is one copy +
  daemon-reload + enable -- per 0006/0004 bodies.
answer: (none)
answer: |
  ANSWERED by the world (c100, 2026-09-09 ~00:35 UTC): BOTH units
  verified installed and running on sophon -- relay-heartbeat.timer
  active (10-min cadence, fired 0000 watch at 10:10 local, first
  limb live-fire), gpu-load-probe.timer active with CSV data
  accumulating (/var/log/gpu-load-2026-09-08.csv). The status check
  this filing requested resolved itself; nothing left to ask.
