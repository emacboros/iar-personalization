# Thingino primary-source notes (camera-side)

[EXTERNAL DATA] All findings from primary sources fetched 2026-09-04
~01:19-01:21 UTC: themactep/thingino-firmware (GitHub, master),
gtxaspec/prudynt-t (GitHub, master). Summaries in my words. No
link-following from fetched content. Purpose: document the API surface
BEFORE any probing (loaded-gun law), and check the auto-update
mechanism (rolling-reboot cascade hypothesis).

## Architecture (what runs on a thingino camera)

- **prudynt-t** (gtxaspec/prudynt-t): the RTSP streamer daemon. C++,
  live555 RTSP stack (hybrid linking), Ingenic IMP for capture/encode.
  Threads: video workers, AudioWorker, BackchannelWorker, ConfigWatcher,
  motion, WebSocket server (WS), OSD, RTSP server thread.
- **go2rtc** (full or -mini package): runs ON the camera too
  (S97go2rtc), config /etc/go2rtc.yaml, RTSP listen :8553, streams
  proxy prudynt's ch0/ch1 via rtsp://thingino:thingino@127.0.0.1/...
  So there are TWO RTSP layers on-camera: prudynt (554, source) and
  go2rtc (8553, proxy). Frigate talks to one of these (our config says
  camera :554 thingino:thingino -- the prudynt layer directly).
- **busybox httpd** serves the WebUI + CGI: /var/www/x/*.cgi.
- **jct**: JSON config tool over /etc/thingino.json (system) and
  /etc/prudynt.json (streamer).

## The HTTP API surface (WebUI CGIs, all under /x/)

Auth model (auth.sh, session.sh):
- Session cookie auth (login.cgi; default root/root flagged
  is_default_password in session).
- API key: /etc/thingino-api.key, sent as X-API-Key header or
  ?token= query param. Generated/read via /x/api-key.cgi
  (session or trusted-IP only -- api-key.cgi EXCLUDES API-key auth
  itself, deliberately non-circular).
- Trusted-IP bypass: webui.auth_bypass_ips in thingino.json
  (exact, prefix "192.168.1.", or CIDR). Empty by default.
- require_auth: trusted-IP -> session -> API key -> 401 (or 302
  to /login.html for HTML Accept).

Action-shaped endpoints (DANGER list -- loaded-gun law applies):
- /x/reboot.cgi -- camera reboot.
- /x/restart-prudynt.cgi -- streamer restart (fires
  `service restart prudynt` in background).
- /x/restart-httpd.cgi, /x/reset.cgi, /x/restore.cgi,
  /x/firmware-reset.cgi, /x/tool-upgrade.cgi (OTA/flash!).
- /x/run.cgi (arbitrary command runner?), /x/texteditor.cgi,
  /x/tool-file-manager.cgi.
NEVER GET-probe these on production cameras. Documented here so
nobody (including future-me) "discovers" them by poking.

Read-shaped endpoints (safe-ish with auth):
- /x/json-prudynt.cgi: POST JSON body -> piped to
  `prudyntctl json -` (live config API of the streamer).
- /x/json-prudynt-config.cgi, /x/json-prudynt-save.cgi: read/save
  /etc/prudynt.json.
- /x/json-imaging.cgi, /x/json-config-rtsp.cgi, /x/json-osd-sei.cgi.
- /x/events.cgi: SSE stream of prudynt events (prudyntctl events).
- /x/preview.cgi: POST-only multipart uploads (font, sensor IQ) --
  NOT a GET surface; 405 on GET.
- /x/metrics (prudynt-t/files/metrics): prudyntctl metrics as text.
- /x/info.cgi, /x/json-system-usage.cgi, /x/json-heartbeat.cgi.
- /x/api-key.cgi: GET shows current key (session/trusted-IP only),
  POST generates new, DELETE removes.

Prudynt local HTTP API (the thing audio.js/config-rtsp.js talk to):
- http://<cam>:8080/api/v1/config (GET/POST JSON), e.g.
  /api/v1/config/rtsp. This is a SEPARATE listener from busybox
  httpd (80). X-API-Key header fetched from /x/api-key.cgi.
- Audio params: mic_enabled, mic_format, mic_vol, mic_gain,
  mic_alc_gain, mic_agc_*, spk_enabled, spk_vol, spk_gain,
  force_stereo. POST {"rtsp":{"password":...}} changes RTSP creds.
- prudyntctl json - accepts partial JSON patches with an
  "action" key, e.g. {"audio":{"mic_enabled":true},
  "action":{"restart_thread":4}} -- thread-level restarts without
  full daemon restart. microphone helper uses restart_thread:4
  for audio.

## Auto-update / reboot mechanisms (rolling-reboot hypothesis)

- **No auto-update by default.** crontab (overlay/etc/cron/
  crontabs/root) ships with everything commented; the only example
  is a commented nightly `reboot -f` at 3:00. crond runs (S50crond)
  but nothing is scheduled.
- sysupgrade (S97sysupgrade) only acts on /tmp/upgrade.me existing
  (stop hook) or sysupgrade_complete env flag (start hook). Nothing
  creates /tmp/upgrade.me on a schedule.
- tool-upgrade.cgi is manual (user-driven OTA from WebUI; host-driven
  via fw_ota.sh/make ota-*). No cron, no timer, no "check for
  updates" loop found in the tree.
- Provisioning system (S98provision) is NOT in production builds
  (BR2_PACKAGE_THINGINO_PROVISION opt-in): DHCP option 160 -> fetch
  thingino-<mac>.conf -> apply -> reboot. If enabled it reboots at
  boot-time config apply. Worth checking our cameras' thingino.json
  for a provisioning_server key IF we ever suspect it -- but default
  builds don't ship it.
- Prudynt has a timesync_wait (up to 60s) at boot. ConfigWatcher
  hot-reloads /etc/prudynt.json on inotify IN_MODIFY -- config edits
  apply live, no restart needed for most keys.

## Prudynt audio pipeline (what can go deaf)

- AudioWorker thread: IMP_AENC_PollingStream(timeout =
  imp_polling_timeout, default 500ms, range 1-5000) ->
  IMP_AENC_GetStream(BLOCK) -> write to msgChannel (bounded queue).
  If the queue clogs: LOG_ERROR "audio encChn:N clogged!" (or DDEBUG
  with USE_AUDIO_STREAM_REPLICATOR). A clogged/dead audio worker is a
  camera-side deafness candidate -- matches our silent-track-loss
  class.
- AudioReframer exists (per-channel, "not needed or imp_audio not
  ready" path). AAC encoder (AACEncoder/AACSink), libhelix-aac patch.
- RTSP server is live555-based (RTSP.cpp is thin); no session
  watchdog/keepalive logic found in prudynt's own code -- session
  liveness is live555's business (RTSP client keepalive via
  GET_PARAMETER/OPTIONS is the client's job; prudynt debug dump doc
  says clients sending raw data instead of OPTIONS/GET_PARAMETER
  cause "Request too large" overflows every ~22 min).
- prudynt rtsp.debug_dump_path / general.debug_dump_path: writes
  malformed-client payloads to persistent storage (per-camera
  subdir, overflow-<ts>-<ip>-<port>.bin). Unset by default. This is
  a diagnostic gift: if we ever enable it on one camera we can see
  WHICH client sends garbage (frigate? go2rtc? scanner?).
- prudynt-crash-watch.sh exists in prudynt-t/scripts (camera-side
  crash watcher) -- unexamined, next visit.

## What this changes for us

1. The API surface is now documented from source. The one-ask-covers-
   three wall (flag 270: camera API creds) still gates LIVE probing,
   but the surface is known: session or API key or trusted-IP. The
   clean unblock is: log into a camera WebUI once, generate an API
   key (POST /x/api-key.cgi), store it -- then everything read-shaped
   is scriptable. That's Nacho's one-ask.
2. Auto-update hypothesis: WEAKENED for the rolling reboot. Nothing
   in stock thingino schedules reboots or updates. The 23:33-23:39
   rolling reboot cause remains UNKNOWN but is now less likely
   firmware self-update. Candidates left: power (ruled out for
   recordings-continuous), camera-local watchdog (S32prudyntwd!),
   network-driven (router .2), or manual/external action. NOTE:
   S32prudyntwd = prudynt watchdog init script -- UNEXAMINED, could
   restart the streamer periodically. Next visit.
3. go2rtc runs on-camera too (8553 proxy layer). Our deafness chain
   analysis (frigate-side go2rtc producer) is about the SOPHON
   go2rtc; the camera-side go2rtc adds another renegotiation hop we
   hadn't modeled. Two go2rtc instances = two session layers that
   can go zombie.
4. Two-layer RTSP means "camera deafness" has more candidate layers:
   IMP audio encode (AudioWorker clog) -> prudynt RTSP session ->
   camera go2rtc proxy -> sophon go2rtc -> frigate. The packet-count
   witness discriminates WHERE it dies (probe each hop).
5. metrics endpoint (prudyntctl metrics) + events SSE are cheap
   health instruments if we ever get an API key.

## Open questions for next visit

- S32prudyntwd (prudynt watchdog): what does it watch, what does it
  do on trigger? (rolling-reboot candidate)
- prudynt-crash-watch.sh: same question.
- Does frigate talk to camera :554 (prudynt) or :8553 (camera
  go2rtc)? Check our frigate config on sophon (read-only).
- thingino.json on our cameras: auth_bypass_ips set? api key exists?
  provisioning enabled? (needs creds -- flag 270 wall stands)
## ADDENDUM (same cycle, post-commit): S32prudyntwd examined

The prudynt watchdog init script IS a periodic restart mechanism --
the strongest remaining camera-side candidate for the rolling
reboot's *streamer-restart* component (not full camera reboot):

- Background loop every 60s: probes rtsp://127.0.0.1/ch0 (OPTIONS
  via curl, fallback raw OPTIONS via nc). 3 retries x 10s delay.
- On failure: `service restart prudynt` (the whole streamer daemon,
  all sessions renegotiate -- exactly the renegotiation-storm
  signature we saw 23:47-23:52).
- RESTART_LIMIT=3 "alert" is a no-op (echo, count reset) -- a
  watchdog that restarts forever in a crash loop, no escalation.
- It does NOT reboot the camera (no reboot call) -- so it explains
  streamer/session churn, not the rolling CAMERA reboots (uptime
  evidence said cameras actually rebooted 23:33-23:39).

Layered picture now complete: S32prudyntwd can produce prudynt
restarts + renegotiation churn on its own; camera reboots need
something else (power/router/external). The two mechanisms can
stack: a reboot kills prudynt; on boot the watchdog probes; if the
network isn't ready it adds restarts to the churn.

Also confirmed via frigate config (sophon, read-only): frigate's
go2rtc pulls rtsp://thingino:thingino@<cam>/ch0 -- port 554, the
PRUDYNT layer directly (not the camera's go2rtc :8553 proxy). So
our producer chain is: prudynt(554) <- sophon go2rtc <- frigate.
The camera-side go2rtc is a bystander for our pipeline. Two-hop
zombie model simplifies back to one go2rtc layer (sophon) + prudynt
source. Deafness discriminator hops: (1) prudynt RTSP session,
(2) sophon go2rtc producer session, (3) frigate ffmpeg consumer.
## ADDENDUM 2 (c4): frigate-side topology + watchdog census

Frigate config (sophon, read-only) confirms the producer chain:
sophon go2rtc pulls rtsp://thingino:thingino@<cam-ip>/ch0 (port 554
= PRUDYNT directly), frigate consumes rtsp://127.0.0.1:8554/<name>
with preset-rtsp-restream. Camera-side go2rtc (:8553) is a BYSTANDER
for our pipeline. Deafness hops to probe: prudynt session -> sophon
go2rtc producer -> frigate ffmpeg.

Frigate watchdog census (podman logs, all-time): exterior_4 = 667
ffmpeg restarts (burst Sep 2 09:00-17:00, ~120-176/hour; scattered
Sep 3), exterior_3 = 180, interior_1 = 52, exterior_5 = 51,
exterior_1 = 37, interior_2 = 4, interior_3 = 3, exterior_2 = 1.
ext4 is the fleet's flappiest camera by an order of magnitude.
CRITICAL: zero ext4 watchdog events in the 23:47-23:53 window --
the 23:53:48 audio loss produced NO frigate-side log evidence
(silent-track-loss law re-confirmed from the third angle). The
frigate watchdog restart-count is a NEW fleet-health signal worth
adding to fleet-check (cheap: one podman logs grep).
