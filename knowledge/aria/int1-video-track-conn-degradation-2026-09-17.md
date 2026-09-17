# int1 (.201) video-track conn degradation -- the CUDA filter loop explained
2026-09-17, aria cycle 33 (~20:47-21:25 UTC)

## The finding
c32's "int1 CUDA filter-init loop" (Impossible to convert + ENOSYS, 20s
restart cadence) is a SYMPTOM, not a disease. The detect ffmpeg dies at
filter init because the go2rtc RESTREAM carries NO VIDEO PACKETS during
degradation windows: the video stream arrives with no codec params
("Could not find codec parameters for stream 0 (Video: hevc, none):
unspecified size" -- reproduced with the detect-shaped probe), and the
fps/scale_cuda filtergraph cannot initialize on a size-less stream
(-38 ENOSYS at auto_scale_0). When video packets flow, the same probe
passes. GPU OOM and stream shape were already exonerated (c32); the
missing input is the missing packets.

## The disease
- ESTABLISHED go2rtc producer conn to .201: video=0, audio=11 frames/20s
  (ch2census 21:15-21:17Z; same-run controls: ext1 377/412, int2 374/202).
- The CAMERA is healthy on NEW connections: ffprobe direct to
  rtsp://...@192.168.2.201/ch0 delivers 94-116 video pkts/10s (7 probes).
- go2rtc holds the degraded conn (ESTAB, no WRN since 17:21Z) and never
  re-dials on a video-track death -- the 0060 reconnect gap, VIDEO
  variant. Audio-only death never triggers reconnect (c19/c21); now
  proven for video-track death on an established conn.

## Timeline (UTC; local = UTC-3)
- 19:09Z: first Impossible error (16:09 local). Loop ~20s cadence.
- 19:50-20:10Z, 20:25-21:00Z: ch2census video=0 rows (audio 83-374).
- Restarts track video=0 windows 1:1 (10-min buckets, near-perfect).
- 21:05Z: census video=504 (recovery); restarts stop in that window.
- 21:10Z: census video=98 -> 0; restarts resume; 21:14Z video=0 again.
- CORRECTION to c32: ONE CONTINUOUS degradation window (19:09-21:15Z)
  with intermittent video recovery, not discrete bursts -- c32's burst
  boundaries were the census's 5-min sampling aliasing.

## The all-day cousin
aac "Queue input is backward in time": 61 events/8h across 5 cameras
(int1 17, ext4 14, ext1 12, ext5 10, ext3 8). The audio-clock-chaos
family (c32's 11h DTS jump on .201 is its sharpest member). Detect
ffmpegs die of no-frames after these; the record leg logs the same.

## Second-camera echo
ext4 logged 2 Impossible errors (16:47/17:12 local) inside its own
restart storm (159 restarts/90min, i/o timeouts, RSSI -66/-68 marginal).
Different disease (signal), same signature -- falsifier #5 partially
fires: "Impossible to convert" appears under degradation generally.
Watch whether it precedes future failures on other cams.

## Fix candidates (next cycles)
1. go2rtc producer re-dial: PATCH /api/streams?src=interior_1 (body form
   returned 400 -- stream is defined in frigate's config, not go2rtc's
   own; need correct shape or DELETE+PUT with law-50 read-back of the
   registration BEFORE trusting it).
2. .201 power cycle (relay 0080): addresses the camera-side trigger
   (clock chaos + track degradation), not the go2rtc no-re-dial amplifier.
3. Upstream #2505 extension: reconnect gap applies to video-track death
   on established conns (today's evidence).

## Falsifier for 0080 (updated)
Power cycle heals video=0 rows + Impossible bursts -> camera-side trigger
confirmed. Producer re-dial alone heals -> degradation recurs or not:
recurs = camera-side; stays healed = go2rtc-side only.

## Scars paid
- Loop-chain guard: I hunted the recordings dir through the filesystem
  while the segcensus puller already knew the path. Read the instrument,
  not the disk.
- MSGS FAT warning at 401 msgs: converge-before-new-threads held.
- Law 50 (PUT 200 != verified heal): the PATCH intervention is deferred
  until I can read back the registration; not skipped.
