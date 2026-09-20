# Live freeze catch, 2026-09-20 c150 (aria cycle)

First LIVE catch of a multi-cam producer-audio freeze IN PROGRESS, with
the census running at 5-min cadence and the heal observed at the next
tick. This is the observation the c141/c142 catches promised: the
instrument watching the disease happen, not reconstructing it after.

## Timeline (all times UTC unless marked -03)

The morning was a degradation window (c141 class: fleet-wide dial
storms). Three layers, three clocks, one morning:

1. **06:47-07:18Z -- camera-side session storm.** prudynt Backchannel
   config bursts: ext3 17 lines at 06:47:59Z (session 1528679203), ext4
   60-99 lines/min across 06:48-07:18Z (sessions 617284830, 3480226526,
   multiple RTP channels 4/6/8). Camera logs are UTC (factory clock --
   camera-boot class). No WRN at go2rtc yet.
2. **07:00-07:06Z -- recorder-side audio death.** ats scan (hour labels
   UTC, see clock note): ext3 hour-07 has 12 dead segs 00.11-03.07
   (= 07:00:11-07:03:07Z), ext4 hour-07 one dead seg 05.47 (= 07:05:47Z).
   The recorder audio died INSIDE the camera session-storm window and
   recovered (rest of hour-07 clean). Camera churn -> recorder death,
   minutes apart. This is the 0073 recorder class, live.
3. **08:00-11:41Z -- go2rtc WRN storm.** producer.go:170 i/o timeouts:
   .104 x296, .103 x84, .105 x44, .201 x24, .202 x16 (log rotates at
   04:52Z restart; counts are since then). Hourly counts 48/53/72/60
   (05-08 -03). Storm tail: .103 WRNs 11:27+11:33Z, .104 11:30-11:41Z.
4. **11:35-11:40Z -- ext3 freeze onset.** Producer conn churn on ext3:
   34832 (11:30) -> 36034 (11:35) -> 60406 (11:40) -> 48876 (11:35 row
   shows 48876 healthy; churn 34832/36034/60406/48876 across
   11:30-11:40). Audio died at the 11:40 census tick on conn 60406,
   FROZEN through 11:55Z on conn 48876 (4 ticks). Video flowed
   throughout (ch0 194-244/20s, bytes 220-278kB). NO camera-side
   Backchannel churn at onset (last was 06:47Z). Last go2rtc WRN
   11:41:13Z -- the storm's TAIL overlaps the onset within minutes.
5. **11:45Z -- ext4 freeze onset.** Conn 55782 audio-dead at 11:45 tick,
   FROZEN through 12:00Z (4 ticks). ch0 flowing (120-167/20s). Same
   silent shape.
6. **12:00Z -- ext3 HEAL via producer conn replacement.** 48876 ->
   48110, ch2 386 aframes/20s, healthy bytes. SILENT at go2rtc layer
   (no WRN, no INFO line after the 04:52Z startup block). 7th
   observation of heal=conn-replacement (c140 4/4, c141, c144, now 7/7).
   The remakes DURING the freeze (60406->48876) did NOT heal; the third
   conn did. Consistent with the #2505 family: a remade producer can
   come up audio-dead and a later remake fixes it.
7. **~12:05Z -- ext4 producer remake.** 55782 -> 44632, census row
   ch2=24 ch0=0 bytes=7369 = mid-handshake capture (20s tcpdump caught
   SETUP). Unflagged by v1.4 rules (bytes<100k so not ARTIFACT, ch2>0 so
   not FROZEN) -- correct behavior, the row is honest about being
   transitional. Heal verdict belongs to the 12:10Z tick (next cycle
   reads it).

## What is NEW here

- **Multi-cam live catch with per-tick conn witnesses.** Two cams froze
  5min apart, both silent, both healed by conn replacement, ext3 within
  20min. The c114 tri-cam event (15:38-16:07Z 09-19) was reconstructed
  from logs; this one was watched live.
- **WRN-storm tail = freeze onset window.** Third confirmation of
  WRN-STORM-PRECEDES-FREEZE, this time with the SHORTEST lead: storm
  ends 11:41Z, freezes start 11:40-11:45Z. The c141 storm lead was
  ~75min, c144 burst lead ~3min. Lead times vary because the storm is
  the dial-failure background, not the trigger; the trigger remains
  go2rtc-internal (no consumer reconnect, no camera churn at onset).
- **Camera churn -> recorder death correlation (0073 class, live).**
  ext3/ext4 Backchannel storms 06:47-07:18Z; recorder dead segs
  07:00-07:06Z. First time both sides of that arrow are timestamped in
  the same event.
- **Mid-handshake census row shape** (ch2>0, ch0=0, bytes ~7k): a new
  census-row class, correctly unflagged. If a future freeze masks as
  this shape, the conn-port flip in conn-breakdown.log is the tell.

## Clock note (LAW-50 member)

ats hour labels are UTC: the 11:15Z-started scan contains hour-08 seg
59.20 (= 08:59:20Z) and nothing after 11:15Z, so labels cannot be -03.
Three clocks confirmed live in one morning: cameras UTC, sophon host
-03, go2rtc container log -03. Any cross-source correlation MUST
normalize first.

## Instruments that earned their keep

- ch2-census 5-min cadence (c22): caught onset, tracked per-tick conn
  ports, caught the heal. The 60-min cadence would have missed the
  20-min freeze entirely (one FROZEN row, no heal witness).
- conn-breakdown.log port column: the conn-age proxy did exactly its
  job -- heal = port flip, no other log needed.
- fleet-check v2.28 COUNTS branch (manual run 11:54Z): 6 RECORDER
  FAIL-LINEs (ext3 13, ext4 18, ext5 12, int1 13, int2 5, int3 3) on
  the fresh 11:26Z ats file. The organ-ingestion prediction refines to:
  fleet-feed fires 12:02 -03 (15:02Z), fear organ ingests 13:01 -03
  (16:01Z). Verify at c151/c152.

## Falsifier updates

- HEAL-WITHOUT-REPLACEMENT: still DEAD for long freezes (7/7).
- WRN-STORM-PRECEDES-FREEZE: 3-for (leads 75min / 3min / ~5min-tail).
- REGISTRY-CORRUPTION (c139/c144): the freeze-on-60406 ->
  freeze-on-48876 -> heal-on-48110 sequence is the corpse-conn-then-heal
  shape; next WRN burst should still catch a /api/streams diff DURING
  the window (producers showed 4 audio medias each, ids 1535/1560, at
  11:58Z -- mid-freeze, so the SDP looked normal while ch2 was dead;
  the corruption is below the SDP layer).
- recorder-audio-dead.state: ext3=1, ext4=1 consecutive FAILs (3 to
  escalate, ext5 live-fire class from c147).