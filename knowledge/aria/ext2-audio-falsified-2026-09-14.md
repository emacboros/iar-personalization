# EXT2 AUDIO: the class-3 prediction FALSIFIED -- 2026-09-14 (c341)

## The prediction (relay 0067, c335)

"Next record-proc restart heals ext2 audio." The theory: .102's
camera reboot (09-14 ~01:00Z) renegotiated its stream; the
long-lived recording_manager (etime 4d19h, started 09-01) kept
its stale negotiation and wrote video-only segments; a restart
would re-negotiate and heal.

## What the census found (c341)

Full-history shape census of ext2 segments (53,887 files,
07-05 -> now), 12-point probe + binary searches:

1. The transition is NOT at a record-proc restart. The exact
   boundary: 09-14 15:33:47 (AUDIO, 33.21.mp4) -> 15:34:07
   (video-only, 33.47.mp4). One segment boundary. No restart, no
   journal event, no gap at that minute (33.37.mp4 missing is a
   routine motion-gated hole; ext1 has the same shape).
2. The recording_manager has NOT restarted since 09-01
   (etime 4-19:55h at 23:38Z). It is writing video-only segments
   RIGHT NOW while the LIVE stream (probed twice: camera .102
   directly AND the go2rtc restream 127.0.0.1:8554/exterior_2)
   carries hevc,video + aac,audio. The record proc is eating a
   stream that HAS audio and writing segments WITHOUT it.
3. There was a PREVIOUS identical episode: 09-08, video-only span
   10:13 -> 16:59 sophon (~6h46m), self-healed WITHOUT any
   restart (frigate journal has no record-proc restarts; journal
   retention only reaches 09-12, but the segment tree shows the
   heal). So the class is: intermittent, hours-long, self-healing
   negotiation staleness INSIDE the record proc's ffmpeg
   pipeline.

## Revised model

Class 3 is not "stale until restart" -- it is a periodic
renegotiation failure in the recording pipeline's audio path
(go2rtc -> record proc ffmpeg), which sometimes self-heals and
sometimes persists for hours+. The record-proc-restart prediction
is FALSIFIED as a necessary mechanism (09-08 healed without one).
It may still be sufficient (a restart would likely re-negotiate),
but the causal story "camera reboot -> stale negotiation -> fix
by restart" is wrong: the live stream is healthy; the record
proc's CONSUMER side dropped audio on its own.

## What would decide it

- Watch for the next self-heal: if ext2 flips back to AUDIO
  without a restart, class 3 = fully self-healing, and the
  restart prediction dies completely.
- The 09-08 episode is in the segment tree only (journal
  retention 09-12+). If it recurs, correlate with go2rtc producer
  reconnects (the 15:33:28 i/o-timeout burst across .103/.201 is
  suspiciously close to the 15:34 transition -- 1 minute later).

## Action

- Relay 0067 amended: prediction falsified, new model, watch for
  self-heal.
- No restart requested: the episode self-heals (09-08 precedent);
  a restart is Nacho's call and now has weaker justification.

[EXTERNAL DATA]: none -- house-internal (frigate recordings,
journals, live probes).