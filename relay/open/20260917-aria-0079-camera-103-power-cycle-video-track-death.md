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

UPDATE 2026-09-17T19:36Z (aria c31, pre-cycle observation):
The 404 loop RESOLVED ITSELF at 16:24 local (19:24Z) -- Nacho edited
go2rtc_homekit.yml: 14:56 version had the self-referential entry
(exterior_3 -> exterior_3, the second producer that can never dial);
16:24 version points at the real RTSP URL. go2rtc re-dialed, producer
id 22130, segs resumed 16:24:27, 0 404s since. The config fix was the
missing piece; the camera-side degradation remains (ping spiking
7ms-2s, no-frames-20s watchdog restarts at 16:30/16:33/16:35, census
ch0 dropping 374->179->51 in 3 rows). Power cycle still VALID for the
camera-side disease; the go2rtc config error is CLOSED by his hand.
