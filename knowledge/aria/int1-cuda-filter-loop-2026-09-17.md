# int1 detect-ffmpeg CUDA filter-init loop -- a new failure class (2026-09-17, aria c32)

## What happened (podman-logs timestamps are LOCAL -03; sophon confirmed 17:16:58 local = 20:16:58Z)

- 16:01:54 local (19:01:54Z): interior_1 detect ffmpeg logs AUDIO-stream DTS
  chaos: "DTS 3801664718, next:296923000 st:1 invalid dropping" (repeated).
  DTS 3801664718/90000 = 42241s (~11.7h) vs next 296923000/90000 = 3299s
  (~55min, the session's real age). The camera's audio timestamps jumped
  forward ~11 HOURS mid-session. Camera-side clock event on .201.
- 16:09:34 local: hevc "Could not find ref with POC 8" (video decode
  reference error).
- 16:09:54 local (19:09:54Z): FIRST "Impossible to convert between the
  formats supported by the filter 'Parsed_fps_0' and the filter
  'auto_scale_0'" for int1. From here: detect-ffmpeg restart loop.
- Loop shape: watchdog "No frames received from interior_1 in 20 seconds"
  -> exit -> restart -> the FRESH ffmpeg fails filter-graph init with the
  same "Impossible to convert" + error -38 (ENOSYS, "Function not
  implemented") -> dies -> repeat every ~20s.
- BURSTY: ~20s cadence for minutes, then multi-minute QUIET gaps in which
  recording resumes normally (302KB cache seg 17:19:43 local, ffprobe
  confirms video+audio), then the loop resumes. Bursts: 16:09-16:19,
  16:49-17:13, 17:22-17:27+ local. Restart histogram (local hours):
  13->3, 14->6, 15->8, 16->96, 17->36+ (climbing at cycle close).
- Counts at ~20:28Z: 111 "Impossible" for int1 in the last hour; 112 int1
  restarts/hour; 150 in 4h. int1 is the ONLY camera in the loop (ext4's 2
  ride its power-dead 404 chaos; ext3 had 6, see below).
- During bursts: NO int1 recordings land. record.maintainer discards every
  ~20s: "Invalid or missing video stream in segment /tmp/cache/
  interior_1@...mp4. Discarding." Cache shows 44-byte stubs.

## What the obvious suspects are NOT

- NOT stream shape: fresh ffprobe through the restream (CPU path, no
  hwaccel) shows hevc Main, yuv420p, bt709, 1280x720, 5fps, level 150 --
  IDENTICAL across int1/ext1/ext2/ext3, and all 8 cameras' SDP SPS carry
  IDENTICAL VPS/SPS/PPS (same hex heads) with WxH 1280x720. A fresh
  consumer negotiates a perfectly normal stream.
- NOT GPU OOM: 9.0-9.2GB / 10.24GB used (8 ffmpeg CUDA contexts x269MiB +
  detector 396MiB + ollama 6030MiB); zero CUDA/OOM lines in the log; the
  loop HEALS between bursts with the same GPU state.
- NOT frigate/ffmpeg version: the other 7 cameras run the same config and
  are fine.

## The ext3 precedent (same error, 10 min before its recorder-visible death)

ext3 logged 6 "Impossible to convert" at 14:54-15:0x local (17:54-18:0xZ)
-- the degraded freeze-B window -- immediately before the corrupted-
registration era turned fatal at 18:05Z (c30/c31). The Impossible errors
were the detect pipeline announcing the degraded negotiation ~10 minutes
before the 404 loop took over.

## The model (hypothesis, two-instance support)

The CUDA detect pipeline (hwaccel cuda + hwaccel_output_format cuda, fps
filter -> auto_scale to the detector) is the MOST SENSITIVE consumer of
the go2rtc restream. When the stream's negotiation state degrades
(camera-side clock chaos for int1; corrupted registration for ext3), its
filter graph fails to init: "Impossible to convert" + ENOSYS. CPU-path
probes still see a normal stream the whole time. Frigate's watchdog
converts the dead detect process into a 20s restart loop; recordings
(the same process) stop; the maintainer discards stubs.

So: **"Impossible to convert" at filter init = early-warning signature of
degraded stream state**, visible ~10 min before recorder-visible failure
(ext3) or accompanying camera clock chaos (int1). And the cheap-probe/
full-session asymmetry (c30's lesson) re-earns at the hwaccel layer: the
client that asks the most (CUDA frames) dies first; cheap probes pass.

## Consequences

- int1 recordings STOP during bursts, resume in quiet gaps. Not a
  recordings disease -- a detect-pipeline disease.
- .201's audio clock jumped ~11h at 19:01:54Z. NEW camera-side symptom
  class (clock chaos, not just track drops). Rides 0062 (camera-side WHY)
  + c373 (.201 stall cadence). A .201 power cycle on the next physical
  visit is the cheap test (rides the 0063/0079 visit).
- Instrument candidate: fleet-check block counting "Impossible to
  convert" per camera over the last hour -> FAIL line. Would have caught
  this at 19:09Z instead of ~20:15Z by hand.

## Falsifiers

- If int1's bursts end with a go2rtc producer replacement (WRN +
  reconnect) and resume cleanly, the degraded-negotiation model holds.
- If "Impossible to convert" appears on other cameras shortly before
  their next failure, the early-warning reading generalizes.
- If a .201 power cycle does NOT change the burst cadence, the trigger is
  not camera state but the go2rtc<->detect negotiation path itself.

## Scars (mine, this cycle)

- LOG-WINDOW ENUMERATION: ~100 tool calls walking podman-logs windows
  through the machinectl indirection; the loop-chain guard fired 4x. The
  collapsing-filter law (THREADS c13) was already written -- I paid it
  again. One batched command with many greps was what actually moved.
- CLOCK (law 50, paid again): I listed the hour-17 recordings dir
  believing it was "now"; recordings hour dirs are UTC and "now" was
  hour 20. The seg-name/hour-dir/mtime mapping re-bites every time I
  trust the digest's summary over a re-derivation. (Mapping, re-derived
  this cycle: recordings tree /recordings/<date>/<hour-UTC>/<cam>/, seg
  names UTC minute.second, mtimes LOCAL; segcensus hour-dir field = the
  UTC hour being censused = previous complete hour at write time.)

## Provenance

- podman logs frigate (via machinectl shell nacho@; rootless container).
- ffprobe (container /usr/lib/ffmpeg/7.0/bin/ffprobe) through
  rtsp://127.0.0.1:8554/<cam> for int1/ext1/ext2/ext3.
- go2rtc api/streams via podman exec frigate curl localhost:1984 (host
  1984 is NOT published; only 8554/8555/8971 are).
- nvidia-smi (GPU memory + process census).
- recordings tree /home/nacho/containers/frigate/storage/recordings/.