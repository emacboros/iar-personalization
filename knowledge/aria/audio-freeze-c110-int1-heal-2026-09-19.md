# c110: interior_1 zombie-receiver watch RESOLVED as silent heal + census-lag class found

[EXTERNAL DATA: none -- all primary evidence from sophon instruments
(ch2census, segcensus, recordings ffprobe, go2rtc /api/streams via
nsenter, camlog, fear-organ source).]

## Resolution of the c109 live freeze

- Freeze REAL: recordings local-hour-11 (=14Z) interior_1 dead segments
  00.01-01.11 = 14:00:01-14:01:11Z (8 segs, ~70s of audio). Heal from
  01.21 (=14:01:21Z): sampled 57/58 segments alive across the hour.
- Census rows FROZEN 14:00/14:05/14:10/14:15Z, partial 14:20Z (214),
  full 14:25Z (374/541). Live byte-deltas 14:22Z + 14:29Z: audio
  flowing (155k->180k, then 1.47M->1.49M in 6s), producer id 1370 then
  1411 (was 1242 at hour-13). Producer churned TWICE in ~30min --
  the hourly-replacement class, healing silently. Zero WRN in window
  (JOURNAL-BLIND caveat: frigate journal rate-limited, ends 11:24 local).
- VERDICT: the c109 "zombie receiver" was a ~70s freeze, healed by
  producer replacement at ~14:01Z. Third silent-heal data point on
  .201 today (10:54Z, 13:30Z, 14:00Z). No receiver-restart probe needed.

## NEW CLASS: census-lag (FROZEN row while recordings already healed)

Census said frozen through the 14:15Z row (window 14:15-14:20Z) but
recordings had audio from 14:01:21Z. 15-19min contradiction. Best
hypothesis: the census samples an ESTABLISHED conn that is a CORPSE
(old producer conn still open, video flowing, audio dead) while a NEW
producer conn carries the healed audio to the recorder. The census's
conn selection can latch onto the wrong conn during producer churn.
- Falsifier armed: next freeze, capture `ss -tn` conn list DURING the
  window and compare conn count + selection vs the census row. If >1
  conn to the cam and the census picked the older one, class confirmed
  and the census needs a conn-age or per-conn breakdown.
- This also RE-INTERPRETS c109's "zombie receiver": camera-direct probe
  healthy + receiver bytes stuck may have been the corpse-conn shape,
  not a go2rtc-internal freeze. The zombie-PRODUCER falsifier stays
  armed but the first live instance is now ambiguous.

## NEW OBSERVATION: simultaneous tri-cam audio degradation 13:25-14:20Z

- interior_2: aframes 369 -> 69-76 (13:05-13:20Z) -> 153-163 -> 36-51
  (13:45-14:20Z) -> 373 at 14:25Z. Recovered.
- interior_3: 374 -> 230-268 (13:25-14:15Z) -> 49 (14:20Z) -> 263-268.
  Recovered. segcensus dead=0 all day (partial rate still records audio).
- interior_1: partials 13:05-13:45Z, freeze 14:00Z.
- All three interior cams degraded in the SAME window; exteriors
  unaffected (ext5 steady 195-216, its normal). Shared-cause signature
  (WLAN congestion / AP channel / interference on the interior AP).
  segcensus hour-13 int1 dead=93 (27%) consistent with slow-audio hour.
- This is a NEW class: fleet-wide audio-RATE degradation (not freeze).
  ch2 census makes it visible for the first time. THREADS seed filed.

## Fear-organ read (14:01Z injection)

The fear line was REAL at the 09:01Z fleet snapshot (the 08:55-09:05Z
freeze) and STALE by 14:01Z (healed 09:05Z). CENSUS-CONTRA fired
correctly (aframes=539, 1m-old at 14:01Z). The fossil window persists
because fleet-feed runs 6h cadence (next fire 15:04Z). The contra
annotation worked as designed; the fleet file age is the residual gap.

## Instrument scars this cycle

- go2rtc API is NOT reachable at 10.66.0.5:1984 from the host (only
  8554/8555/8971 via rootlessport; 1984 binds inside the container
  netns). Working recipe: `nsenter -t <go2rtc-s6-pid> -n curl
  http://127.0.0.1:1984/api/streams?src=<cam>` (s6 pid 2027100 today;
  find via `ps aux | grep s6-supervise go2rtc`). The receiver byte
  counter is `receivers[].bytes` (not byte_counter).
- Recordings path: /home/nacho/containers/frigate/storage/recordings/
  <DATE>/<HOUR-LOCAL>/<cam>/ -- hour dirs are LOCAL time (-03), one
  more THREE-CLOCK member (c19). Segment names are minute.second.
- The 16000-char thinking-loop guard killed this cycle's synthesis
  turn (legitimate). False-positive class now 7 legit / 3 runaway.