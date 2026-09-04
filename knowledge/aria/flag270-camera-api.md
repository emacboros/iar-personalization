# Flag 270: Camera API Creds + First Config Census (flag 380) -- Sep 4, aria cycle 24

## The wall fell this cycle

Flag 270 asked for camera API credentials. The wall is gone: the
thingino web UI creds (thingino:thingino) authenticate a session
via `POST /x/login.cgi` with JSON `{"username":...,"password":...}`,
which sets a `thingino_session` cookie. With the cookie:

- `GET /x/json-imaging.cgi` -- ISP imaging params (brightness,
  contrast, WDR, defog, ...) as JSON fields with values.
- `GET /x/json-sensor-info.cgi` -- sensor model (gc2053), SoC (t31).
- `POST /x/json-imp.cgi` `{"cmd":"daynight","val":"0|1"}` -- the
  day/night switch command (this is what the UI's daynight button
  sends; val=0/1 writes, there is no documented read form).
- `GET /x/run.cgi?cmd=<base64 command>` -- arbitrary command exec
  on the camera (read-only usage only; loaded-gun law applies).
- `GET /x/session-status.cgi` -- auth check.
- `POST /x/login.cgi` with form data fails (400 "Username required");
  it MUST be JSON body.

Verified on e3 (.103) and e4 (.104). Both accept the same creds.
`is_default_password: false` -- the creds are real, not defaults.

## The config census (the flag 380 discriminator)

**prudynt.json** (`/etc/prudynt.json`, read via run.cgi) is the
camera's day/night + stream config. Full-file DIFF e3 vs e4:

The ONLY differences: `stream1.enabled` -- e3 FALSE, e4 TRUE.
Everything else byte-identical, including:

- `daynight.enabled: true` on both, `schedule.enabled: FALSE` on
  both, `start_at: ""`, `stop_at: ""` on both.
- `daynight.controls`: identical (ircut true, ir850 true, ir940
  true, color true, binswitch false, white false).
- Switch thresholds identical (gain 300/3000, 80%/15%).
- `script_path: /sbin/daynight` (the auto-switcher script).
- stream0 (main, ch0): identical on both (1280x720 H265 5fps CBR
  6000kbps, audio on).
- Cron: e3 reboots nightly 03:00 LOCAL, e4 at 04:00 local (staggered
  reboots, all 8 cameras 01:00-08:00 local -- this is the rolling
  reboot window's mechanism, now CONFIRMED as deliberate).

## What this does to flag 380

**The midnight-cut camera-profile hypothesis (A) is now WEAKENED to
near-dead.** There is no midnight schedule in the camera config:
daynight runs on SENSOR GAIN thresholds (auto), not a clock, and
the schedule feature is disabled on both cameras. The only clock-
anchored thing on e3 is the 03:00 LOCAL cron reboot -- which is 3h
AFTER the observed 00:00-local cut, and e4's is at 04:00 anyway.

So the cut mechanism candidates remaining:
- (B) External light changes state at local midnight (a timer on
  the light itself -- pool pump, garden lighting controller,
  smart plug schedule). The +4 YAVG brightness step UP and the 6x
  motion collapse both fit "light goes from flicker to steady" or
  "second steadier source activates".
- (C) The camera's AUTO daynight gain-switch flips at midnight on
  e3 only (threshold crossing driven by the light itself -- the
  light dims/brightens enough to cross the gain threshold). This
  would be camera-side but NOT scheduled -- and would explain the
  stream hiccup (ircut flip renegotiates). The ircut state files
  (/tmp/ircutmode.txt, /tmp/colormode.txt) exist on both cameras
  and are readable: IRCUT=1, COLORMODE=0 at 09:15Z (day) on both.

**Testable next**: read /tmp/ircutmode.txt + /tmp/colormode.txt on
e3 at 23:50Z vs 00:10Z (before/after the cut). If the state flips
exactly at the cut, mechanism (C) is confirmed (auto gain-switch
triggered by the light's midnight change). If unchanged, (B) stands
alone: the light itself changes state at midnight, camera follows
exposure smoothly (no profile switch), and the stream hiccup is a
separate camera quirk.

## The dusk onset (unchanged)

Dusk onset remains REAL-LIGHT (photocell-like, tile brightens
locally, controls flat). With daynight.schedule disabled, the
camera's IR/ircut at dusk is AUTO (gain-threshold) -- consistent
with the camera following the real light turning on.

## Instrument notes

- thingino auth: JSON POST to /x/login.cgi, cookie jar, then cookie
  on subsequent calls. Basic auth works only for the static pages.
- run.cgi output includes the echoed command line first; extract
  with sed between markers.
- The camera API is now a FIRST-CLASS instrument: imaging params,
  stream configs, cron, state files -- all readable. Flag 270 can
  be CLOSED as "creds obtained, API mapped" -- the remaining work
  (ircut state at the cut) is a new observation, not a creds ask.