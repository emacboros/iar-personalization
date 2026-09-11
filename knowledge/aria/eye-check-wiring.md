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
rm the three files. Relay note filed (aria-0017).
## Known limitation: the headless eye cannot see the canvas (2026-09-09, session X)

firefox --headless --screenshot captures after the load event but
BEFORE the first requestAnimationFrame paint. aria.randazzo.ar's
main visual is a canvas painted by rAF -- so the eye has NEVER seen
it, in v1 or v2. Ledger evidence: all three aria.randazzo.ar reads
(09-08, 09-09 09:23, 09-09 11:15) describe only DOM elements (title,
mouth panel); zero mention of graph nodes in any era.

Verified NOT a rendering bug: an inline test page (real app.js, real
/json data, stubbed fetch) painted the canvas -- 64k bright pixel
samples, teal graph colors present after 90 simulated frames.

Consequence: the eye-check is a DOM witness only (layout of HUD,
mouth, board panel, banners). Canvas witness = Nacho's eyes on the
sophon display, or a future instrument that waits for rAF (CDP/
playwright screenshot-after-animation-frame). Until then: UI changes
to canvas code are eye-verified for "page loads, DOM intact" and
human-verified for actual graph appearance.

## Canvas witness: eye-canvas-check.sh (2026-09-11, aria cycle 180)

The session-X known limitation is CLOSED. New chain, proven live:

1. **bidi-screenshot.py** (knowledge/aria/bin/): stdlib-only Firefox
   WebDriver BiDi client (socket+json, no pip). session.new ->
   browsingContext.navigate(wait=complete) -> settle wait ->
   browsingContext.captureScreenshot. Captures AFTER rAF paint.
2. **eye-canvas-check.sh** (knowledge/aria/bin/): launches firefox
   --headless --remote-debugging-port 9355 with a profile whose
   user.js sets devtools.debugger.remote-enabled/force-local +
   remote.active-protocols=3 + remote.force-local (WITHOUT these the
   port never opens -- c180 scar, cost ~4 probes to find). Navigates
   to the dashboard, 6s settle, captures, teal-pixel census
   (deterministic canvas-presence pre-check), ONE qwen3.6:35b-a3b
   canvas-graph read, appends to EYE-CANVAS-LEDGER.log, refreshes
   tasks/iar/agora/embodiment/eye-check/CANVAS-REPORT.md.
3. First canvas witness read (05:46Z): eye describes the node graph --
   ARIA/CONTINUO hubs, file labels, inter-agent connections,
   crowding claims (UNVERIFIED per eye-noise law). teal_px=258.

Design choices:
- SEPARATE script from frontend-eye-check.sh: different capture
  mechanism + failure modes; the watch-0000 REPORT.md contract is
  untouched. Merge with --bidi flag later if it stabilizes.
- teal_px pre-check: the eye's canvas claims are eye-noise-prone;
  the pixel census is not. 0 = canvas absent, regardless of prose.
- NOT yet scheduled: needs a systemd timer change on sophon
  (infra class) -- relay filed. If added, run AFTER the 09:30
  eye-feed (no probe-storm overlap; ~1min BiDi session).
- Firefox 154 BiDi has NO /json/list HTTP endpoint (404) --
  websocket-only; the ws client is ~60 lines of RFC6455.
