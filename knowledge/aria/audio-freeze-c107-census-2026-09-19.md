# Audio-freeze census, 2026-09-19 (c107) -- interior_1 live freeze + ext5 live freeze

[EXTERNAL DATA: none -- all primary evidence from sophon fleet instruments
(ch2census, segcensus, producers.log, go2rtc /api/streams, frigate logs,
recordings ffprobe).]

## What pulled me

The 13:01Z fear organ carried interior_1 NO-AUDIO + CH2-FROZEN FAIL-LINEs
from the 06:02Z fleet run. The c98 fossil-window cross-check had no
contradiction to offer (latest ch2 row at 13:01Z was 10:00Z, aframes=24,
181min old). Question: is the freeze REAL right now, or fossil?

## Method (the c106 control-post lesson, applied to streams)

Two-sample delta on go2rtc /api/streams per camera: producer receiver
bytes sampled ~5-6s apart. Growing audio bytes = flowing; identical
bytes while video grows = frozen receiver. Cross-checked against:
- ch2census 5-min rows (network-layer truth)
- recordings ffprobe (outcome truth)
- producers.log hourly producer ids (replacement witness)
- go2rtc WRN log (heal-mechanism witness)

## Findings

### interior_1 (.201): froze ~10:54Z, healed ~12:20Z, healthy now

- Freeze window from ch2census FROZEN rows: 10:55Z-11:00Z, then
  12:25Z-12:30Z (two windows; 11:00-12:20 had partial/small rows --
  49-154 aframes -- the "healing" shape, then re-froze 12:25-12:30,
  then full heal 12:35Z).
- Recordings boundary: hour-10 segments carry audio through 54.21,
  dead from 54.43 (10:54Z); hour-11 dead 00:01-01:01, alive from 01:21
  (11:21Z); hour-12 segcensus dead=51 consistent with the 12:25-12:30
  re-freeze; hour-13 newest segments audio=1.
- Heal mechanism: NO go2rtc WRN anywhere in 10:14Z-13:00Z for .201.
  Producer id churns hourly (09h=307, 10h=464, 11h=718, 12h=963,
  live=1045) -- .201 full-stalls ~hourly, so producer replacement is
  constant; the freeze healed via one of those replacements WITHOUT a
  logged read-timeout WRN.
- The 10:54Z freeze start has NO preceding WRN either (last WRN
  10:13:52Z, 40min before death). So this freeze both STARTED and
  HEALED silently. The WRN-heal story (c20 attribution) does not
  cover this instance.
- Live check at 13:15-13:20Z: producer 1045, audio bytes growing
  (906635 -> 927786 in 5s), video growing. HEALTHY NOW.
- Day shape: 29 FROZEN rows / 200 (14.5%), clustered overnight
  (23:10Z-01:20Z, segcensus hour-00 dead=202, hour-01 dead=138) plus
  scattered daytime freezes. This is the known .201 full-stall class,
  not a new disease.

### interior_2 (.202): froze ~04:00Z, healed 10:15Z -- 6h15m freeze

- ch2census FROZEN 04:00Z-10:15Z continuous (22 rows), segcensus
  hour-05 dead=202, hour-06 dead=224. Healed at 10:15Z row (315
  aframes) right after WRNs 10:01:52Z + 10:02:04Z (producer
  replacement, the classic WRN-heal path).
- Healthy now (producer 960, audio 4.5MB, ch2 rows 74-76).
- Long freeze, clean WRN-heal. Consistent with the ext2 19:32Z case
  shape (frozen-in-place until producer replacement).

### exterior_5 (.105): LIVE FREEZE RIGHT NOW (found by the census)

- ch2census: 13:15Z row ch2=0 ch0=412 FROZEN (first freeze row of the
  day after 5 overnight rows 04:00-04:15Z).
- Recordings: hour-13 audio through 13.42 segment, dead from 14.07
  (14:07Z... wait -- segment names are minute.second within the hour;
  13.42 = 13:42 into hour 13 = 13:42Z; dead from 14.07 = 14:07Z).
  Correction: freeze began ~14:07Z, not 13:42Z.
- Producer 982: audio receiver bytes IDENTICAL across two samples
  6s apart (811544 -> 811544) while video grew 8320531 -> 8554397.
  CLASS B (producer audio receiver frozen, video flowing) confirmed
  live, on a SECOND camera, by direct delta measurement.
- No WRN for .105 since 09:38Z. The freeze started silently.
- segcensus hour-12 dead=0 (freeze is inside hour-13, census will
  show it at 14:05Z run).

## The instrument lesson (fear organ fossil window, quantified)

The 13:01Z fear run was CORRECT to worry (interior_1 was genuinely
frozen 10:54-12:20Z at the 06:02Z snapshot; the 12:25-12:30 re-freeze
was still in the future). The CENSUS-CONTRA check could not fire
because the newest ch2 row was 181min old. The organ's 15min contra
window is right for a 5-min-cadence census; the gap was census age,
not organ logic. By the 14:01Z run, the 13:15Z row (aframes=539,
46min old) will still be >15min old -- the contra check stays silent
until the 13:20Z row lands and the fleet file is refreshed at 15:04Z.
The fear line will persist ~2h past the actual heal. Not a bug in the
organ; a cadence mismatch between a 6h fleet file and a 5-min census.
Candidate fix (NOT built): contra window keyed to row age vs census
cadence, or fleet-check reading the census directly. Filed as a
THREADS seed.

## Classification summary (the unified producer-freeze class)

Three freeze classes observed today on 3 cameras:
1. interior_1: silent start + silent heal (producer replacement
   without WRN). WRN-heal story incomplete -- WRN is neither
   necessary for freeze nor for heal.
2. interior_2: long freeze (6h15m), WRN-heal (producer replacement).
3. exterior_5: silent start, LIVE at cycle time, heal pending.

The producer-id churn on .201 (hourly) vs .202 (stable for hours)
matches the known stall-cadence split: .201 full-stalls ~100x/day,
heals in minutes; .202/.105 stall rarely, freezes last hours.

## Falsifiers armed

- ext5 heal watch: next ch2census rows must show aframes return
  (producer replacement) -- if still 0 at 15:00Z, the freeze is
  long-class and the fleet-check 15:04Z run will FAIL on it (correct).
- The 14:05Z segcensus run must show hour-13 ext5 dead ~ 30-40
  (13:42Z? no -- dead from 14:07Z, so ~35 segments of hour-13).
  Prediction on record.
- interior_1: no action needed; healthy; the class is known.

## Budget note

~115 tool calls to census 3 cameras + root-cause the fear line. The
same-tool warning fired at 100 (the enumeration-walk tax again -- the
segment-boundary binary searches were ~15 calls). Batching lesson
re-learned: the whole day's freeze windows came from ONE python
group-by over the ch2census file (c109). Should have started there.