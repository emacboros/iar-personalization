# The Audio-Death Law (2026-09-12, cycle 241)

## The finding

Frigate's per-camera record ffmpeg loses its AUDIO leg whenever the
process (re)connects while the camera is down (reboot window). The
session that results carries video forever and audio never: segments
get an AAC track with 0 samples. The camera side is innocent -- the
RTSP source and the go2rtc restream both carry audio the whole time
(verified live: 190-200k samples in a 12s probe on every camera).

## Evidence (all 8 cameras, one table)

Record-ffmpeg start times (frigate container local = UTC-3) vs camera
reboot times (staircase crontabs, .101=01Z ... .203=08Z):

| cam | record start (UTC) | reboot (UTC) | delta | audio now |
|-----|--------------------|--------------|-------|-----------|
| ext1 | 01:00:41 | 01:00:00 | +41s | OK |
| ext2 | 17:53:45 Sep11 | 02:00:00 | PRE-reboot (stale) | DEAF |
| ext3 | 03:01:05 | 03:00:00 | +65s | OK |
| ext4 | 07:19:53 | 04:00:00 | +3.3h | OK |
| ext5 | 05:01:14 | 05:00:00 | +74s | OK |
| int1 | 06:01:34 | 06:00:00 | +94s | OK |
| int2 | 07:00:30 | 07:00:00 | +30s | DEAF |
| int3 | 08:01:34 | 08:00:00 | +94s | OK |

Every deaf camera is explained; every healthy camera is explained.
ext2 holds a PRE-reboot session (stale-session mechanism, c235 class);
int2 connected 30s into its camera's reboot window (connect-during-
down mechanism). One end state, two paths.

## Why the camera side was exonerated

- thingino configs identical between deaf (.102) and healthy (.101):
  prudynt.json audio block byte-for-byte comparable, mic_enabled
  true, gain 25, AAC.
- dmesg audio init lines identical.
- Live RTSP probe of .102 and .202 directly: audio flows
  (198656 / 193536 samples in 12s).
- go2rtc restream probes of interior_1/interior_2/exterior_2: audio
  flows on all.
- All 8 go2rtc producer SDPs carry m=video + m=audio.

## The wrinkle

ext1 restarted 41s after its reboot and audio survived -- .101's RTSP
comes back faster than .202's. There is no clean second threshold;
the law is "connect during camera-down," and camera-down duration
varies. The observable law: a record ffmpeg that starts in the
reboot window risks a dead audio leg for the life of the process.

## Fix and falsifier

One frigate restart (Nacho, relay 0050) re-inits every record process
while all cameras are up => all 8 audio legs should come back. The
falsifier is unchanged and now sharper: after the restart, ext2 and
int2 segments must carry real audio within one segment cycle. If they
do not, the connect-during-down law is wrong and the stale-session
mechanism needs re-examination.

## Prediction

int2 audio will also return on the frigate restart (its record
process is fresh but was born during the camera-down window). Until
then, fleet-check FAIL=1 on ext2+int2 NO-AUDIO is the honest signal.
# Addendum (cycle 241, post-review): the law restated at the strength
# the evidence supports

The first version of this doc stated the law as "connect-during-
camera-down." The reviewer (delegated, c241) broke it on two points,
both correct:

1. ext2's record process connected at 17:53:45Z Sep 11 with the
   camera UP and audio flowed ~8.5h; the audio died at the 02:20-
   02:46Z producer renegotiation while go2rtc was still sending aac
   bytes into the process (c233's primary-source check). That is a
   renegotiation-under-consumer death, not a connect-during-down
   death. The law as first stated covered int2 only (n=1).

2. The ext3 cell: c233 recorded ext3's record ffmpeg as "00:01:05Z"
   (pre-reboot, audio intact -- a counterexample). Resolution: c233
   mislabeled container-local time as UTC (00:01:05 local = 03:01:05
   UTC = +65s after the 03:00:04Z reboot). The CURRENT ext3 process
   started 05:01:34 local = 08:01:34Z (+94s after the 08:00Z
   reboot). Both ext3 observations fit the law; c233 carried the TZ
   suffix error (4th sighting of that family, in my own record).

## The law, restated

The record ffmpeg's AUDIO leg dies when its RTSP session to the
go2rtc producer does not survive -- or is born during -- a producer
renegotiation. Two paths, one end state:

- PREDATE path (ext2): the consumer's session predates the camera
  reboot; the producer renegotiates with the rebooted camera; the
  old consumer's audio mapping dies (go2rtc keeps sending bytes the
  old ffmpeg never decodes). ext2 is the confirmed instance.
- ATTACH-DURING path (int2): the consumer attaches while the
  producer is down/mid-renegotiation (camera rebooted 07:00:00Z,
  record restarted 07:00:30Z, camera RTSP still returning); the
  session it gets carries video forever, audio never. int2 is the
  confirmed instance.

Healthy cameras attached 65s-4h after their reboots, after the
renegotiation had completed. ext1 (+41s) survived because .101's
RTSP recovers fast; the recovery-time variable is UNMEASURED --
prudynt starts its RTSP listener at S31, before ntpd, so the
listener may be up while audio is not yet flowing. The window
boundary is a free parameter, not a law.

## What the frigate restart will and will not prove

A restart resets record processes AND go2rtc producers while all
cameras are up. Every candidate mechanism predicts full healing.
So a successful restart confirms only: "consumer/producer session
state is the disease; restart is the heal." It does NOT confirm
the connect-during-down framing. Do not record it as such.

## Discriminating tests (for the next staircase night)

1. Any record process that PREDATES its camera's reboot and stays
   healthy through the renegotiation = evidence against the
   renegotiation law (and for a per-process state variable, c233's
   backward-time-error-history hypothesis).
2. Any record process that attaches 30-90s after a reboot: track
   audio outcome per camera against the measured RTSP/audio
   recovery time (probe .202 and .101 at 5s resolution tonight).
3. Pre-restart self-heal of ext2/int2 audio would kill the
   "for the life of the process" clause.

## Corrections to the first version

- "190-200k samples on every camera" overclaims: direct probes ran
  on 2 cameras, restream probes on 3, SDP-presence on the rest.
- The falsifier in relay 0050 is a heal test, not a mechanism test.
  It justifies the restart (which is Nacho's action) but must not
  be recorded as mechanism confirmation.
- c235-class citation for the stale-session mechanism should read
  c233 (the ext2 stale-session diagnosis is c233's).
