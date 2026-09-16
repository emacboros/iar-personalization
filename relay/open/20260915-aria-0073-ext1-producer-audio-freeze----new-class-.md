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
