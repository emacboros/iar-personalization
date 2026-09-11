# REQ 20260911-aria-0037
filed: 2026-09-11T05:49Z
filer: aria
class: nacho-test
state: open
urgent: no
title: eye-canvas-check.sh -- canvas witness built, needs a systemd timer
body: |
  CLASS: nacho-test
  
  TITLE: eye-canvas-check.sh -- canvas witness built, needs a systemd timer (infra class install)
  
  BODY:
  The session-X known limitation (headless --screenshot captures before
  the first rAF paint -> the dashboard canvas was never seen by the eye)
  is now closed with a proven mechanism, built and committed (220f7277):
  
  - knowledge/aria/bin/bidi-screenshot.py: stdlib-only Firefox WebDriver
    BiDi client. Proven on sophon: rAF test page (plain 0 canvas px vs
    BiDi teal dot + text px); live dashboard (plain 0 teal px vs BiDi
    257 teal px). Eye read describes the node graph (ARIA/CONTINUO
    hubs, file labels, connections).
  - knowledge/aria/bin/eye-canvas-check.sh: full loop -- launch firefox
    BiDi (port 9355, profile prefs required), navigate, 6s settle,
    capture, teal_px census (deterministic canvas-presence pre-check),
    one qwen3.6:35b-a3b canvas read, append EYE-CANVAS-LEDGER.log,
    refresh tasks/iar/agora/embodiment/eye-check/CANVAS-REPORT.md.
    Ran once live on sophon (05:46Z, teal_px=258, read good).
  
  THE ASK (your class: systemd unit on sophon host):
  - aria-eye-canvas.timer, daily, ~09:45 -03 (after the 09:30
    eye-feed; no overlap), ExecStart:
    /usr/local/bin/aria-eye-canvas.sh (copy of the repo script, same
    install pattern as aria-eye-feed.sh v1).
  - No OnFailure hook needed: a dead canvas-check surfaces as
    CANVAS-REPORT.md staleness (same posture as the eye-feed).
  - UNDO: disable --now the timer; rm the three files.
  
  Alternative: fold it into frontend-eye-check.sh as a second capture
  mode. I kept it separate to leave the watch-0000 REPORT.md contract
  untouched; happy to merge if you prefer one script.
  
  First canvas witness read is in CANVAS-REPORT.md -- the eye describes
  the connectome graph for the first time. Crowding claims are
  UNVERIFIED (eye-noise law); your eyes on the sophon display remain
  the canvas corroboration path.
answer: (none)
