# Tri-cam freeze 09-19: the 16:07Z frigate restart was NOT the healer

## The claim that needed testing
c114 closed with "frigate restart healed all 8 cams". If the restart
itself is the healer, the class has a recorder-side heal path. If the
heal happened BEFORE the restart, the class is camera/go2rtc-internal
only (c114's original read) and the restart was incidental.

## Evidence (ch2-census conn-breakdown, 5-min cadence, v1.1)

ext3 (.103): frozen 15:35-16:05Z on conn 36630 (ch2=0, 8 samples).
  Heal: 16:10Z row = NEW conn 49426, ch2=225. Producer replaced
  ~16:05-16:10Z. WRN at 13:48/13:52/13:54Z (i/o timeouts) -- the
  producer DIED (conn torn down, replaced) minutes before the heal.
int1 (.201): frozen 15:40-16:05Z on conn 33752. Heal: 16:10Z row =
  NEW conn 49686, ch2=373. Same shape: WRN 13:42Z, producer replaced.
ext5 (.105): frozen 15:50-16:05Z on conn 58044. Heal: 16:10Z row =
  NEW conn 33616, ch2=373. WRN 13:08/13:32/13:42Z, producer replaced.

All three healed at the SAME census row (16:10Z) with NEW producer
conns. Frigate restart = 16:07:08Z (ActiveEnterTimestamp). The heal
row is the FIRST row after the restart.

## The confound I cannot break from inside
go2rtc's reconnect loop retries on i/o timeout WRNs. The 13:42-13:54Z
WRN cluster for all three cams is consistent with: producers died ->
reconnect loop made new conns -> all three healed 16:05-16:10Z ->
frigate restart at 16:07:08Z landed in the same 5-min window. The
restart is CONFOUNDED with the natural heal cycle. I cannot
distinguish "restart healed them" from "reconnect loop healed them,
restart coincided" from census data alone.

## What this changes
1. c114's "frigate restart healed" is DOWNGRADED to "heal coincided
   with restart; mechanism unproven". The class's heal mechanism
   remains: producer replacement (conn identity change), consistent
   with the reconnect loop, NOT proven to be the restart.
2. The heal-without-replacement falsifier stays armed and UNSTRUCK:
   every observed heal has a conn-identity change. 0 exceptions.
3. The WRN cluster (13:42-13:54Z) PRECEDES all three freezes'
   recovery by ~15-25min. If the WRN cluster is the shared cause's
   signature (something made all three producers time out), the
   tri-cam event has a timestamp: ~13:42-13:54Z, NOT 15:35-15:50Z.
   The freezes were the TAIL of a shared event that started ~90min
   earlier.
4. .104 (ext4) had 84 WRNs in the window -- the known power-dead
   cam's noise floor. Excluded from the tri-cam class.

## Instrument note
conn-breakdown.log timestamps are epoch seconds; the 5-min cadence
rows (1789832956 = 15:29:16Z) are mid-hour samples from the 1-min
timer runs. Census cadence = 1min timer, 5-min logged rows in
breakdown, per-cam rows hourly in the cam logs. THREE-CLOCK law
applies to reading these files.
