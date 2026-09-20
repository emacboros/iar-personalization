# WRNRATE x CENSUS JOIN (c167, first analysis)

## Setup

c161 prediction: wrnrate (per-cam 5-min WRN counts, producer-remake
proxy) should predict class-B death frequency per-cam. Puller live
since 06:57Z 09-20 (TOTAL format), per-cam format since 19:07Z.
Analysis at 21:58Z: per-cam era = 1.5h, TOTAL era = 15h.

## Result: the c161 prediction is FALSIFIED (at slot granularity)

Per-cam era (1.5h, 98 census rows):
- 72 dead slots (FROZEN/VIDEO-DEAD) -- ALL 72 had wrn=0 in the same
  slot. 0% co-occurrence. The one slot with wrn>0 was ALIVE (ch2=374,
  the ext4 remake-heal WRN storm landing in a slot where census saw
  video already restored).
- Episode-level: only 16/69 episodes had any WRN within +-5min.
- Rank correlation (eps/h vs wrn/h): ext4 and ext3 top both lists,
  but ext5 (wrn 6.7/h) has FEWER episodes (4/h) than interior_1
  (wrn 2.7/h, 5.3/h) -- inverted pair. Weak, not tracking.

TOTAL-era same-slot buckets: wrn=0 rows (n=298) mean ch2=62.9 /
ch0=123.3; wrn>=4 rows (n=8) mean ch2=21.1 / ch0=222.1. No
meaningful separation.

## Lead-lag probe (wrn>=2 slot -> next slot dead?)

Small numbers, but suggestive: of 6 high-wrn slots, the next slot
was dead for ext1(1/2), ext3(1/1), ext4(2/2), int1(1/1) -- 5/6
next-slot-dead. With n=6 this is noise-level, but the DIRECTION is
the remake->death sequence the class-B model predicts (death starts
0-5min AFTER a producer remake WRN). Worth watching as data
accumulates, not a verdict.

## Interpretation

The c161 hypothesis "wrnrate tracks class-B death frequency per-cam"
is falsified at the same-slot level: deaths happen in slots with NO
WRNs. This is consistent with the refined c166 model: the wedge
(video or audio track death on an established conn) does NOT
require a remake WRN -- it happens on quiet conns too. WRNs mark
CONN REPLACEMENTS (heals and remakes), not the deaths themselves.

The 16/69 episode-WRN-bracketing number needs care: most "episodes"
in the full census are single-slot rows (span=0m) -- slot-boundary
artifacts, not real deaths (c164 FP class). The real-episode
bracketing rate is unknown from this pass.

## What this changes

1. WRNRATE-NOT-PREDICTOR (c160) STRENGTHENED to slot-level: WRNs do
   not co-occur with deaths. The remake-cadence model of class-B
   death frequency is wrong; deaths are conn-internal events.
2. The debug-witness instrument (landed this cycle) is now the ONLY
   path to the trigger: WRN-level logging cannot see conn-internal
   track death. First wedge onset with debug on = the evidence.
3. The lead-lag direction (death AFTER high-wrn slot) is the one
   live thread from this join -- accumulate slots, re-test at ~24h.

## Method notes

- Batch-the-walk held: the whole join was 5 scripts, each one
  emitting one table. No enumeration walks.
- The "ts" row in the first join table was a parse artifact (the
  ts=... line matched the cam=N regex) -- killed in join3 by
  anchoring on the ts= prefix. LAW-50 schema check would have caught
  it earlier.
- Census-slot x wrn-slot alignment: census rows are slot-START
  epochs; wrnrate slots are slot-START epochs; both 5-min cadence --
  they align by construction, no offset needed (verified: the
  heal-WRN slot DID align with a census row).