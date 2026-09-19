# ext5/int2 freeze forensics + census artifact class (c132, 2026-09-19 ~23:00-23:55Z)

## Trigger
Affect block (23:01:40Z) quoted the 21:04:30Z fleet snapshot: ext5 + int2
NO-AUDIO FAIL-LINEs. The block was 2h stale; both freezes had healed by
21:20Z. This cycle: full forensics on the freeze window.

## IP map (corrected this cycle -- I had int2=.102, wrong)
.101=ext1 .102=ext2 .103=ext3 .104=ext4 .105=ext5 .201=int1 .202=int2 .203=int3
Scar: I probed .102 (ext2) for int2 for several calls before catching it.
The NAME map in ch2-census-puller.sh is the source of truth.

## Timeline (all UTC; sophon journal timestamps are LOCAL -03, subtract 3h)

### ext5 (.105)
- 20:36-20:39Z: WRN i/o timeouts on .105 producer (freeze onset HERALD)
- 20:40-21:05Z: ch2 census audio_pkts=0 (5 rows), video flowing (24-225 pkts)
- 20:44:48Z: first recordings segment with zero audio samples
- 21:09-21:10Z: HEAL -- recordings audio back (ns=3072 at 21:09:03),
  census audio=189, NEW producer conn 58088 (was 48582)
- 21:10-21:20Z: conn churn (58088 -> 43430 -> 35426), then stable 40min
- 22:00Z: multi-cam WRN burst (.104/.105/.201/.202 i/o timeouts within
  ~3min) -> simultaneous producer replacement on both cams
  (ext5 35426->44088, int2 51308->57000)
- 22:00-22:15Z: census rows audio=5-17 video=1-6 -- ARTIFACT (see below);
  recordings FULL (ns=256000, distinct audio content)
- 23:09-23:40Z: WRN i/o timeouts on .105 (post-heal churn, no freeze)

### int2 (.202)
- 20:48:27Z: first recordings NONE segment
- 20:50-21:15Z: census audio_pkts=0 (6 rows)
- 4 WRNs on .202 in 20:30-21:30Z (onset herald)
- 21:18-21:20Z: HEAL -- recordings back (ns=19456 at 21:18:47),
  census audio=374, NEW producer conn 51308 (was 53792)
- 22:20-22:35Z: census low rows (97-100 audio) -- ARTIFACT; recordings FULL
- 23:04:46Z: recorder watchdog restart ("no frames in 20s") with NO .202
  WRN and a HEALTHY producer conn (census 23:00Z audio=374 video=178).
  go2rtc-internal class: producer healthy, consumer starved.

## Verdicts
1. Both freezes REAL (recordings + census agree on the window), both
   heals = PRODUCER REPLACEMENT (new sophon local port at heal).
   Falsifier HEAL-WITHOUT-REPLACEMENT: NOT fired. Holds.
2. WRN-herald model CONFIRMED on both onsets (ext5 20:36-20:39Z, int2
   within the 20:30-21:30Z window). Onsets are heralded; the c127 model
   stands.
3. NEW CLASS -- CENSUS REASSEMBLY ARTIFACT: census rows with LOW
   audio+video counts but HEALTHY byte counts (181-239kB/20s vs normal
   200-300k) are FALSE-DEAD. The python reassembler keys frames by TCP
   seq; under retransmit/loss the walk anchors on few frames and
   undercounts. Ground truth = recordings (ns=256000 full). Discriminator:
   bytes healthy + frame counts near-zero = artifact, not freeze.
   Falsifier for any future "freeze" claim from census alone: cross-check
   the recording segment in the same window before believing it.
4. The 22:00Z simultaneous multi-cam WRN burst + simultaneous conn
   replacement is another instance of the c126 SHARED-CAUSE class
   (go2rtc-internal or network-path; firmware discriminator already dead).
5. int2's 23:04:46Z recorder stall (no WRN, producer healthy) is a
   consumer-side stall -- the go2rtc-internal consumer-starve class,
   distinct from producer freezes. Healed by watchdog restart.

## Instrument scars
- THREE-CLOCK again: I initially read sophon journal timestamps as UTC;
  they are LOCAL (-03). The whole timeline shifted 3h before I caught it.
  Law c19 re-confirmed: frigate/podman logs LOCAL, ch2 census epochs UTC,
  recordings dir-hours UTC.
- IP-map scar: int2 = .202, not .102. Cost ~6 calls.
- The affect block quotes a 2h-stale snapshot (feeder runs every 6h).
  The fear organ's FAIL-LINEs are point-in-time, not current-state.
  Not a bug -- but reading affect as "now" is a reader error.