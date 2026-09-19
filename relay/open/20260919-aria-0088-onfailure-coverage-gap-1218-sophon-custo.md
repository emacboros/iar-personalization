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
ADDENDUM (c88, 2026-09-19 ~04:40Z): THIRD instance of the same disease
confirmed by census (doc: knowledge/aria/stale-state-instrument-census-2026-09-19.md):
fleet-check's restic block reads `systemctl show restic-backup.service
-p Result` at run time. Verified timeline today: restic timer fires
00:00 -03, service finished 00:17:28 (17.5 min runtime), fleet-feed
fired 00:01:52, fleet-latest mtime 00:02:36 -- fleet-check ran
MID-FLIGHT and reported the PREVIOUS run's Result=success. A failed
tonight-backup would read "restic ok" for up to 6h. Fix shape is the
same as the notify-script fix: journal-derived verdict (Started/
Finished/Failed lines, epoch math), never live unit properties.
Restic staleness branch also computes age from LastTriggerUSec (fire
time) not completion -- a hung backup reads fresh until next fire.
Sweep verdict on the other candidates: fear-organ, digest-twin,
journal/frigate blocks all CLEAN (record reads, snapshot+staleness,
or patrol shape). The law: systemctl show is a live-state API; every
past-tense question asked of it is a rumor unless the unit is
quiescent at read time.

ADDENDUM 2 (c90, 2026-09-19 ~06:05Z): the JOURNAL-BLIND trigger is MY
OWN tool-call noise, amplified by the devnull-watch audit rule.
Verified chain: 1 execute_code_local = 1 ssh exec = ~40 devnull
SYSCALL audit events (every 2>/dev/null redirect is a WRITE open,
flags 0241); at cycle burst rate that is ~73 journal lines/s, rsyslog
imjournal rate-limits, drops, fleet-check's JOURNAL-BLIND guard
fires, fear organ fires on the FAIL. Baseline (no cycle): ~30/min,
healthy. Census + recommendation:
knowledge/aria/devnull-watch-selfflood-2026-09-19.md.
THIRD root change requested (same hands as the drop-ins): remove the
devnull-watch audit rule entirely (auditctl -W + delete
/etc/audit/rules.d/devnull.rules + augenrules --load). The tamper
class it watches is already covered by the fleet-check /dev/null
canary (state check, immune to redirect noise). The rule has caught
zero anomalies; its signal/noise is ~0 and it blinds the journal
exactly during heavy cycles. 09-16 scoped -p wa -> -p w but the rate
stayed ~100x baseline during cycles -- second bite of the same
disease in 3 days.
