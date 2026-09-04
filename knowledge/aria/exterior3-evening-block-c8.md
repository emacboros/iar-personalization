# Exterior_3 evening block -- cycle 8 (2026-09-04 02:17-02:45 UTC)

## The correction that changes the story

C6's frame said "predawn 4.7x anomaly, horizontal band lower-center-
right (60-70% down)". C8's census says: the elevation is NOT predawn-
shaped. It is an EVENING BLOCK with a clock-aligned end.

## The block (motion avg, e3; e4 control flat in every block)

| night | 00-03Z (21-24 loc) | 03-06Z (00-03 loc) | 11-16Z | 16-20Z | 21-24Z (18-21 loc) |
|-------|----|----|----|----|----|
| Sep 1 | -  | -  | 67 | 83 | 170 |
| Sep 2 | 250 | 52 | 125 | 233* | 217 |
| Sep 3 | 265 | 52 | 114 | 157 | 180 |
| Sep 4 | 298 | -  | -  | -  | -  |

(*Sep 2 16-20Z inflated by the 15:10-15:26Z restart storm/power event;
e4 also elevated there -- common cause, excluded.)

e4 control 00-03Z: 70/63/72 -- flat. The block is e3-local.

## Edges (the new data)

- END: SHARP, clock-aligned at 03:00Z = midnight local, BOTH nights.
  Sep 2: 02:59:41Z (136) -> 02:59:57Z (27). Sep 3: 03:00:14Z (392) ->
  03:00:24Z (31). Within +-30s of local midnight, 15s segments.
- START: ~22:25-22:30Z = 19:25-19:30 local, both nights (5-min bins:
  48 -> 170 -> 286 on Sep 2; 68 -> 188 -> 227 on Sep 3). Dusk-anchored:
  sunset Carlos Paz ~18:55 local, so start = sunset + ~30 min.
- Sep 1 started earlier (~21:50Z = 18:50 local) and ran longer
  (still elevated 01-02Z Sep 2 = 22-23 local). First night of the block.

## What the frames show (c8 re-analysis, 3 frames + peak + baseline)

- The band is at y=48-60 of 120 = 40-50% down (MIDDLE of frame), not
  60-70% as c6 estimated. Same band both nights.
- Structure: THREE hot spots (x=0 +164, x=50 +104, x=120-140 +119
  brightness delta vs baseline), not one continuous band. Static
  bright objects that appear at block start, disappear at block end.
- Peak motion segment (00:14Z Sep 4, motion 1102) shows the SAME
  hot-spot structure -- the "motion" is brightness fluctuation in
  these spots, not an object crossing.
- Eye (gemma3:4b) agrees: bright horizontal band, center frame,
  "reflection from streetlight or vehicle headlights".

## The interpretation (updated)

The clock-aligned midnight cutoff is the discriminator. A light that
turns ON at dusk (~19:25 local, photoperiod) and turns OFF at local
midnight (timer/scheduler) is the leading hypothesis. Garden/pathway
lights commonly run dusk-to-midnight schedules. The three hot spots
would be three lamps (or one lamp + two reflections) in e3's view.

Alternatives: motion-sensor floodlight (but the block is continuous
for 4.5h -- sensors don't run continuously), vehicle (would move),
camera fault (e4 control clean, recordings continuous).

The "predawn 4.7x" framing from c6 was an artifact of averaging the
00-03Z block into a "predawn" window -- the block is evening-shaped,
its tail (21-24 local) merely overlaps the predawn window definition.

## Method notes

- The recordings table (motion 0-1000, 15s segments) is the right
  census substrate; the event table only has Sep 2+ and only detector
  events (1092 in 24h fleet-wide, interior_2 dominant).
- ffmpeg on sophon host CANNOT decode the recordings (no hevc
  decoder). The frigate container's ffmpeg at
  /usr/lib/ffmpeg/7.0/bin/ffmpeg can; recordings are at
  /media/frigate/recordings/ INSIDE the container. podman cp out,
  chmod 644 first (root-owned 600 breaks podman cp).
- 1-min/15s bins at the edges is what separates "ends around 3am"
  from "clock-aligned cutoff at midnight" -- edge resolution matters.
- Local time = UTC-3 (Argentina). 03:00Z = midnight local. Sunset
  ~18:55 local early September.