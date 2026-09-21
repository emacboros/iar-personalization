# WRNRATE LEAD-LAG: CLOSED (c172, 2026-09-21 ~08:12Z)

The c160 lead-lag watch (5/6 deaths followed high-wrn slots at n=6) is
FALSIFIED at n=125 with clean baselines. WRN does not lead death.

## The test

- Deaths: census FROZEN/VIDEO-DEAD rows 09-20 19:00Z -> 09-21 08:05Z
  (the full wrnrate coverage window). n=203 total; 125 with wrnrate
  coverage (wrnrate only went full-cadence at 19:07Z 09-20).
- Reboot-window exclusion: deaths with epoch%3600 < 720 (first 12min
  of the UTC hour, the HH:02Z cron window) excluded -> n=100.
- Join: per-cam wrnrate value at death slot, slot-300, slot-600.
  Slot alignment: wrnrate slots land at epoch+1 (mod 300 = 0/1);
  matched slot OR slot+1.

## Results

- P(wrn>0 in prev slot | death) = 21% (storm window).
- Storm-period baseline P(wrn>0) = 21.5% (68/316).
- EXACTLY AT baseline. No lead, no lag signal.
- Clean-window (21:30Z->08:05Z): 0.8% nonzero wrn, ZERO deaths.
- Per-cam: ext4 30% vs 55% baseline, ext3 23% vs 37%, ext5 33% vs
  32%, int1 14% vs 22% -- deaths happen in QUIET slots relative to
  each cam's own churn rate.

## Why c160's 5/6 was wrong

Small n (6) + reboot contamination (reboot windows manufacture both
WRN storms and FROZEN rows). The reboot exclusion + n=125 kills it.

## Instrument scars hit this cycle (all real, all mine)

1. wrnrate.log has TWO formats: old per-cam-IP lines (epoch date IP
   wrn, 06:57Z->19:00Z 09-20) and new wide lines (ts=... cam=N).
   Any join must parse BOTH. IP map: 101-105=exterior_1-5,
   201-203=interior_1-3.
2. `sort -n -u` on "epoch cam val" lines COLLAPSES all lines sharing
   a leading epoch (numeric compare treats trailing text as 0).
   Use `sort -s -n -k1,1` (stable, no -u).
3. awk strftime("%H") uses LOCAL time (sophon -03) unless TZ=UTC.
   My hour labels were 3h off until anchored. The c171 scar
   (hand-conversion forbidden) extends: TZ-ANCHOR EVERY strftime.
4. awk -v s=$slot-300 assigns the STRING "1789931400-300" -- shell
   doesn't arithmetic-expand inside -v. Compute in $(()) first.

## The 19-21Z storm (new confirmed event)

125 FROZEN rows 19:00-22:20Z, multi-cam (ext2 19:40-20:13Z, ext3,
ext4, ext5, int1), recorder-confirmed: hour-20 row (19-20Z) dead
segs ext2=54, ext3=76, ext5=90, int1=63, ext4=5; hour-21 (20-21Z)
ext1=50, ext3=27, ext4=13. Two independent instruments agree. This
is the recorder-audio-death class firing fleet-wide -- EPISODES
ledger material. 33/118 FROZEN rows had bytes<2k (walk-failure
shaped, pre-v1.7 rows).

## Verdict

WRNRATE-NOT-PREDICTOR: CONFIRMED at n=125. WRN marks conn churn;
deaths are independent of slot-level WRN. The watch closes. The
class-B model (v3.1) loses its "trigger" candidate -- reboot
schedule + heal events remain the only correlated precursors.