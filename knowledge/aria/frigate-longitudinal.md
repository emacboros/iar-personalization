# Longitudinal data -- motion-by-hour per camera

The time series. One entry per observation day. Baseline method:
avg(motion) by hour-of-day per camera from frigate.db recordings
table (continuous recording, ~225-360 segments/h/camera, motion
0-1000 scale). Written by cycle-me each cycle that looks.

## 2026-08-30 (baseline, cycle 3)

- House quietest 03:00-09:00 (avg ~55), peak 18:00 (172).
- exterior_1 tracks daylight: peak 16-19h (408-459), night ~44-50.
- interior_1 flat ~31, small evening bump 22-23h (94/81).
- interior_2 noisy all day, evening peak 20-21h (283/336).
- exterior_2 DEAD (no data since Jul 8 -- fixed later this day).

## 2026-08-31 (cycle 8, 01:00 AR) -- second data point + first ANOMALY

Per-camera night (00-06h) avg motion, Aug 30 vs Aug 27 baseline:

| camera | Aug 27 | Aug 30 |
|--------|--------|--------|
| exterior_1 | 87 | 59 |
| exterior_3 | **78** | **233** |
| exterior_4 | 55 | 56 |
| exterior_5 | 103 | 89 |
| interior_1 | 33 | 34 |
| interior_2 | 161 | 97 |
| interior_3 | 36 | 37 |

**THE ANOMALY: exterior_3, night of Aug 29-30.** 12 hours
(22:00 Aug 29 - 09:00 Aug 30) of constant elevated motion, avg
~233, distribution shifted wholesale (Aug 27 night: 1102 segments
<100, 2 >300; Aug 30 night: 53 <100, 305 >300). NOT spikes -- a
raised FLOOR. Every other camera normal. Camera-local event.

Signature analysis: constant moderate motion for 12h on one
camera = insect on/near lens, IR reflection from something new
(snow? no, August; a moved object reflecting), or vegetation
grown into frame. NOT a person/animal (that would be spiky, not
constant). The floor stayed high through sunrise decay (~09:00).

Follow-up: night of Aug 30-31 shows MILD recurrence (22-23h avg
142-171, then normal). Trend across the week: night avg climbing
76 -> 93 -> 118 -> 87 -> 82 -> 133 -> 219. Something is changing
at exterior_3. Next cycle: check whether the 22-23h elevation
persists; if the pattern strengthens, flag for Nacho (physical
look at the camera -- lens cleaning or object moved into IR path).

Also captured this cycle (house rhythm, Aug 31 data):
- exterior_1 daylight peak confirmed (16-17h: 567-612, higher
  than baseline's 408-459 -- windier day?).
- interior_2 evening peak confirmed (20-21h: 283/331 -- matches
  baseline exactly; the living room's rhythm is stable).
- exterior_3 daytime now elevated too (16h: 222 vs baseline ~186).

## exterior_2 resurrection confirmed

Recording again since Aug 30 ~19:50 (fix landed that evening):
259 segments Aug 30, 238 in hour 00 Aug 31. Motion values healthy
(75-112 night). The 7-week hole (Jul 8 - Aug 30) in its data is
permanent -- previews still 0 files (previews build from events,
and there are no events without a detector).

## Structural findings (this cycle's archaeology)

- **~20GB of orphaned recordings**: 2026-07-05..07-08 dirs
  (~20.2GB) exist on disk but have NO rows in frigate.db (DB
  earliest row: Aug 24 00:51 UTC). The DB was wiped/recreated
  around Aug 24 (frigate down Jul 8 - Aug 24; boots show machine
  off Aug 4-16, and no frigate journal entries before Aug 24).
  The maintainer only deletes what the DB knows. 20GB of
  invisible video nobody can browse.
- **Retention config**: continuous 3 days, motion 7, alerts 30.
  Working as designed for DB-tracked segments (Aug 24+ only).
- **Recording structure**: recordings/<date>/<hour>/<camera>/NN.NN.mp4
- **Camera network**: all 8 cameras UP on 192.168.2.x (thingino
  firmware, ch0 streams). exterior_2 at 192.168.2.102 confirmed.
- **Frigate health**: 8/8 cameras at 5fps, zero detection errors,
  only 2 watchdog restarts in 24h (exterior_1 RTP cseq glitch,
  self-recovered; exterior_4 one restart). The 7-week watchdog
  spam is GONE since the exterior_2 fix.
- **GPU**: RTX 3080 at 1% util, 2.5GB used (frigate ffmpeg
  processes ~269MB each). Still no detector configured.