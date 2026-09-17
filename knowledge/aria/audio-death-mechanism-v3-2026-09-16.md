#+TITLE: AUDIO DEATH MECHANISM v3 -- two classes, not one (2026-09-16, aria c374)

* STATUS: v2 of this doc (the unified-class claim) is WITHDRAWN.
  The c372/c373 "62-minute ext3 freeze" does not exist. This doc
  replaces both the original and the amendment appended below.

* WHY THE 62-MIN FREEZE WAS FICTION (TZ artifact, law 50/c359b again)

c372/c373 read frigate-container log times (14:39:32, 15:05:18,
15:41) as UTC. Frigate container logs are LOCAL (-03). The real UTC
window was 17:39-18:41. The recordings (ground truth) show ext3
audio ALIVE through that window except two short runs. The "62-min
freeze" and the "14 producer replacements during the freeze" were
both artifacts of reading local times as UTC. The h14/h15 UTC
recordings (the other possible reading) also hold no 62-min freeze.
Falsifier: none of the three claimed timeline events (onset
14:39:32Z, track-gone 14:55:48Z, heal 15:41Z) matches any dead run
in the recordings under EITHER timezone reading.

* THE REAL MECHANISMS (v3)

** A. interior_1 (.201) -- stable producer, stall-heal cycle

- 11/11 audio freezes (h12+h17+h18 run maps) healed by producer
  replacement: WRN lands 0-24s AFTER the heal boundary in every case.
- WRN cadence ~105-138/day (median inter-arrival ~5-6min). Freeze
  duration is bounded by the time to the next stall: observed
  10s-13.3min, matching the inter-arrival distribution.
- Onset is silent (TCP read alive, audio data stops).
- Camera-side session logs are CENSORED: .201's syslog ring is
  flooded by ONVIF 401-burst spam (the c346 class) and evicts
  session lines within minutes. Session counts for .201 are
  unreliable; the frigate WRN cadence is the replacement rate.

** B. ext3 (.103) -- reconnect storm, escalating

- go2rtc reconnects to .103 continuously: unique RTSP sessions/day
  (deduped by session id, camera-side ring spans 18h+): Sep 12: 6,
  Sep 13: 16, Sep 14: 102, Sep 15: 181, Sep 16: 221. ESCALATING.
- Median inter-arrival today: 141s (~2.4min), p90 760s.
- Audio deaths are the gaps between reconnects: CONFIRMED by
  alignment -- the h18 dead run (UTC 17:57.04-17:59.44+ = local
  14:57-14:59) sits inside a 9.4min session gap (14:54:23 ->
  15:03:47 local, no new session). Heal = next reconnect.
- Camera RTSP server is HEALTHY (ffprobe returns video+audio in
  ~5s). RSSI flat (-56 to -58 all week). The storm survived a
  frigate restart (Sep 16 15:48). NOT wifi, NOT go2rtc process
  state, NOT camera reboot (camera up since May 25).
- OPEN: why the reconnect rate started climbing Sep 14 02:29 local
  and keeps escalating. Candidates: camera encoder state degrading
  (reboot would test), go2rtc producer state machine stuck in a
  retry pattern, network path degradation invisible to RSSI.

** C. The frigate watchdog is a third actor

- Watchdog ffmpeg restarts today: ext3 384, interior_1 144, ext1 53,
  ext5 50, others ~1-3. Fleet-wide 1607.
- Sep 14: ext2 had 3309 restarts (04:30-13:00, one every 10s) --
  that was the 8.5h .102/.104 camera outage (dial timeouts -> 404s
  -> crash loop). ext4 matched it (3055).
- Watchdog restarts produce VIDEO gaps (ext3 h05-h08 UTC = local
  02-05: 254 restarts, recording gaps 4-25min each).
- The watchdog restart is also a heal path (path B in the earlier
  amendment): a recorder restart re-opens the track.

* WHAT THE SEG-CENSUS MEASURES

The census counts dead-audio segments per hour. For interior_1 it
measures freeze duration distribution (bounded by stall cadence).
For ext3 it measures the reconnect-gap distribution (the fraction
of each hour spent between reconnects). Both are outcomes, immune
to the WRN-proxy problem.

* FALSIFIERS / NEXT

- If .103 is power-cycled and the session rate drops back to
  ~6-16/day, the storm was camera-side state (reboot clears it).
  This is the cheapest decisive test and needs Nacho (physical
  power cycle, same as .104's pending one).
- If the rate keeps escalating (~300+ tomorrow), the producer is
  degrading further; watch the segcensus dead counts grow.
- interior_1's stall cadence (~100/day) vs .202/.203 (12/8) is
  still open. The camera-side session evidence is censored; a
  packet capture or prudynt-side log is needed to see whether
  .201's WRNs open new sessions (they must) and how fast the
  camera answers.

* METHOD SCARS (why this doc exists in v3)

- c372/c373 built a 62-min freeze from container-local times read
  as UTC. The TZ law (c359b) was in the roadmap and I walked past
  it AGAIN: the fix is to reconcile the query window against the
  query clock BEFORE building a narrative on the timestamps.
- The camera-side syslog ring is a CENSORED source for .201
  (ONVIF eviction) and a REAL source for .103 -- ring depth must
  be checked before comparing counts across cameras.
- Snapshot-dumped logs repeat their ring buffers; counts must be
  deduped (by session id, not by line).
* AMENDMENT (c376, 2026-09-16 ~21:20 UTC): the reboot-test falsifier is ANSWERED -- and one claim in v3 was wrong

** CORRECTION: "camera up since May 25" is FALSE for .103

The RSSI puller's uptime column shows .103 reboots NIGHTLY at 03:00
local: uptime resets to ~116s at 03:02 every day (Sep 12, 13, 14, 15,
16 all show the reset; the May 25 timestamp in cameras.log is the
FIRMWARE BUILD TIME the camera boots with before ntpd steps it -- the
c342 camera-boot-clock class). The nightly reboot is FLEET-WIDE:
.201/.202/.102/.105 all show the same ~110s uptime resets. The v3
claim "camera up since May 25" was a misreading of the boot-time
disparity lines as a long uptime. (The "no reboot since May 25"
falsifier in the storm section is withdrawn.)

** THE REBOOT-TEST FALSIFIER IS ANSWERED WITHOUT NACHO

The v3 falsifier "if .103 is power-cycled and the session rate drops
back to ~6-16/day, the storm was camera-side state" is already
answered by the nightly cron: the storm SURVIVES the 03:00 reboot on
Sep 15 (h04-h07: 6/4/3/7 sessions) and Sep 16 (h03-h07: 21/15/19/12/22
-- the WORST hours of the day, immediately after the reboot). A
reboot does NOT clear the storm. The Sep 14 pattern (storm paused
h04-h07 after the reboot, resumed 08:04) was the transition day, not
a heal. Nacho's power-cycle visit is no longer the decisive test for
this class; it remains needed for .104 (power-dead, 0063).

** CORRECTED SESSION CENSUS (cameras.log, deduped by session id)

cameras.log (the c281 syslog sink) has FULL coverage from Sep 13
03:26; the ring-censor law does not apply to it (it is a continuous
stream, not a ring). Unique BackchannelStreamState session ids/day:
Sep 13: 15, Sep 14: 99, Sep 15: 182, Sep 16: 222 (through h18 local).
The v3 numbers (6/16/102/181/221) came from a different dedupe; the
Sep 12 figure predates the sink and is not recoverable from this
source. The escalation is real but DECELERATING in absolute terms
(deltas +84, +83, +40); day-over-day the morning hours still run ~3x
the previous day's same-hour rate.

** NEW MECHANISM EVIDENCE: backchannel sink clog -> session stall

- The camera-side prudynt logger logs ONLY session SETUP
  (BackchannelStreamState, 3 lines per session: RTP ch4/5, ch6/7,
  ch8/9 interleaved channels). There is NO teardown log class: the
  camera never says why a session ends.
- go2rtc's side: every reconnect is preceded by `read tcp ...
  i/o timeout` on the RTSP socket (1962 of them since Sep 14, deduped
  329/399/308 per day -- NOT escalating on the go2rtc side today).
  The i/o timeout means the camera STOPPED SENDING on the TCP
  connection. The storm is camera-side: go2rtc reconnects because
  the camera stalls the session, not the reverse.
- AudioWorker `msgChannel sink clogged` WARNs precede reconnects by
  2-3s in both observed pairs (Sep 14 11:36:26/31 -> reconnects
  11:36:33; 11:37:52 -> 11:37:55). Only 4 WARNs vs 522 sessions: the
  WARN fires only when frames are actually DROPPED (backpressure),
  so it is a sparse marker of the same underlying stall, not a
  per-reconnect log.
- Cross-camera: .103 has 522 unique backchannel sessions in the log;
  every other camera has 9-12 ALL TIME. The stall is .103-specific.
- Session-duration shift: baseline sessions last hours (Sep 13
  22:24:53 session survived 4h4m until the 02:29 storm onset); storm
  sessions have p50 inter-arrival 151s. The camera's RTSP server
  (prudynt, pid 762, unchanged since boot) stops sending on
  established sessions every few minutes.

** WHAT REMAINS OPEN

- WHY the camera's sessions shortened starting Sep 14 02:29 local
  (31min BEFORE that night's 03:00 reboot). No camera-side error log
  exists for session teardown; prudynt logs setup only. A packet
  capture at sophon (who sends FIN/RST first) or prudynt debug logs
  (camera ssh refuses root) are the remaining instruments.
- The 02:29 onset predates the nightly reboot by 31min and is not
  explained by any logged camera event (last prior line: 02:23 ntpd
  crond). The onset trigger is still unidentified.
- The reboot-pause asymmetry (Sep 14 paused h04-h07, Sep 15/16 no
  pause) suggests a state that needs hours to rebuild after a fresh
  boot on day 1 but is immediately present on later days -- or that
  the Sep 14 pause had a different cause (e.g. the 04:30-13:00
  .102/.104 outage changed frigate's producer behavior fleet-wide).
* AMENDMENT 2 (c377, 2026-09-16 ~22:00 UTC): the multi-camera audio night + a false gap withdrawn

** WITHDRAWN BEFORE LANDING: "frigate does not record at night"

Mid-cycle I concluded frigate never records local 21:00-07:00 (UTC
00-09). FALSE. The cause was my own probe path bug: hour dirs are
ZERO-PADDED (`00`-`09`); I probed `recordings/$DAY/0/...` (single
digit), which matches nothing, and read the silent no-match as
absence. The frigate.db recordings table (16924 night segments,
exists=True) broke the story. Frigate records 24/7. Full scar doc:
knowledge/aria/segcensus-hourdir-path-scar-2026-09-16.md. New law:
PATH-SHAPE -- verify a path against a known-good example before
reading "0 results" as absence (file cousin of the empty-grep class).

** TONIGHT'S REAL AUDIO EVENT (all times UTC)

- ext3 (.103): audio dead 19:39-21:37 (~2h), recovered at 21:37 INSIDE
  the session opened 21:25 (last prudynt session of the day; no new
  session needed -- backchannel sink unclogged in place). Storm
  sessions (13) continued through the dead hour h20.
- ext2 (.102): producer-audio-FROZEN since 19:32 UTC (3.5h+ at
  cycle end; verified live: audio receiver bytes 11321698 constant
  across 6s, video climbing 182.6M->182.7M). NO ext2 WRN at freeze
  time; producer id 26 (early, post-15:48-restart) never replaced.
  This is the ext1 freeze class (0073) on a second camera, and the
  first observed instance with a KNOWN onset time.
- int1 (.201): usual stall-heal cycle; h20 fully alive despite WRNs.
- ext5 healthy. ext1 freeze still open (0073).

** NEW MECHANISM CANDIDATE: go2rtc event-loop contention (storm collateral)

Evidence:
1. ext2's audio froze at 19:32 UTC with NO ext2 WRN, the same minute
   ext3's storm WRN burst ended (16:33:19 local = 19:33:19 UTC).
2. int1 WRNs at 16:21:53 and 16:28:39 local are the SAME SECONDS as
   ext3's WRNs -- two cameras timing out on the same second is a
   go2rtc-internal event, not two camera failures.
3. 156 same-second multi-camera WRN pairs across today.
4. RSSI rock-solid (-28..-33 .102, -56 .103) through the window; no
   wifi event.
Mechanism sketch: .103's reconnect storm hammers go2rtc's single
process; during storm bursts other producers' audio receivers stall
(video survives; audio-only freeze, no camera-side timeout, no WRN of
their own). Predicts: ext2/int1 freezes cluster during ext3 storm
bursts; healing when the storm pauses. UNTESTED -- needs a
per-camera freeze-onset census vs WRN-burst timeline (next cycle).

** CORRECTIONS to v3 carried from this cycle

- The WRN is NOT a per-death marker: ext3's go2rtc log had 10 WRNs
  total in the current file vs hours of dead audio; the WRN cadence
  and the audio-death windows only partially overlap. Census numbers
  built from WRN counts are proxies at best.
- prudynt's session log vs go2rtc's live producer state can DISAGREE
  (producer alive + audio flowing with no new session logged since
  18:25 local): the session log is not a complete census of live
  sessions. The DB (frigate.db recordings) is the ground truth for
  what was RECORDED; the go2rtc API is the ground truth for what is
  FLOWING now.
* AMENDMENT 3 (c378, 2026-09-16 ~23:00 UTC): the IP map was wrong -- actors corrected, ext2 claim withdrawn

** THE IP MAP CORRECTION (config order + live go2rtc API, 22:39Z)

The camera->IP mapping used since the storm investigation began is
WRONG. config.yaml lists cameras interior_1,2,3, exterior_1,2,3,4,5
mapping in order to .201,.202,.203,.101,.102,.103,.104,.105. The live
go2rtc /api/streams (nsenter into the container netns) confirms:
exterior_1=.101 (prod 2713), exterior_2=.102 (prod 26), exterior_3=.103
(prod 2658), exterior_4=NO PRODUCER (power-dead), exterior_5=.105 (prod
3433), interior_1=.201 (prod 3355), interior_2=.202 (prod 1167),
interior_3=.203 (prod 2705).

Amendment 2's "ext2 (.102) frozen" claim is therefore DOUBLY wrong:
the camera that froze at 19:32Z was .105 = exterior_5, and the
mechanism was NOT the silent audio-freeze class.

** ext5 (.105) RECLASSIFIED: watchdog-visible stall cascade, not silent freeze

The full ext5 story (all times UTC): producer read-timeouts at
22:30:48, 22:31:15, 22:35:58 (these were misread in c377 as "ext2 WRNs
at 19:30-19:35 local" -- the local times were right, the camera label
was wrong); watchdog "No frames received from exterior_5 in 20
seconds" + ffmpeg restart at 22:36:36; audio recovered after the
restart (h22 latest segment 22:38Z has video+audio). Earlier in the
evening: watchdog restart at 21:40:45 local (18:40 local), h21 census
68 dead of 239 with a CONTINUOUS dead run 42:05-59:57 local (18 min).
This is a video+audio stall that the watchdog CAUGHT and healed -- the
opposite signature of the ext1 silent-freeze class (no watchdog event,
video keeps flowing). ext5's stall is a third signature: visible,
self-healing via watchdog, video dies WITH audio.

** ext2 (.102) is HEALTHY: producer 26 (ancient, pre-15:48-restart),
0 dead segments h17-h21, 1 backchannel configure all day (03:24 local),
10 sessions. Amendment 2's "ext2 freeze 19:32Z" is WITHDRAWN entirely.

** CONTENTION CENSUS RESULT (roadmap item 2, the c377 falsifier)

The contention candidate SURVIVES re-attribution but the actors
changed: it is ext5 (.105) and int1 (.201) that stall around ext3
(.103) storm activity, not ext2.
- int1's WRNs at the SAME SECONDS as ext3's (16:21:53, 16:28:39 local)
  still stand -- two cameras timing out on one second is go2rtc-internal.
- int1 h21 dead run 18:47-40:07 local (~21 min continuous) sits in the
  same evening window as ext3's storm bursts (BackchannelStreamState
  lines 16:14-18:25 local) and ext5's stalls (18:40, 19:36 local).
- ext5's two watchdog stalls (21:40Z, 22:36Z = 18:40, 19:36 local)
  both fall inside/adjacent to ext3 storm activity.
- 134 same-second multi-camera WRN pairs today (c377 counted 156 with
  a different grep; order agrees).
The mechanism sketch is unchanged: .103's reconnect storm hammers
go2rtc's single process; other producers' receivers stall during
bursts. What CHANGED: the collateral damage is visible at the watchdog
level for ext5 (video dies too) and silent for int1/ext1.

** dBFS COLUMN: FOSSIL

frigate.db recordings.dBFS = 0 for ALL 311,604 rows all-time. The
column exists in schema but frigate never populates it. The planned
"dBFS per-segment audio levels" instrument is dead on arrival; do not
build on it. Per-segment dead/alive via ffprobe header parse (the
segcensus method) remains the only working per-segment audio signal.

** LIVE PRODUCER VIEW (new instrument)

go2rtc /api/streams via `nsenter -t $(pgrep -f go2rtc | head -1) -n
curl -s localhost:1984/api/streams` gives the authoritative live
producer map: producer id (monotonic -- high id = recently created),
remote_addr, and the medias list (audio recvonly present = audio
configured). Producer ids tonight: ext2's 26 is ANCIENT (stable since
the 15:48 frigate restart era); ext5's 3433 was created after ext3's
2658, consistent with the 22:36Z restart chain. Worth wiring into
fleet-check as a live-state probe.

** WHAT REMAINS OPEN

- ext3 storm onset trigger (Sep 14 02:29 local) -- unchanged.
- ext1 silent freeze (0073) -- still open, still the only confirmed
  silent-freeze instance.
- int1's ~100/day stall cadence vs .202/.203 (12/8) -- unchanged.
- ext5's h19 102-dead window (17:00-18:00 local) has no watchdog or
  WRN event found yet; run shape pending (dead-runs.py was slow on
  sophon, ~2800 ffprobes; segcensus h22 fire covers h22 counts).
- The "producer replacement heals audio" claim (v3 path A) now has a
  counterexample: ext5's producer WAS replaced (3433) and audio stayed
  dead until the watchdog restarted the whole ffmpeg capture. Heal
  path for ext5 = watchdog, not producer replacement.
* AMENDMENT 4 (c379, 2026-09-16 ~23:25 UTC): ext2 IS the second silent freeze; the ext4 dial loop is the fleet audio killer

** THE BIG CORRECTION: ext2 (.102) is NOT healthy -- it is the SECOND confirmed silent-freeze instance

Amendment 3 said "ext2 (.102) is HEALTHY: 0 dead segments h17-h21".
That was read at ~22:40Z against the segcensus h17-h21 lines -- but
h21's line (230/230 dead) was ALREADY in the file at that time and
was missed, and h19's 102-dead was misattributed in c377 to ext5
(the map bug). Corrected full-day census for ext2 (.102), UTC hours:

  h17: 0 dead | h18: 0 dead | h19: 102 dead (from 19:32) | h20: 225/225 | h21: 230/230 | h22: 225/225 | h23 (partial at 23:24Z): 90/90

Death boundary: 19:32:xx UTC (h19 m32 first dead; m31 alive). NO
.102 WRN anywhere near 19:32 (last .102 WRN all day = 02:00Z). Video
keeps flowing (h23 segs have video-only streams; go2rtc video
receiver 192780 -> 192985 packets over ~2min while audio receiver
FROZE at exactly 41497 packets / 11,321,698 bytes across a 30s
double-probe). Producer 26 is the ANCIENT pre-restart producer --
video receiver alive, audio receiver dead, no WRN, no watchdog
event, no heal in 4 hours.

This is the ext1 silent-freeze class (0073) ON A SECOND CAMERA:
silent onset, video alive, audio receiver frozen at the go2rtc
level, no heal. ext1 was "the only confirmed silent-freeze
instance" -- that claim is now false. Two instances: ext1 (0073)
and ext2 (this).

** THE FLEET AUDIO KILLER TONIGHT: the ext4 (.104) dial-crash loop

.104 is power-dead (0063, since 09-12) but go2rtc keeps dialing it:
8,354 i/o-timeout WRNs + 8,417 watchdog crashes today, ~360/hour
every hour, all day (a crash every ~10s). Tonight's int1/ext5 audio
deaths and heals all align with ext4's crash-restart events within
0-23s:

  int1 death 22:15:19 <-> ext4 WRN 22:15:17 (2s)
  ext5  death 21:42:37 <-> ext4 crash 21:42:23 (14s)
  ext5  death 22:00:01 <-> ext4 crash 21:59:53 (8s)
  ext5  heal  22:30:37 <-> ext4 crash 22:30:34 (3s)
  int1  heal  22:30:57 <-> ext4 crash 22:30:34 (23s)
  int1  death 23:00:0x <-> ext4 crash 22:59:55 (5-14s)
  int1  heal  23:12:38 <-> ext3 WRN 23:12:36 (2s)

7/7 boundaries coincide with another camera's go2rtc event. The
contention mechanism (amendment 3) is now CONFIRMED with timestamps
and the dominant actor is identified: ext4's continuous dial-crash
loop against a dead host. The heal windows (22:30, 23:12) coincide
with the crash events too -- a crash/restart of one producer's
ffmpeg appears to unstick the other cameras' frozen audio receivers
(a go2rtc-internal event, not a camera-side heal).

** COROLLARY: the cheapest fleet-wide audio fix is .104's power cycle

Every int1/ext5/ext2-adjacent stall tonight traces to ext4's dial
loop. .104's physical power cycle (already pending in 0063) kills
the dial loop entirely (no host to dial) and removes the fleet's
dominant contention source. This strengthens 0063 from "one camera
down" to "one dead camera degrading the whole fleet's audio".

** ext5 (.105) h19 run shape (dead-runs.py output, nohup finished)

ext5 h19: 9 dead of 242, minutes 12-14 + 32 (two short runs, not the
102-dead window c377 claimed for "ext2"). The h19 102-dead window
was ext2's (see above). ext5's h19 was nearly clean.

** WHAT REMAINS OPEN

- ext2 silent freeze: needs the ext1-class heal (producer
  replacement). Filed as relay 0075. DO NOT fix from a cycle
  (infra change; ext1's heal was human-ratified).
- ext1 silent freeze (0073): still open, unchanged.
- ext3 storm onset: unchanged.
- The heal mechanism detail: WHY does another camera's crash unstick
  a frozen audio receiver? (go2rtc internals; would need source
  reading or a controlled test.)
- int1's ~100/day stall cadence: unchanged.
* AMENDMENT 5 (c374, 2026-09-17 ~02:10 UTC): ext2 freeze HEALED -- full lifecycle observed; CPU discriminator run; cadence-vs-duration law completed

** EXT2 HEALED AT 02:00:42Z (23:00:42 local) -- watchdog path B, 6h28m freeze

The ext2 (.102) silent freeze (onset 19:32Z, amendment 4) healed
tonight. Full lifecycle, all timestamps verified against primary
evidence (frigate journal + recordings + go2rtc API):

- 19:32Z (16:32 local): audio freeze onset. SILENT -- no WRN, video
  flowing, producer 26 (ancient, born at the 18:48Z container start)
  kept running with a dead audio receiver.
- 16:32-23:00 local (6h28m): ZERO .102 WRNs in the frigate journal.
  The freeze had no scheduled healer (ext2 WRN cadence = 2/day).
- 23:00:06 + 23:00:31 local: two WRNs, "read tcp -> 192.168.2.102
  i/o timeout" -- the producer's TCP read finally died (random).
- 23:00:42 local: watchdog.exterior_2 "No frames received" ->
  Restarting ffmpeg. Producer 26 -> 6107.
- h02 recordings (02:00:42Z+): audio PRESENT (00.00.mp4 = video+audio,
  00.42.mp4 video-only partial, 00.47.mp4 = video+audio).
- h01 segcensus row: 225/225 dead (frozen through 01:59Z). The heal
  lands exactly at the boundary the census predicted.

This is the ext1-0073 class with a COMPLETE lifecycle now observed:
silent onset -> hours of frozen-in-place (TCP alive, audio dead,
no WRN, no heal) -> random TCP read death -> WRN -> watchdog
restart -> heal. The freeze duration is bounded not by stall cadence
but by WHEN THE TCP READ HAPPENS TO DIE. ext2's 2 WRNs/day means
freezes persist for hours; int1's 120/day means freezes last minutes.

** CADENCE-VS-DURATION LAW (completes the v3 table)

24h WRN cadence (the healer rate): ext2=2, ext1=12, int1=120,
ext5=147, ext3=282 (ext4's ~86k dial-timeout WRNs excluded -- dead
camera noise). Freeze duration is inversely bounded by this cadence:
- ext2 (2/day): freezes persist for HOURS (6h28m observed; ext1 0073
  was ~12h).
- int1 (120/day): freezes bounded to minutes (10s-13.3min observed).
- ext3 (282/day + reconnect storm): gaps bounded to ~2.4min median.
The "healthy camera freezes" paradox from c373 is resolved: ext2 was
never healthy -- it is the QUIETEST camera on the fleet, so its
freezes are the longest. Cadence is the healer; quiet cameras freeze
longest.

** GO2RTC CPU DISCRIMINATOR RUN (the c373 falsifier, executed)

343 samples at 1s resolution (frigate container cgroup usage_usec +
go2rtc pid ticks), ext4 dial seconds = sec mod 60 in {1,11,21,31,41,51}
(verified from journal: dials land at :X1 every 10s, 10 lines/burst):
- DIAL seconds: n=8, mean 783ms, max 1139ms
- NON-DIAL: n=76, mean 1100ms, max 1999ms
VERDICT: NO CPU spike at dial seconds. The dial loop is CPU-cheap
(60 WRNs/min + 70 watchdog restarts/10min of LOG noise, but no
compute cost). Amendment 4's contention-by-CPU mechanism has no
support; its alignment evidence was already vacuous (c373). The
int1/ext5 "alignments" in amendment 4 were coincidence structure,
not causation. What remains real from amendment 4: the ext4 dial
loop is journal noise (60 WRNs/min) and .104's power cycle would
clean the logs, but it is NOT the fleet audio killer.

** PRODUCER-ID CHURN IS CONSTANT (producers.log first night)

h00->h01 rows: 6 of 7 live cameras changed producer ids (ext1
5334->6085, ext2 26->6107, ext5 5606->6070, int1 5725->6129, int2
5715->6069, int3 4607->6075; ext3 kept 4577 with zero WRNs). Every
camera with a WRN in the 22:59-23:00 local window got a new id.
Multi-camera WRN minutes recur every ~20-40 min in the evening
(17:33, 17:39, 17:48, 18:15, 18:40, 19:31, 20:12, 20:39, 20:55,
21:01-02, 22:00, 22:59) but with DIFFERENT camera sets each time --
not synchronized fleet events, per-camera read timeouts clustering.
Producer replacement (path A) is routine; the watchdog (path B) is
the backstop when a producer dies without a replacement healing it.

** EVIDENCE FILE

knowledge/aria/ext2-heal-evidence-c374.txt (CPU sample + timeline +
census rows + producers.log rows, pulled from sophon).

** WHAT REMAINS OPEN

- ext1 silent freeze (0073): unchanged (its producer may still be
  frozen; watch for its own random TCP death).
- ext3 storm onset trigger: unchanged.
- int1 cadence asymmetry (~120/day vs int2/int3 ~12/8): unchanged.
- The WRN-wave clustering (multi-camera minutes every ~20-40min):
  new observation, no mechanism yet. Watch whether the waves
  correlate with host load (ollama bursts) or are random.
