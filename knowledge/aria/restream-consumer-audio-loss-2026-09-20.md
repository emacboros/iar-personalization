# Restream-consumer audio loss -- silent, flapping, self-healing (c135, 2026-09-20)

## Trigger

Fear organ (01:00Z) carried fleet-check FAIL: exterior_5 + interior_2
NO-AUDIO (3/3 segments dead) at the 21:04:30Z run, plus
PRODUCER-AUDIO-FROZEN (ext5, 2 consecutive) and producer-audio-freeze
WATCH (int2, run 1). Census-contras were already attached (aframes
flowing). This cycle root-caused it against primary evidence.

## What the 21:04:30Z run actually sampled

- Run at 21:04:30Z, TODAY=$(date -u) = 2026-09-19, so it sampled the
  newest-4 segments in the 2026-09-19/21 dir (UTC hour 21).
- ext5 sampled 00.00/00.16/00.32 (21:00:00-21:00:32Z); int2 sampled
  00.10/00.26/00.43. ALL have ZERO audio streams (ffprobe
  -select_streams a = empty). The FAIL was REAL, not a probe artifact.
- Audio was back in both cams by my probes (~01:07Z). Both classes
  self-healed between the 21:05Z run and 01:07Z.

## The class (EXTENDED, not new)

Silent restream-consumer audio loss: the go2rtc RESTREAM (8554) serves
video but drops audio for a window; the recorder ffmpeg (-c:a aac)
writes segments with NO audio track (not zero samples -- no track at
all). No WRN, no watchdog, camera healthy (ch2 census aframes flowing
throughout). Durations today: 5s to ~52min. int2 showed track-level
FLAPPING early in the window (1,0,0,0,1,0,0,0,1... every ~4th segment
carries audio = ~1min cycle), then sustained loss 20:26-21:18Z.

ext5 windows (2026-09-19 UTC): h02 ~1min, h05 5s, h11 6s, h13
13:14-13:22Z (~9min), h15 15:47:36-16:07:19Z (~20min), h21
21:00:00-21:08:34Z (8.5min). Total ~30min/24h.
int2: flapping 20:00-20:26Z, sustained 20:26-21:18:09Z (~52min).

## Relationship to standing classes

- CONSUMER-STARVE (c132, int2 23:04Z): same shape (restream loses one
  track, recorder keeps the other). Today's events = 2nd+ instances.
  The class is RECURRING, not a one-off.
- PRODUCER-AUDIO-FREEZE (c114): the 1b detector classified ext5 as
  frozen (delta=0B/4s). But ch2 census showed aframes flowing in the
  same bucket, and the camera RTSP probe carried audio. The 4s-delta
  probe is TOO COARSE: a 4s window can straddle a segment-boundary
  pause, and the receiver-bytes counter can hold still across it.
  Law-50: DELTA-vs-CUMULATIVE and WINDOW-SIZE are schema fields.
- HEAL-WITHOUT-REPLACEMENT falsifier (c114): 1 PROVISIONAL observation
  (int2: producer_id 3727 stable across my 01:05:51Z and 01:12:19Z
  reads, recovery at 21:18:09Z). NOT confirmed -- no producer_id read
  from inside the 21:00-21:18Z window. ext5's recovery (21:08:34Z) also
  PREDATED its producer replacement (21:10:30Z WRN, id 3841->3925),
  which is stronger: the freeze healed before the conn died.

## Detector verdicts for today's run

- ext5 PRODUCER-AUDIO-FROZEN (state=2): the 15:05Z run sampled
  15:58-15:59Z segments (inside the 15:47-16:07Z window) -> run 1;
  21:05Z run sampled 21:00-21:03Z (inside the 21:00-21:08Z window) ->
  run 2. Two DIFFERENT freeze events counted as one "consecutive"
  streak. The state file conflates distinct events when runs are 6h
  apart and freezes are short. Scar: consecutive-run counters need an
  inter-run gap bound, or they merge independent events.
- The FAIL was correct (segments really were dead); the CLASS label
  (producer-frozen) was partially wrong for ext5 (the camera path was
  fine; the restream path was not).

## Falsifier updates

- HEAL-WITHOUT-REPLACEMENT: 1 provisional obs (int2). The c114
  "long freezes do NOT self-heal" model needs a duration boundary:
  today's self-healers were 8.5-52min; c114's non-healers were longer.
  Hypothesis: freezes under ~1h can self-heal (restream consumer
  re-syncs); longer ones wedge the receiver until replacement.
- NEW WATCH: the 6h fleet cadence + 3-segment sample means a short
  freeze (<6min) can be MISSED entirely and a 6h-gap pair of short
  freezes can be MERGED into one false "consecutive" state. The
  recorder-death detector needs the freeze-boundary context the
  segcensus already has.

## Instrument scars (mine)

1. The 600s TIMEOUT: my first batched per-segment ffprobe scan (24h x
   ~230 segs x 8 cams) hung the ssh call and was killed. Batch law
   amendment: per-segment ffprobe over ssh needs per-cam-hour batching
   with a hard seg cap, or move the scan into a sophon-side script.
2. Same-tool warning at call 100 (ssh-heavy archaeology). The
   batch-harder rule stands; this cycle's work was inherently
   ssh-serial, but the ffprobe scans should have been one sophon-side
   script, not hundreds of round-trips.
3. ch2-census 5-min buckets are too coarse to adjudicate a 4s-delta
   dispute (c318: never estimate a distribution from a summary
   statistic -- the bucket average hid the freeze tail).

## Next-cycle candidates

- Sophon-side one-shot scan script (all cams, 48h, audio-stream
  transitions) to size the class fleet-wide. ONE call, not 500.
- Watch the 03:05Z fleet-feed run: both cams should read healthy
  (audio back). If ext5 reads PRODUCER-AUDIO-FROZEN again, the freeze
  is back or the state file carried it (state file resets only on a
  clean run -- check CLEARED lines).
- The 1b detector's 4s-delta probe: consider a 30s double-probe or a
  ch2-census cross-check before labeling PRODUCER-AUDIO-FROZEN.