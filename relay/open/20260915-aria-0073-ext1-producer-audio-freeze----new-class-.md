# REQ 20260915-aria-0073
filed: 2026-09-15T05:48Z
filer: aria
class: nacho-test
state: open
urgent: no
title: ext1 producer-audio freeze -- NEW class (go2rtc audio receiver stuck, camera healthy); detector v2.24 built + live-verified
body: |
  NEW CLASS found while building the c353 detector: ext1 (.101) audio
  dead in recordings since 04:31Z 09-15 -- but NOT the c353
  recorder-death class. go2rtc producer 102689's AUDIO RECEIVER froze
  (0-byte delta over 4s, stuck at 52123251B/196916 packets since 04:31Z)
  while its VIDEO receiver keeps flowing on the same session. Camera
  .101 is healthy (direct RTSP decode carries audio, mean -50.6dB; rssi
  flat -27/-28; uptime continuous). Mechanism doc:
  knowledge/aria/ext1-producer-audio-freeze-2026-09-15.md
  
  Context: at 01:31:06-07Z a simultaneous multi-camera RTSP stall hit
  .103/.201/.105 (read-timeouts). .103 recovered (producer reconnect +
  recorder restart), .201 survived, .101's audio froze SILENTLY -- no
  journal event, no reconnect. ext1 segments video-only since 04:31Z
  (31.29.mp4 first dead).
  
  DETECTOR BUILT (as proposed in 0072, extended with this third class):
  fleet-check v2.24 block 1b now distinguishes recorder-death (audio
  flowing) vs producer-audio-freeze (audio stuck, video flowing) vs
  camera-side (both stuck). 2-consecutive-run gate, state file on
  /var/lib/aria-fleet. Live-verified: ext1 currently fires
  PRODUCER-AUDIO-FROZEN (2 consecutive, FAIL=1). Read-only probes only.
  
  REQUEST: none required. .101's nightly cron reboot (01:02Z, verified 4
  days running) should replace the producer and heal it. FALSIFIER: ext1
  audio back in the first segment after ~01:03Z Sep 16. If STILL dead
  after that, the freeze is in go2rtc's receiver state and I request
  your call on a go2rtc restart (service-touching, hence relay).
answer: (none)
## AMENDMENT (c355, 2026-09-15 ~06:50Z) -- boundary re-pinned + recurrence + one correction

1. BOUNDARY CORRECTED: first dead ext1 segment is 04/31.29.mp4
   (04:31:29Z); 31.11.mp4 is the partial (90112 samples). The freeze
   window is 04:31:11-29Z. (c354 said "31.29 first dead" -- confirmed;
   the 90112-sample partial at 31.11 sharpens the boundary.)
2. RECURRENCE (c271 law: re-census before recurrence claims -- done):
   ext5 had a SILENT freeze at ~15:59Z Sep 14 (15/59.57 partial ->
   dead), partial SELF-RECOVERY at 19:03-19:04Z with NO producer
   replacement (no log event at all), stable until the 00:27Z death.
   So this class recurs and can self-heal; producer replacement is
   one heal path, not the only one.
3. PRODUCER-AGE NOT THE TRIGGER: freezes at producer-age ~3.5h
   (ext1), ~11h (ext5 15:59Z), ~19.5h (ext5 00:27Z). Random stall.
4. INSTRUMENT CORRECTION (mine, c354): my "ext5 NO-STREAM all day"
   map was an ffprobe nb_samples artifact -- that field is ABSENT on
   frigate segments even when audio is healthy. The volumedetect
   probe (what fleet-check uses) is correct. Full write-up:
   knowledge/aria/ffprobe-nb-samples-trap-2026-09-15.md. c353's
   ext5 falsifier result RE-VERIFIED with the correct probe: heal at
   05:01Z stands.
5. Falsifier unchanged: .101 cron reboot 01:02Z Sep 16; ext1 audio
   should return in the first segment after ~01:10Z.

## FALSIFIER READ 2026-09-16T16:13Z (aria c369): 01:03Z heal FALSIFIED

ext1 (192.168.2.103) did NOT heal at the predicted 01:03Z Sep 16.
go2rtc producer i/o timeouts continued through 12:40:55Z; the 15:00Z
fleet run shows ext1 audio FLOWING (age 19s, -31.1 dB). Heal window:
~12:41-15:00Z Sep 16 -- ~12h after the predicted window. The freeze
heals on the producer's own schedule (camera-side?), not at a fixed
cadence. Filing stays OPEN; next sighting should log the exact
producer-reconnect timestamp to test whether the heal tracks camera
reboots (the .101 boot at 01:00:14Z did NOT heal ext1's producer --
different cameras, but the timing model needs the correction).

## AMENDMENT (aria c371, 2026-09-16 17:10Z): ext3 = SECOND camera, same class

ext3 (.103) hit the same producer-audio-freeze class today: death #1
~11:21 local (recovered 12:11), death #2 15:30-15:37 local with the
same ring-drain decay (260->10 frames over 7 min, then track gone),
video flowing throughout, camera alive. Detector WATCH run 1 fired at
the 15:00Z fleet run; run 2 (18:03 local) should escalate to
PRODUCER-AUDIO-FROZEN. Forensics:
knowledge/aria/ext3-producer-freeze-journal-flood-2026-09-16.md.

The ask GROWS: this is now 2 cameras in 2 days (ext1 healed 13h late
by camera cron; ext3 pending). The per-camera cron reboot heal is
reactive and slow. Consider the go2rtc-side producer watchdog
(restart the producer when its audio byte-counter stalls while video
flows) -- that is a config change in the frigate container = your
call. Until then each freeze costs the camera's audio until the next
cron reboot.
## AMENDMENT (aria c372, 2026-09-16 ~18:10Z): ext1 HEALED 12:54Z; ext3 mechanism CONFIRMED end-to-end; interior_1 = NEW transient sub-class

1. EXT1 HEALED: audio back in recording at 12:54Z Sep 16 (17/exterior_1
   segments 12.54+ carry audio; 16:00Z hour 222/224 audio). Heal was
   SILENT -- zero journal events for .101 12:30-13:00Z. The 01:03Z
   falsifier window missed; the heal came ~12h late, on the producer's
   own schedule. 0073's ext1 thread can CLOSE (healed); the class doc
   stays for the next freeze.
2. EXT3 MECHANISM CONFIRMED END-TO-END (UTC timeline, from journal +
   segment forensics): RTSP i/o timeouts 14:34:49Z, 14:38:08Z,
   14:39:32Z -> producer replaced -> recorder audio dead from
   14:39:44Z (ring drain, contiguous noaudio) -> track gone 14:55:48Z
   -> RTSP timeout 15:05:18Z -> producer replaced again -> audio back
   15:05:06Z. The heal IS the next RTSP timeout. The freeze is the
   window BETWEEN two producer reconnects. Camera-cron reboots are
   unnecessary for this camera -- the next natural reconnect heals.
3. INTERIOR_1 (.201) = NEW SUB-CLASS: recurring TRANSIENT recorder
   audio deaths, 15-25min each, SELF-HEALING, NO RTSP-timeout
   signature. Census today (segments noaudio/hour): 00:0, 02:128,
   04:103, 06:4, 08:9, 10:0, 12:143, 14:26, 16:0, 17:~100. Deaths at
   ~02-04Z, ~12-13Z, ~17Z (every 5-10h). .201's RTSP timeouts CEASED
   after 14:xxZ -- consistent with the producer going idle-frozen
   (no traffic = no timeout), then recovering. This looks like CLASS B
   (producer freeze) in transient form: freeze -> self-heal before the
   6h fleet-check can catch 2 consecutive runs.
4. DETECTOR GAP (mine to fix): the detector samples only at fleet-check
   time (6h cadence); transient deaths that heal within 3h are
   invisible to it. interior_1 has been cycling through this class ALL
   DAY and the detector never fired. A segment-census puller (hourly,
   count noaudio segments per camera) would catch the transients.
   That is a fleet-check v2.25 item -- mine to build, no ask.
5. Micro-deaths (1-3 contiguous segments, e.g. ext3 16:00Z hour: 3
   singles) appear across cameras; likely the same mechanism at small
   scale. The class family is now: recorder-death (c353),
   producer-freeze (0073), transient-freeze (this amendment).

## AMENDMENT (aria c374, 2026-09-16 ~19:33Z): the c372 "ext3 mechanism CONFIRMED" claim WITHDRAWN -- TZ artifact

Amendment 2 above (c372) is FICTION. The "UTC timeline" was built from
frigate-container log times read as UTC; the container logs LOCAL (-03).
The real UTC window (17:39-18:41Z) shows ext3 audio ALIVE in the
recordings except two short runs. The 62-min freeze does not exist
under either timezone reading. The recordings (UTC hour-dirs) are the
ground truth; the journal narrative was built on the wrong clock.
Doc: knowledge/aria/audio-death-mechanism-v3-2026-09-16.md (a50daeb5).

What replaces it (mechanism v3):
- interior_1 (.201): stall-heal class. 11/11 freezes WRN-healed 0-24s;
  duration bounded by stall cadence (~100/day). Camera-side session
  logs CENSORED by ONVIF spam (ring-censor law).
- ext3 (.103): RECONNECT STORM class, ESCALATING -- unique RTSP
  sessions/day 6->16->102->181->221 since Sep 14 02:29 local. Audio
  dies in the gaps between reconnects (confirmed by alignment: the
  h18 dead run sits inside a 9.4min session gap). Camera healthy,
  RSSI flat, no reboot since May 25, survived frigate restart.
- The ask GROWS differently than c371 framed it: ext3's storm is
  escalating daily and the decisive test is a .103 power cycle
  (physical, yours -- could ride the same visit as .104's pending
  power cycle, relay 0063). If the session rate drops to ~6-16/day
  after reboot, the storm was camera-side state.

## ANSWERED 2026-09-16 ~23:17Z (interactive session, Nacho): cameras deprioritized -- accept the outage

RULING: no action on all camera asks. The cameras are not a priority
right now; the audio/storm/power outages are ACCEPTED for now. Nacho
will fix later and notify when he does.

Consequences:
- The go2rtc producer-watchdog proposal is DECLINED for now (not
  rejected on merits -- deferred with the rest).
- No .103 power cycle, no .104 power cycle, no go2rtc restart. The
  frigate/go2rtc config stays untouched.
- ext1 thread CLOSED (healed 12:54Z, silent, ~12h late).
- ext3 storm + ext2 producer-freeze + interior_1 transients remain
  OPEN as observation-only: detector + segcensus keep running, I keep
  census + falsifiers, no asks. Escalation to URGENT only if a class
  starts destroying evidence (recordings lost) or spreads to all 8.
- 0063 (.104 power cycle ask) stays OPEN but parked on the same
  ruling; it fires when Nacho does the physical visit.

## AMENDMENT (aria c381, 2026-09-17 ~04:16Z): SECOND INSTANCE -- int2
interior_2 (.202) audio died 02:47:11Z sharp (last-audio seg 46.47.mp4,
first-dead 47.11.mp4), video continuous, frigate.db recordings unbroken,
no error logged anywhere. go2rtc producer 6069 alive, SDP advertising 4
audio tracks while recorder segments are video-only. New law-50 member:
SDP-ADVERTISED != PACKETS-FLOWING (producers.log probe reads the frozen
SDP offer; it said audio-yes in the same pull where segcensus counted
49 dead). Producer 6069 was born BEFORE the death => replacement will
not heal (ext5 precedent); remaining heal paths: camera reboot or
frigate restart. Still observation-only per your ruling; falsifiers
armed (06:00Z feed escalation; h06+ segs after the 03:00-local reboot
window). Filing: knowledge/aria/int2-producer-audio-freeze-2026-09-17.md.
Escalation bar unchanged (evidence destruction / all-8 spread).
## AMENDMENT (aria c385, 2026-09-17 ~06:30Z): THIRD INSTANCE + census -- THREE cameras froze overnight, mechanism narrowed to consumer-side backpressure

Overnight census (death minutes pinned by segment ffprobe binary search):
- interior_2 (.202): 02:46:13-02:47:11Z (producer 6069, born 01:05-02:05Z)
- exterior_1 (.101): 04:54:04-04:55:03Z (producer 8147, born 03:05-04:05Z)
- exterior_3 (.103): 05:51:09-05:52:15Z (producer 9028, born 04:05-05:05Z)

All three: camera audio ALIVE (direct RTSP probes, 94KiB/3s each),
video flowing, recorder segments video-only since death. Healthy:
ext2/ext5/int1/int3. Producer age at death 42-110min in all three --
but c355 already showed producer-age is not the trigger (3.5h/11h/19.5h
prior instances), so the tight window tonight is probably coincidence
of the churn cadence, not a law.

MECHANISM RECONCILIATION (resolves the c382 contradiction): the freeze
is CONSUMER-side. The recorder ffmpeg (PID 1241, alive since container
start 18:48Z 09-16) stops draining its audio track; the producer audio
receiver's queue fills and its bytes counter stalls (looks frozen, is
actually blocked). Producer replacement does NOT heal (ext5 precedent)
because the new producer's audio queue fills the same way. The int2
"producer receiver frozen" observation and the ext5
"replacement-doesn't-heal" observation are the same disease seen from
two layers. Prediction for the 07:00Z .202 reboot: audio STAYS dead
unless the recorder ffmpeg restarts (it only restarts on VIDEO
failure). Falsifier: h07 segcensus (11:05Z pull). Doc:
knowledge/aria/audio-freeze-census-3-cams-2026-09-17.md.

Detector note: ext1+ext3 froze AFTER the 03:00Z fleet-check, so they
were invisible until the next feed; the 06:00Z feed run (09:00Z UTC)
should flag all three. Observation-only ruling unchanged; escalation
bar (evidence destruction / all-8 spread) unchanged -- 3/8 frozen is
within the accepted outage, but the SPREAD RATE (1->2->3 cameras in
3 days) is now the number to watch.

## ANSWER (c386, 2026-09-17 ~07:10Z): falsifier resolved -- disease is CAMERA-side

The 07:00Z .202 reboot healed int2: producer 6069 -> 10007, recorder
audio back by 07:01:38Z. The c385 consumer-side backpressure theory
in this filing is FALSIFIED; the c353 producer-replacement-heals
mechanism is CONFIRMED.

The packet census (tcpdump on the camera->sophon RTSP connections,
interleaved-frame channel census) pins the layer: frozen cameras
(int2/ext1/ext3) send ZERO audio-channel RTP frames on their
established connections while healthy cameras send hundreds, and a
FRESH connection to a frozen camera carries audio immediately. The
camera's prudynt silently drops the audio track mid-connection.
go2rtc's stalled receiver counter is starvation, not backpressure.
No log trace at any death minute (go2rtc WRN or camera camlog).

Heal path: the nightly camera reboot staircase (each camera reboots
on its own cron; ext1 01:00Z, ext3 03:00Z). Observation-only ruling
stands; escalation bar unchanged. A longitudinal ch2-census detector
(read-only packet census) is filed in the roadmap as the next
instrument if the class keeps recurring.
## c387 amendment (2026-09-17 ~08:00Z): class doubled -- 5 instances,
## two heal paths, fleet-wide spread

Full-day ffprobe transition scan (09-16 h19 + 09-17 h00-h07, all 8
cams) found two more deaths and refined the mechanism:

- ext3 09-16 19:33Z death, healed 21:37:16Z (2h04m, NO reboot --
  next boot was 09-17 03:02Z). Its 21:01 WRN burst (4x read
  timeout) did NOT heal it; audio returned 36min later with no WRN.
- ext5 09-17 07:25:57Z death, healed 07:32:06Z (6m9s, no reboot).
  A go2rtc read-timeout WRN fired 10s AFTER audio returned =>
  producer replacement is the heal.

TWO HEAL PATHS now observed: (1) camera reboot (int2), (2)
producer replacement via full-stall WRN (ext5; ext3-0916 likely).
Death remains silent at all five death minutes. Conn age at death
spans 2h23m-19h45m -- not an age timer.

FLEET-WIDE: healthy cams show sub-10min transients of the same
class (int1 9m13s + 4 shorter; int3 3x 1-2s; ext2 5s; ext5 18
windows/30h). 5/7 alive cams froze at least once in 30h. The
long-freezers (ext1/ext3) and the flappers (int1/ext5) are the
same disease at different stall cadences.

Spread status vs the 0075 escalation bar: 5/7 alive cams affected
in 30h. If a 6th camera freezes long tonight, that trips the
all-8 bar and the observation-only ruling should be revisited.

Doc: knowledge/aria/audio-freeze-census-3-cams-2026-09-17.md
(c387 amendment, a18502dd).
## AMENDMENT (c13, 2026-09-17 ~08:30Z) -- the ch2 census is now a standing instrument

The c386 packet census (45s manual tcpdump + interleaved-frame
parse) is now a standing hourly organ: ch2-census-puller.sh v1.0 +
aria-ch2-census.{service,timer} on sophon (fires :05 past each
hour). Counts ch2 (audio) frames on each camera's ESTABLISHED
producer connection; frozen cams read ch2=0, healthy 245-374 per
20s window. Validated 3 runs + cross-checked vs segcensus on all
three states (frozen/healing/healed) -- consistent. Output:
/var/lib/aria-fleet/ch2census/<cam>.log with FROZEN flag.

This sharpens the falsifier for the original 0073 request: ext1
has been frozen since 04:55Z 09-17 with ch2=0 in every run. Its
01:02Z reboot tonight is the heal; the h01 ch2 row should flip
0 -> hundreds. If it does NOT, the freeze survived a reboot AND a
producer replacement, which would be a new mechanism class and
would justify the go2rtc-restart request this filing reserved.

No new request. Observation-only stands (0073+0063 answered).
Doc: knowledge/aria/audio-freeze-census-3-cams-2026-09-17.md
(c388 addendum, bbd6da4a).
[2026-09-17 12:00Z aria c19 amendment] UNIFIED MECHANISM FOUND. int1's
"recorder-side" deaths (c18) are the SAME producer-freeze class: prudynt
silently stops audio RTP on the established conn; video keeps flowing so
go2rtc never times the conn out. All six int1 death blocks (21:03 09-16,
02:08, 04:17, 07:33, 08:03-08:26, 08:39-08:46 local) healed EXACTLY at
go2rtc read-timeout reconnects (producer replacement) or the 08:47:14
ffmpeg restart. ext1's 5h22m freeze healed the same way (07:17:04
reconnect). Difference is stall cadence only: .201 full-stalls ~59x/day
=> minute-scale freezes; .101 rarely => hour-scale freezes. The 12:05Z
segcensus row for int1 should carry STALE-MAJ (falsifier). Camera-side
root cause (why prudynt drops audio) still needs the physical visit --
rides 0062. Doc: knowledge/aria/int1-recorder-audio-mechanism-2026-09-17.md
(844c2ba1). Observation-only ruling stands; no new request.

## AMENDMENT (aria c37, 2026-09-18 ~00:50Z): ROOT CAUSE CLASS FOUND + first self-executed heal + API scar repeated

1. TRIGGER FOUND: the two 09-17 night freezes (ext1 22:37:41Z, int1
   23:02:25Z) both landed within seconds of MULTI-CAMERA WRN BURSTS
   (>=3 distinct cameras getting go2rtc i/o timeouts in one 10s
   window). Bursts are frequent (17 in 6h); audio deaths are rare --
   burst is necessary-but-not-sufficient. AP map: nacho_guest
   (72:7f:f0:1e:4a:a8) and nacho_camaras (08:8a:f1:6a:62:56) BOTH on
   channel 1 (2417 MHz) -- co-channel interference between the two
   networks is the shared-infrastructure candidate. RSSI stable
   through bursts => SINR-level, not signal-level. Doc:
   knowledge/aria/ext1-mechanism2-heal-2026-09-18.md (94440014).
2. FIRST SELF-EXECUTED HEAL under D-018: ext1 frozen 2h12m (producer
   15, aac flat 39723, no WRN, no watchdog -- detect consumes video
   only). Killed the exterior_1 record proc (c264-verified path);
   frigate restarted it; producer 15 -> 729; aac growing; ffprobe
   confirms video+audio in fresh segs. Mechanism 2 does NOT self-heal
   on ext1 without conn death or intervention.
3. SCAR REPEATED (c386): my PUT used name=<url>&src=exterior_1 --
   INVERTED -- which DELETED the exterior_1 registration (PUT 200 !=
   verified heal, second occurrence). Fixed from my own API doc:
   PUT ?name=<stream>&src=<source>. Verify the registry after ANY PUT.
4. segcensus DEAD counts MISSING SEGS (video gaps), not audio deaths:
   ext1 hour-22's 84/225 = the ext1 seg-gap pattern (14 min x 6),
   NOT the freeze. Audio-freeze evidence chain = ffprobe codec_type
   + ch2 census + API packet delta. Three instruments, three things.
5. UPSTREAM #2505 material now complete: two mechanisms + costs +
   co-channel trigger + the fix ask (per-track staleness detection).
   Draft update rides the next quiet cycle.

## AMENDMENT (aria c104, 2026-09-19 ~12:10Z): int1 WATCH fossil + fleet-check CLEARED verified; interior_1 = the flapper

1. FOSSIL CONFIRMED + CLEARED: the 09:01:40Z fleet run left
   "interior_1 1" in recorder-audio-dead.state (run-1 WATCH on a
   producer-audio-freeze that healed 09:05:10Z). The 12:01:40Z run
   correctly emitted "interior_1 recorder-audio-death CLEARED" (I
   re-ran fleet-check live: interior_1 audio flowing, -38.9 dB, 3/3
   fresh segs sampled). The 1b CLEARED watch from c97/c98: PASSED --
   the state file is not a liar; it was a fossil-window artifact
   (0091), now overwritten. State file now empty.
2. NEW TRANSIENT (c102 find, confirmed): segcensus h10 row
   354/32-dead = freeze ~10:54Z, self-healed by 11:05Z. Third int1
   transient this week. ch2 census 11:00-11:10 rows (154/156/166
   aframes) caught the heal in progress. The 5-min ch2 cadence is
   the only instrument that sees these; 6h fleet cadence never will.
3. int1 (.201) is now the fleet's flapper: minute-scale freezes,
   self-heals at producer replacement or transient. Full-stall WRN
   cadence ~59x/day (c19 amendment). No action needed; the class is
   documented (0073 thread). Observation-only stands.

## AMENDMENT (aria c116, 2026-09-19 ~17:22Z): tri-cam event resolved as high-churn cohort; heal mechanism re-verified; .104 census-blind fixed

1. TRI-CAM EVENT (c114) REFRAMED: int1/ext3/ext5 simultaneous freeze
   15:35-16:05Z was the high-churn cohort reaching simultaneous freeze,
   not a new shared cause. Full-day conn-replacement census: int1=8,
   ext3=7, ext5=4 distinct producers vs 2-3 for healthy cams. WRN
   census: .201=94, .103=82, .105=68 vs .101/.102=2. Cohort stable
   across days. Shared-cause question shifts to "why do .201/.103/.105
   churn 4-8x more" (AP ruled out -- different APs; firmware/model
   census next). Doc: knowledge/aria/tri-cam-freeze-2026-09-19-c116.md.
2. HEAL MECHANISM (c114 "frigate restart healed" DOWNGRADED): all
   three healed at the 16:10Z census row with NEW producer conns; the
   16:07:08Z restart is CONFOUNDED with the natural reconnect cycle
   (WRN cluster 13:42-13:54Z preceded the heals by ~15-25min). Heal =
   producer replacement, consistent with every prior instance. The
   heal-without-replacement falsifier remains UNSTRUCK (0 observed).
3. .104 (ext4) WAS NEVER CENSUS-BLIND-BY-BUG -- it was EXCLUDED from
   CAMS in v1.0. Direct RTSP digest-auth probes today: .104 serves
   audio fine on FRESH connections (157 audio frames/10s, 3/3
   attempts) but cannot sustain long-lived producers (478 WRNs today,
   watchdog give-up 14:09-14:19Z, self-healed 14:19:58Z via watchdog
   respawn + producer replacement). "Power-dead" label WITHDRAWN for
   the current state (09-12..09-16 WAS genuinely L2-dead -- different
   mode). ch2-census v1.2 adds .104 to CAMS (pushed, live at next
   fire). The most freeze-prone cam is now watched.
4. Observation-only ruling unchanged. No new ask. The cohort-churn
   discrimination (firmware version, AP, client count per cam) is the
   next census -- no new code needed, one config census.

AMENDMENT (aria c132, 2026-09-19 ~23:59Z): the class definition has
evolved since this filing. Current state (knowledge/aria/
audio-freeze-c132-ext5-int2-forensics-2026-09-19.md):
- Producer-audio-freeze: durations 60s-29min+, onsets WRN-heralded
  (i/o timeouts), heals = producer replacement (new sophon local port),
  video keeps flowing through the freeze. c132 confirmed both onsets
  WRN-heralded and both heals producer-replacements on ext5/int2.
- NEW sibling class, CONSUMER-STARVE: recorder stalls with NO WRN and
  a healthy producer conn (census healthy at the same minute). int2
  23:04:46Z 09-19 is the second confirmed instance. Healed by watchdog
  restart. Distinct signature; distinct heal.
- The ch2 census can FALSE-DEAD under TCP reassembly failure; the
  v1.4 ARTIFACT guard (commit 5b9ef516) now discriminates. Any freeze
  claim from census alone should be cross-checked against recordings.
The detector work in this filing remains valid; the class taxonomy
above supersedes the single-class framing.

## UPDATE 2026-09-20 ~00:45Z (aria, interactive-session census): fleet audio state healthy; ext5/int2 fleet-FAILs were stale

Live ch2 census (00:45Z): all 8 cameras ch2 373-376 frames -- ZERO
frozen right now. The 18:04Z fleet-latest NO-AUDIO FAIL-LINEs for
exterior_5/interior_2 are STALE: both healed by ~19:05Z (segcensus
h19-h22 shows the dead-run then 0 dead rows; census-contradiction
already annotated by fear-organ v1.5).

48h freeze census (ch2 FROZEN rows, 5-min cadence): int1 73 rows
(many short windows, chronic churn class), ext5 64 (worst single
window ~3.2h on 09-18), ext3 52 (cluster 09-19 10:20-15:xxZ, healed
via producer WRN reconnects), int2 36 (02-04Z + 14-18Z 09-19), ext4 6
(revived camera now flapping -- marginal RSSI -67/-72, rides the AP
fix in 0045/0055), ext1 1, ext2/int3 0. NO camera is frozen now;
no long-freeze active anywhere. Observation-only ruling (09-16/09-17)
stands; spread bar not tripped (no NEW long-freezer class tonight).

## AMENDMENT (aria c163, 2026-09-20 20:27Z): the class family re-modeled (v3)

The c161/c162 window-level decomposition is superseded by
knowledge/aria/sync-audio-death-clusters-2026-09-20.md. Head changes:
the watchdog mass-restarts (c162 "B3") are HEAL events, not killers;
audio-track losses self-heal in seconds more often than not; the
remake-heal model is falsified for WRN-bracketed windows (10/13 heal
before the next remake); the census sees audio death as ch2 byte
collapse without FROZEN (int3 62/61 vs 350 baseline). This filing's
class (producer-audio freeze, silent) remains a member of the family;
the family model is now v3 (per-segment attribution, recovery =
whichever comes first: self-heal / remake / restart). No state change
to this filing -- still open on Nacho's queue as part of the class
taxonomy (0073 carries the c132+c150+c151 amendments).
