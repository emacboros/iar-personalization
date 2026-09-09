# Eye-check scheduling -- as-built (2026-09-09, cycle 122)

The c120 audit's last open law-27 item: frontend-eye-check.sh ran
once (c74, 09-08 12:49Z), wrote REPORT.md, and was never scheduled.
This note records the fix, same purpose as fear-fleet-wiring.md.

## The chain now (verified end-to-end, live-fired)

1. **aria-eye-feed.timer** (daily, OnCalendar=*-*-* 09:30) ->
   aria-eye-feed.service (root, oneshot, no OnFailure hook).
2. **aria-eye-feed.sh** runs frontend-eye-check.sh FROM GIT
   (/var/home/nacho/repos/iar-personalization/knowledge/aria/bin/
   frontend-eye-check.sh -- the version in git IS the running
   version, the standing rule). Never exits nonzero.
3. **frontend-eye-check.sh** writes/refreshes
   tasks/iar/agora/embodiment/eye-check/REPORT.md (the artifact
   contract relay watch 20260908-0000 greps '^LIVE:' on) and
   appends reads to audit/iar/aria/EYE-FRONTEND-LEDGER.log.
4. The relay heartbeat (existing, sophon) greps the report on its
   own cadence -- the watch's delivery path is unchanged.

## Live-fire verification (c122)

- Manual run via the installed unit path: report refreshed with a
  fresh LIVE: line and timestamp; ledger got 2 new READ lines
  (i.ar + aria.randazzo.ar); overall=ok. First scheduled fire
  09:30 -03 09-09.
- The watch 0000 was ALREADY FIRED by c74's run (state: fired,
  awaiting Nacho's answer) -- this schedule does not re-fire it;
  it keeps the artifact fresh for the NEXT watch class.

## Design choices

- Daily cadence: the eye is a witness, not an instrument (c19) --
  one read/day is enough to catch layout breakage and keep the
  report honest without burning eye-model cycles.
- No OnFailure hook: a dead eye-feed surfaces as REPORT.md
  staleness (the generated: line ages), which is exactly the
  failure the next watch on this artifact would catch. Failure
  surfaces where the meaning lives.
- 09:30 -03 chosen to sit between the 06:00 and 12:00 fleet-feed
  fires -- no probe-storm overlap.

## Install record (D-011 aria-reversible)

Files: /usr/local/bin/aria-eye-feed.sh (v1),
/etc/systemd/system/aria-eye-feed.{service,timer}. Enabled
09:2x -03 09-09. UNDO: systemctl disable --now aria-eye-feed.timer;
rm the three files. Relay note filed (aria-0016).