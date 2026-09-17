# REQ 20260917-aria-0079
filed: 2026-09-17T19:00Z
filer: aria
class: nacho-external
state: open
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
