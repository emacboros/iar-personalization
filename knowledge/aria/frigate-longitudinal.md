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
## INSTRUMENT PROVENANCE (pinned 2026-09-04, cycle 11)

The motion census instrument IS: `frigate.db` table `recordings`,
column `camera` (TEXT, e.g. 'exterior_3'), column `motion` (0-1000
per ~15s segment), `start_time` epoch UTC. NOT the `timeline` table
(timeline carries only source=motion/class_type=motion rows and e3
has none -- cycle 10's "0 motion rows" was the wrong TABLE, not a
missing anomaly). Query shape:

```sql
SELECT start_time, motion FROM recordings
WHERE camera='exterior_3' AND start_time>=? AND start_time<?
```

Bin by `time.gmtime(ts).tm_hour` for hourly averages. DB retention:
3 days continuous (current DB earliest row 2026-09-01 06:53Z). The
Aug 27/Aug 30 baselines above came from an EARLIER DB era (pre-wipe,
DB recreated ~Aug 24); cross-era comparisons need care.

## 2026-09-04 (cycle 11) -- e3 evening block CONFIRMED, instrument recovered

e3 21-03Z block-hours avg motion (recordings table):

| night (UTC) | e3 block avgs | e4 control |
|-------------|---------------|------------|
| Sep 1 | 56, 218, 233 | (partial) |
| Sep 2 | 88, 212, 347, 175, 298, 280 | 74, 70, 62, 67, 69, 76 |
| Sep 3 | 63, 185, 292, 269, 265, 262 | 82, 65, 77, 73, 64, 52 |
| Sep 4 | 309, 302, 266 | 58, 67, 85 |

The block: starts ~22:15-22:30Z (dusk+30 local), ends SHARP at
03:00Z (local midnight; 15-min bins 02:45=262 -> 03:00=72 ->
03:15=44 on Sep 3). Every available night. e4 flat throughout.
The cycle-10 "no recurrence" verdict was an instrument error
(wrong table), now corrected; the anomaly NEVER stopped.

Mid-block frame profile (Sep 3 night): band y=48-56 hot (103-125
vs 71-80 neighbors), three spots x~0/50/120-140, right side
(x=120-140) grows brightest through the night (137->148 by 02:45Z)
while top flare row stays flat (96->99). A-vs-C diff map: change
concentrated in the band right-of-center; rest of frame static.
- e3 geometry CLOSED (c12): block is e3-LOCAL. Same-instant e2/e4
  frames have NO band (79-90 vs e3's 110 at y=48-143); neighbors'
  bright edges STATIC through night (e2 left 170->175, e4 right
  138->138) while e3's band right side grows (137->148). Emitter
  is in e3's field of view or immediate foreground. NEXT: e3
  daylight frame at band position (y=48-143, x~0-140) to name
  candidate objects; Nacho's physical glance (flag 380) still
  cheapest discriminator.
## 2026-09-04 (cycle 13) -- e3 daylight-discriminator pass: band objects NAMED

Daylight frames at band position (y=48-143, x=0-144), Sep 3 recordings,
12Z (full day) / 16Z / 19Z (dusk, block starting). Pure-python PNG
profiler (no PIL/numpy in the i.ar container).

| hour | band avg | scene avg | ratio | spots x0-15 / x45-60 / x120-144 |
|------|----------|-----------|-------|-------------------------------|
| 12Z  | 56       | 113       | 0.49  | 47 / 46 / 75                  |
| 16Z  | 65       | 97        | 0.68  | 21 / 61 / 100                 |
| 19Z  | 152      | 111       | 1.37  | 146 / 127 / 187               |

The band region is a DARK WALL by day -- the darkest structure in its
strip. The three night hot spots sit on dark vertical elements (x~0-60)
plus a mid-gray object (x~120-144). Brightest noon pixels in the band
are small specular points (252@y49x63, 235@y54x25) on the dark
structure. The eye's c9 reading ("brick structure + light poles/
fixtures") holds.

VERDICT: the night 'band' is specular wash on a dark wall/fence with
vertical elements, lit from a source below/left, OUTSIDE the frame.
The emitter hunt is now physical: what light stands below/left of e3's
view, runs dusk-to-midnight, grows through the night? Nacho's glance
(flag 380, lab-notes 385) names it in seconds. Lab-notes 391 posted.

Method: container ffmpeg extract -> cp via /media/frigate/recordings/
(the bind-mounted subdir; /media/frigate/*.png is root-owned and NOT
host-visible) -> scp one-per-file -> python zlib PNG decoder (60-line,
banked in JOURNAL c13). 6 calls this pass.

## 2026-09-04 (cycle 15) -- instrument banked: pngprof.py + census metric amendment

CENSUS METRIC AMENDMENT (c14 finding, pinned here): the `motion`
column is an activity SCORE (0-255+ observed; e2 has values up to
492), NOT a boolean. `motion=1` is a near-useless filter (6 rows
all-time for e2). The pinned metric is SUM(motion) per bin.
Census path: host python3 + /home/nacho/containers/frigate/config/
frigate.db (no sqlite3 in the frigate container). Container ffmpeg
is NOT on PATH: /usr/lib/ffmpeg/7.0/bin/ffmpeg (5.0 also exists).

INSTRUMENT: knowledge/aria/bin/pngprof.py -- pure-python PNG
decoder + frame profiler (the c13 decoder was lost with /tmp; this
is the durable rebuild). Scope: 8-bit non-interlaced gray/RGB/RGBA.
Self-test: `python3 pngprof.py --selftest` (synthetic image, all 5
filter types, exact round-trip). Positive control (c15): band mean
101.3 vs ffmpeg signalstats YAVG 103.1 on the same crop (~2% apart,
95 vs 96 rows) -- instrument validated against ffmpeg.

c15 12Z re-profile (Sep 3 12/exterior_3/00.13.mp4): scene 113.9,
band y48-143 101.3, ratio 0.89. NOTE: c13's same-hour numbers
(band 56, scene 113, ratio 0.49) do NOT reproduce on this segment
-- c13 likely profiled a different 12Z segment or the lost decoder
was buggy. The NAMED-OBJECTS conclusion (dark wall + vertical
elements) stands on the c13 frames; the exact ratio is segment-
dependent. Provenance now pinned: pngprof.py + segment name.
