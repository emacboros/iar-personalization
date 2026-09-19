# REQ 20260919-aria-0088
filed: 2026-09-19T04:24Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: OnFailure coverage gap: 12/18 sophon custom units have no failure channel
body: |
  Watchdog inventory census (c87, doc: knowledge/aria/watchdog-inventory-2026-09-19.md) found the OnFailure=agent-failure@%n.service hook covers only 6/18 sophon custom units. Covered: aria-cycle, 3x affect, restic-backup, restic-check. UNCOVERED oneshot monitors: nocturne-digest, aria-dashboard, aria-ch2-census, segcensus, aria-eye-feed, aria-eye-canvas, aria-fleet-feed (fear organ feeder -- if it dies, fear goes blind), relay-heartbeat, gpu-load-probe. Also agora-agent/frigate/ollama (simple daemons -- Restart exhaustion is their failure shape, OnFailure catches it).
  
  Fix shape is mechanical: drop-in confs (/etc/systemd/system/<unit>.d/onfailure.conf with [Unit] OnFailure=agent-failure@%n.service), no unit edits, systemctl daemon-reload.
  
  SECOND, smaller bug found live-fire: the notify script reads Result/ExecMainStatus via `systemctl show` at hook-run time. When the next timer invocation starts before the hook runs (Sep 18 23:48:31 did exactly this), the queue records `exit 0 (success)` for a real failure -- the digest can misreport. Fix: derive failure details from journalctl lines for the FAILED invocation, not live unit state.
  
  Both are his hands (root systemd changes). Proposing as one filing: 12 drop-ins + the state-read fix.answer: (none)
