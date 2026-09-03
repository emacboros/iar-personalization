# Camera firmware inventory (prudynt-t / thingino web build)

Written 2026-09-03, cycle 9, during the audio-loss real-fix arm.
Question from the roadmap: which prudynt-t build are the 8 cameras
on? Feeds the firmware-update decision (the "real fix" arm of the
audio-loss decision tree).

## What the probes found

All 8 cameras (192.168.2.101-105, .201-.203) answer HTTP with the
thingino web UI (`<title>thingino</title>`). One camera's root page
(192.168.2.101) carries:

    data-asset-ts="1779707526"

which decodes to **2026-05-25 11:12:06 UTC**.

The prudynt-t silent-audio session-state fixes (thingino-firmware#1462,
viliampucik, merged 2026-08-13) are ~2.5 months NEWER than that asset
stamp. If the asset-ts tracks the firmware build (it is the cache-
busting timestamp of the web UI assets, which ship inside the firmware
image), the cameras run a May build that predates the fix.

## Caveats (honesty)

- asset-ts is the WEB ASSET build stamp, not necessarily the prudynt-t
  binary version. A firmware could ship new prudynt-t with old assets
  (unlikely but possible). Confirming the binary version needs either
  the thingino JSON-RPC (see below) or ssh on the camera.
- Only .101's asset-ts was read in cycle 9. Uniformity across the 8
  is expected (same install batch) but not yet verified.

## The API wall (learned the hard way, ~6 probe variants)

This thingino build does NOT answer on the endpoints the current
webui repo suggests:

- `GET/POST /mjsonrpc`, `/jsonrpc`, `/api/*`, `/op/*`, `/about`,
  `/manifest.json`, `/version` -> all redirect to `/` (httpd catch-all).
- Raw RTSP OPTIONS on :554 -> connects (CSeq echoed) but NO Server
  header on any of the 8 cameras. prudynt-t does not advertise itself.
- thingino's webui repo (themactep/thingino-webui) serves cgi-bin/*.cgi
  -- but these cameras' httpd redirects even /cgi-bin paths probed.

Remaining version paths, for a future cycle:
1. `POST http://<cam>/mjsonrpc` may need auth (thingino has admin
   auth; unauthenticated requests may bounce). FOR-NACHO has the open
   question from cycle 18 about camera API credentials.
2. thingino runs dropbear ssh on the camera (port 22) -- firmware
   version in /etc/os-release or `prudynt -v`. Needs camera ssh creds.
3. The firmware image filename often encodes the build date; visible
   in the web UI's system page (behind auth).

## The decision this feeds

Audio-loss root cause (cycle 8): cameras stop SENDING audio-RTP on
long-lived RTSP sessions; prudynt-t has shipped exactly this class
of bug (session-state decay, fixed Aug 13). Palliative lever:
frigate restart (fresh producer sessions). Real fix: firmware update
to a post-Aug-13 build.

The May-25 asset stamp says the cameras are old enough that the
update path is live and worth doing. Next concrete step for Nacho:
check thingino's firmware release page for the camera models, or
grant camera API/ssh creds so the version can be confirmed exactly.

[EXTERNAL DATA] thingino-firmware#1462, prudynt-t#51/#74 via GitHub
API 2026-09-03; asset-ts read directly from camera HTTP.
## Uniformity confirmed (cycle 9, same session)

All 8 cameras report the same two asset stamps:
- .101-.105: 1779707526 = 2026-05-25 11:12:06 UTC
- .201-.203: 1779706276 = 2026-05-25 10:51:16 UTC

Two build stamps, 21 minutes apart, same day -- one install batch,
two firmware images (or one image flashed in two waves). ALL cameras
are May-25 builds, ~2.5 months before the prudynt-t audio session
fixes (Aug 13). The firmware-update arm of the decision tree applies
to the whole fleet, not just the three deaf cameras.

The 21-minute split also matches the ext1-5 vs interior_1-3 naming
split -- likely two flash sessions of the same build. No camera is
on a newer prudynt-t than any other.