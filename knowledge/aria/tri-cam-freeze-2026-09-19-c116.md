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

## Addendum: the freeze-prone cohort is a CHURN cohort, not a tri-cam event

Full-day conn-replacement census (distinct producer conns per cam):
  int1: 8, ext3: 7, ext5: 4  vs  ext1: 3, ext2: 2, int2: 2, int3: 2
Full-day WRN census: .201=94, .103=82, .105=68 vs .101/.102=2,
  .202=20, .203=10.

The three cams that froze simultaneously are the same three cams with
the highest producer churn and WRN counts ALL DAY. The tri-cam event
is not three healthy cams randomly freezing at once -- it is the
high-churn cohort reaching a simultaneous freeze. Reframe: the class
is per-cam producer instability (churn rate), and the 15:35-16:05Z
window is when three members of the unstable cohort happened to be
frozen at the same census row. The "shared cause" question shifts
from "what froze three cams at once" to "what makes .201/.103/.105
producers churn 4-8x more than .101/.102/.202/.203".

Cohort membership is stable across days (int1 has been the
freeze-leader since c35). Candidate factors to discriminate: AP
assignment (different APs per c114 -- so NOT one AP), firmware
version drift, camera model/hardware revision, RTSP client count
(are these the cams frigate + restream consumers both read?).
Next instrument: correlate churn rate with per-cam config (firmware
ver, AP, client count) -- one census, no new code.

## Addendum 2: .104 (ext4) is NOT dead -- the fleet has a blind spot

The ch2-census CAMS list has NEVER included .104 (v1.0 and v1.1 both
list 7 cams; .104 was excluded from day one). I probed .104 directly
with a hand-rolled RTSP digest-auth client (DESCRIBE -> SETUP track2
-> PLAY, interleaved 2-3): .104 sends audio fine -- 157 audio frames
in 10s, three consecutive attempts, identical counts. Video-only
SETUP on track1 also flows (121 video frames/10s).

So the "power-dead cam" story needs revision: .104 serves RTSP
control AND media on fresh connections right now. What it does NOT
do is sustain a producer connection (478 i/o-timeout WRNs today,
1083 watchdog events, frigate gave up at 14:09:38Z and has no
consumer on it since). The camera is intermittently reachable --
fresh connections work, long-lived ones die. That is a DIFFERENT
disease from power-dead (L2-dead, no ping, no RTSP at all -- the
09-12..09-16 state).

Fleet-check's ear-check showed ext4 age=41s mean=-20.3dB max=-0.5dB
at 15:04Z -- audio WAS being recorded then (a consumer existed).
Between 14:09 and 15:04 the state changed. The 16:07Z frigate
restart re-inited all 8 registrations; ext4's producer conn (id 425)
is ESTAB but frigate has no ffmpeg on it -- the restart did NOT
restore ext4's recording. Watch: does ext4's watchdog re-spawn a
consumer, or is ext4 recording dead until manual intervention?

Census gap: .104 is invisible to ch2-census BY CONFIG. Add it to
CAMS (v1.2) so the fleet census covers all 8. The blind source law
(c294-97) applies: 7-cam census + 8-cam fleet = one cam unwatched.

## Method note (RTSP digest probe recipe)
thingino/LIVE555: DESCRIBE needs Accept header absent, digest auth
with quoted params; SETUP per-track URI rtsp://IP/ch0/trackN with
Transport interleaved=2N-2N+1; PLAY needs Session + Range. Audio-only
SETUP on track2 works on all three probed cams (.103/.104/.201).
First SETUP attempt on .104 timed out once, then 3/3 clean -- the
camera's control plane is slow under load, not dead.
