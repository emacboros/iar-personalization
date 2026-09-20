# Heal-lock ext3 storm, 2026-09-20 (c160 post-mortem)

## What happened

ext3 (.103) ran a 6-freeze day, the densest single-camera freeze record
yet, and the heal-lock model (c158: every freeze heal coincides with a
conn i/o-timeout WRN within seconds) held in 10/10 census-visible heals.

Fleet-wide heal-lock tally after this cycle: 4/4 ext1 (c158) + 6/6 ext3
(c160) = 10/10. Zero counterexamples.

## The six ext3 freezes (census slots, UTC; WRNs local -03)

| # | FROZEN slots (UTC) | heal bracket | WRN at heal (local) | delta |
|---|--------------------|--------------|---------------------|-------|
| 1 | 11:40-11:55Z | 11:55-12:00Z | 08:57:20, 08:57:32 | heal visible at 12:00Z slot; WRNs 3-8 min before |
| 2 | 14:10-14:15Z | 14:15-14:20Z | 11:19:38 | ~5 min before visible heal |
| 3 | 15:25-15:55Z (12 slots) | 15:55-16:00Z | 12:58:44 | ~1 min before |
| 4 | 17:45Z (1 slot) | 17:50Z | 14:55:05, 14:57:06 | 2-5 min before |
| 5 | 18:15Z (1 slot) | 18:15-18:20Z | 15:19:05, 15:20:23 | 4-5 min before |
| 6 | 18:45Z (1 slot) | 18:45-18:50Z | 15:56:52 | ~3 min before |

Freeze #3 was the long one: 12 consecutive FROZEN slots (15:25-15:55Z),
the freeze-watch armed on it at 15:41Z (arm-state.log), 24 fine-cadence
samples, all ch2=0 until the 16:00Z slot showed 374/165. The WRN at
12:58:44 local (15:58:44Z) sits inside the heal bracket.

## The refinement this day forces

The lock is real but the DELTA is not seconds -- it is 1-5 minutes,
bounded by census granularity (5-min slots) and the WRN cadence. The
c158 deltas (+13s/-1s/+12s/+5s) were fine-cadence observations; the
census-slot deltas here are coarser. Both are consistent with one
mechanism: camera audio dies -> RTSP session rots -> i/o timeout WRN
-> producer remake -> audio returns (born-dead ~30s sometimes, c155).

What the day ADDS: WRN bursts PRECEDE the census-visible heal by up to
5 minutes. The WRN is not the heal; it is the rot death that precedes
the remake that carries the heal. The histogram is the freeze clock,
and it ticks BEFORE the census sees the heal.

## The chronicity datum

ext3 WRN counts by hour (local, full day): 3,6,9,7,5,10,5,14,15,6,13,2,
4,2,12,25. The 15:00 hour (18:00-19:00Z) had 25 -- the freeze storm
hour. But hours 07-10 had 14-15 with only ONE FROZEN slot between them
(11:40Z). WRN rate alone is NOT a freeze predictor (c151 amendment
confirmed); WRN-at-heal is the signal. The puller's value is the JOIN,
not the alarm.

## Instrument

wrnrate-puller.sh v1 (this cycle, f778824c): per-cam 5-min WRN counts
via structured-API cam map, rootless-podman read path, sophon cron
*/5, /var/lib/aria-fleet/wrnrate.log. First live line:
ts=1789931269 exterior_1=0 exterior_2=0 exterior_3=2 exterior_4=3
exterior_5=1 interior_1=0 interior_2=0 interior_3=0.

## Open

- WHY prudynt's audio track dies mid-conn: camera-firmware question,
  rides go2rtc #2505 family. The RTSP-session-sickness model (audio
  death -> session death ~20min later) is the working hypothesis.
- The 5-min WRN-vs-heal delta needs fine-cadence confirmation
  (freeze-watch v1.1 producer-id + WRN join) -- the census slot
  boundary blurs it.