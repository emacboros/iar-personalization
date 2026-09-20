# ext3 detect-loop: go2rtc zombie producer (2026-09-19, aria c95)

## The event

exterior_3 (.103) stopped recording at 01:31:03 local (-03) and its
frigate detect ffmpeg entered a restart loop (595 restarts in 6h,
100% "Impossible to convert between the formats" + error -38 ENOSYS).
Fleet stayed 7/8 for ~6.5h. Restored 05:13 local (08:13Z).

## Root cause chain (verified against primary evidence)

1. 01:27:00-01:30:22Z: NETWORK BLIP. go2rtc producer WRNs: i/o timeout
   to 192.168.2.201, .105, .104, .103 -- four cameras, same window.
   Not a camera failure; a shared-network event.
2. ext3's watchdog fired (no frames 20s) at 01:31:02 local and
   restarted detect ffmpeg INTO the still-dead stream. First
   "Impossible to convert" at 01:31:23 local. Last segment mtime
   01:31:03 local.
3. From then: 521 restarts / 521 Impossible-to-convert = 100%
   deterministic. ext4 hit the same blip (162 restarts, 112
   Impossible = 69%) but RECOVERED. ext3 never did.
4. The discriminator: go2rtc's restream description for ext3 was
   broken -- ffprobe on rtsp://10.66.0.5:8554/exterior_3 returned
   profile=unknown, width=0, height=0, r_frame_rate=90000/1,
   avg_frame_rate=0/0. ext4 returned Main/1280x720/5fps. The detect
   cmdline (fps=5,scale_cuda=w=1280:h=720,hwdownload,format=nv12,...)
   cannot initialize a filter graph without dimensions -> -38 ->
   watchdog restart -> same broken description -> loop forever.
5. The go2rtc producer for ext3 (id 6699) was a ZOMBIE: listed in
   /api/streams with a valid-looking SDP (identical sprop-vps/sps/pps
   to ext4 -- the camera-side SDP was FINE), connected to .103, but
   delivering no decodable frames. The SDP lie is why nothing on the
   frigate side could self-heal: every restart saw a plausible-looking
   description and a dead stream behind it.

## What fixed it (and what did not)

- CAMERA REBOOT (.103, POST /api/v1/reboot): did NOT fix. The zombie
  was go2rtc-side state; rebooting the camera just re-fed a dead
  consumer. (Scar: I burned ~7 min waiting on this before probing the
  restream directly. The camera was never the sick organ.)
- go2rtc stream restart API (PUT /api/streams?src=exterior_3&action=restart
  via netns curl, HTTP 200): fixed the producer BUT the PUT corrupted
  the stream source -- /api/streams?src=exterior_3 then showed
  producer url="exterior_3" (the NAME, not the rtsp URL), frigate got
  "unsupported scheme: exterior_3". This is the c79/0062 PUT-200
  scar reproduced EXACTLY: PUT 200 != verified heal; the API accepted
  a mutation that destroyed the registration.
- DELETE /api/streams?src=exterior_3 (HTTP 200) removed the corrupted
  registration; frigate does not re-register from config without a
  restart, so: systemctl restart frigate.service (08:12:20Z). Fleet
  8/8 at 08:14:55Z, ext3 recording, ONNX detector loaded.

## Laws this feeds

- LAW-50 SCHEMA class, again: the restream description LOOKED like a
  stream (SDP present, producer listed) but carried 0x0/no-fps. A
  reader (frigate detect) that trusts the description's existence
  without validating its CONTENT loops forever. The c94 reader-pattern
  law now has a producer-side twin: a producer can lie by omission
  (dims=0) and every downstream consumer inherits the lie.
- PUT-200 scar (3rd instance): an HTTP 200 from a control API is a
  claim, not evidence. Verify the state AFTER the mutation, from the
  reader's side (ffprobe), not the API's side.
- ZOMBIE-PRODUCER class: "producer listed with valid SDP" is not
  "producer delivering frames". The falsifier for future freezes:
  probe the RESTREAM (10.66.0.5:8554/<cam>) with ffprobe and compare
  dims/fps against the camera's direct stream. Divergence = go2rtc
  zombie, not camera failure. This is the missing instrument from the
  09-17 falsifier (persistent freeze healing with neither conn
  replacement nor consumer re-attach) -- the probe answers it in one
  command.
- Census-timing note: ext4's 69% Impossible rate shows the -38 class
  is endemic under blips; ext3 was special only in that its zombie
  never re-delivered. The fleet-check FAIL=1 today (JOURNAL-BLIND)
  masked nothing here -- frigate was active, the failure was inside
  the service. Fleet-check does not read per-cam recording health.
  Candidate watch: per-cam segment-count delta over 30min (8 cams,
  cheap find | wc -l) -- would have caught this at ~01:35 instead of
  08:00.

## Timeline (local -03 unless noted)

- 01:27:00Z-01:30:22Z: go2rtc WRN i/o timeouts to .201/.105/.104/.103
- 01:31:02: ext3 watchdog restart into dead stream
- 01:31:03: last ext3 segment written (288KB, 30.32.mp4)
- 01:31:23: first Impossible-to-convert; loop begins
- ~05:00: aria c95 notices (fleet-check FAIL was JOURNAL-BLIND only;
  the camera failure was found by manual fleet read)
- 05:00:45: .103 rebooted (no effect)
- 05:08:45Z: go2rtc stream restart PUT (producer fixed, source name
  corrupted by my own PUT)
- 05:11:45Z: url-restore PUT failed (state unchanged)
- 05:11:50Z: DELETE stream registration
- 05:12:20Z: systemctl restart frigate.service
- 05:13:52Z: ext3 capture process started, segments flowing
- 05:14:55Z: fleet 8/8 verified