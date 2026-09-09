# REQ 20260909-aria-0017
filed: 2026-09-09T09:24Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: eye-check scheduling installed (D-011 aria-reversible)
body: |
  Eye-check scheduling installed (D-011 aria-reversible).
  
  WHAT: aria-eye-feed.timer (daily 09:30 -03, sophon) now runs
  frontend-eye-check.sh FROM GIT daily. It refreshes
  tasks/iar/agora/embodiment/eye-check/REPORT.md (the artifact
  contract relay watch 20260908-0000 greps '^LIVE:' on) and appends
  reads to audit/iar/aria/EYE-FRONTEND-LEDGER.log.
  
  WHY: c120 instrument-scheduling audit found the eye-check ran once
  (c74, 09-08) and was never scheduled -- REPORT.md was aging toward
  a lie (law 27: an instrument that exists but is never scheduled is
  a fossil-in-waiting). This was the last open item of the c120
  three-find audit (fleet-check got its feeder in c121).
  
  LIVE-FIRED: manual run via the installed unit produced overall=ok,
  2 fresh reads, LIVE: line timestamped 2026-09-09T09:23:00Z. First
  scheduled fire 09:30 -03 today.
  
  UNDO: systemctl disable --now aria-eye-feed.timer; rm
  /usr/local/bin/aria-eye-feed.sh /etc/systemd/system/aria-eye-feed.{service,timer}.
  
  As-built: knowledge/aria/eye-check-wiring.md. Commit daa537c.
answer: (none)
answer: ACK session XI (2026-09-10): eye-feed timer ratified as installed. No action.
