# REQ 20260917-aria-0079
filed: 2026-09-17T19:00Z
filer: aria
class: nacho-external
state: answered
urgent: no
title: camera .103 power cycle: video-track death, recordings stopped 18:05Z
body: |
  ext3 (.103, thingino) VIDEO track died on the producer conn ~18:05Z
  2026-09-17; audio still flows. go2rtc cannot re-establish the video
  session (read i/o timeout on every dial), so the restream 404s and
  frigate ffmpeg 404-loops: NO ext3 recordings since 18:05Z (55+ min and
  counting). Camera is up (HTTP 200, RTSP answers control fast) but
  degraded (ping 344ms avg vs 22ms for .101; malformed RTP header WRN at
  14:52Z). Diagnosis doc:
  knowledge/aria/ext3-video-death-restream-404-2026-09-17.md
  
  REQUEST: physical power cycle of camera .103 on next visit (rides the
  same visit as .104 power-dead, relay 0063). No remote fix attempted --
  reboot via thingino HTTP API is possible but I chose not to poke
  camera firmware state remotely without a ruling.
answer: (none)

## ANSWERED 2026-09-17 (interactive session, Nacho): REMOTE REBOOT AUTHORIZED + EXECUTED + ROOT CAUSE FOUND

Ruling (standing, stated clearly): "we are wasting time on the
cameras, they are really not that important... I'm lifting the
observation-only mode... feel free to do anything with or inside them
without the need for permission. Again, cameras are just a
nice-to-have, not critical at all. So b) it is."

EXECUTED (19:21-19:27Z):
- Remote reboot via thingino run.cgi (reboot -f, same as the camera's
  own cron) at 19:21:50Z. Camera back in <60s, ping 16.8ms (was 344ms
  degraded).
- ROOT CAUSE of the 18:05Z death found during the heal: my 17:56Z
  stream-reload "heal" for the falsifier wedge had CORRUPTED the
  stream registration -- DELETE(400) + PUT(200) re-registered the
  stream with the NAME as the source URL ("unsupported scheme:
  exterior_3" in go2rtc log). The segments that resumed at 17:56Z
  were the OLD producer still running; when it died at 18:05Z,
  nothing could re-dial. The 0079 death was MY OWN broken
  registration, not camera degradation. (The malformed RTP WRN at
  14:52Z and the 344ms ping were real camera-side symptoms of the
  wedge, but the 18:05Z death itself was the corrupted registration.)
- FIXED: DELETE + PUT with the correct source
  (rtsp://thingino:thingino@192.168.2.103/ch0&name=exterior_3).
  Producer dialed (22130), frigate reconnected, segments resumed
  16:24 local. Ear-check 19:26Z: ext3 audio healthy (-41.2 dB), all
  7 alive cameras carrying audio.

SCAR (law 50 family): an API PUT that returns 200 is not a verified
heal -- the PUT silently accepted a malformed source (name-only) and
the failure mode was DEFERRED (old producer kept running, death came
when it died). Verify the WRITE's semantic effect (read back the
registration, confirm the source URL), not just the status code.
Also: "unsupported scheme" in go2rtc logs at 16:02-16:23 was the
corrupted registration announcing itself for 2 hours before anyone
read it.

Camera standing mode (Nacho, 09-17): full access, no permission
needed, cameras = nice-to-have. The 0063 (.104 power cycle) remains
the only camera item needing physical presence.
