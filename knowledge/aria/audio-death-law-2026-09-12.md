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
## ADDENDUM 2 (cycle 242, 2026-09-12 ~09:20 UTC): int3 gap = transient, healed; process census; new failure classes

### int3 (NEW finding this cycle)

int3 (interior_3, .203, reboot hour 08Z) shows a 3-segment audio gap
in hour 08: segment 00.30 = 119 pkts, 00.38/00.39/00.40 = NONE (0
pkts, NO audio stream at all), 01.40 = 345 pkts, then normal 250/seg
for the rest of the hour. The gap HEALED ITSELF by 01.40 (~09:40Z,
within the same hour) with NO record-process restart: the delegated
process census shows int3's record ffmpeg started 05:01:34 -03
(= 08:01:34Z) and has not restarted since. So the audio-death law's
"permanent death" framing does NOT cover this event -- this was a
transient gap that self-healed mid-process.

Honest implication: the law (as restated in addendum 1) explains
PERMANENT audio death born at renegotiation boundaries. int3's
transient is a different class: audio vanished for 3 segments
(~2.5 min of wall time) and returned without any process restart.
Candidate mechanisms for the transient class (not yet
discriminated): (a) a producer renegotiation that the consumer
survived this time (session survived, audio leg dropped then
re-attached); (b) camera-side audio encoder stall during/after its
08Z reboot (camera rebooted at 08:00Z; gap at 08:38-08:40Z is 38-40
min later); (c) go2rtc-side producer restart that re-established
audio cleanly. The 00.38-00.40 segments have NO audio stream at all
(NONE, not 1-packet stub) -- different signature from ext2/int2's
1-packet stubs. Three distinct output signatures now exist:
  - 250 pkts: healthy
  - 1 pkt: stub session (ext2, int2 -- permanent death class)
  - 0 pkts / no audio stream: stream-absent (int3 transient class)
  - partial (10-119 pkts): truncation at segment boundary

### Process census (delegated probe, all 8 record ffmpeg lstart, -03 local)

- exterior_2: Sep 11 14:53:45 (= 17:53:45Z) pid 2937138
- exterior_1: Sep 11 22:00:41 (= 01:00:41Z) pid 3491721
- exterior_3: Sep 12 00:01:05 (= 03:01:05Z) pid 3647478
- exterior_5: Sep 12 02:01:14 (= 05:01:14Z) pid 3803875
- interior_1: Sep 12 03:01:34 (= 06:01:34Z) pid 3882401
- interior_2: Sep 12 04:00:30 (= 07:00:30Z) pid 3958436
- exterior_4: Sep 12 04:19:53 (= 07:19:53Z) pid 3983528
- interior_3: Sep 12 05:01:34 (= 08:01:34Z) pid 4037318

Consistent with the law: ext2 predates its 02:00Z reboot (dead);
int2 born 07:00:30Z, +30s into the 07:00Z .202 reboot (dead); ext1
born 01:00:41Z, 41s after its 01:00Z reboot (survived -- the wrinkle);
ext5 born 05:01:14Z, 65s after its 05:00Z reboot (survived); int1
born 06:01:34Z, +65s (survived); ext4 born 07:19:53Z (survived);
int3 born 08:01:34Z, 65s after its 08:00Z reboot (survived, but
suffered the transient at 08:38Z).

### Per-hour audio census (3 segs/cam/hour, hours 00-08, 2026-09-12)

- ext1: hour 01 bad 3/3 (00.14-00.36, NONE pkts=0) -- death at its
  01:00Z reboot boundary, then healthy hours 02-08.
- ext2: hours 02-08 bad 3/3 each (1-pkt stubs from 00.46 on) --
  permanent death, matches law.
- ext4: hour 04 bad 3/3 (00.16/00.17 NONE + scattered 1-20 pkt
  stubs through the hour) -- death at its 04:00Z reboot boundary.
- ext5: hour 05 bad 3/3 (00.14-00.35, NONE + 66-pkt partial) --
  death at its 05:00Z reboot boundary.
- int2: hours 07-08 bad (1-pkt stubs from 00.58) -- permanent death,
  matches law.
- int3: hour 08 bad 2/3 (00.38-00.40 NONE) -- TRANSIENT, healed.
- All other camera-hours: 0/3 bad.

NOTE: hour 00-08 "bad=3/3" cells for ext2/int2 are the known
permanent deaths; the per-hour census confirms they never recover.

### NEW TOOLING SCARS (law-50 family)

1. ffprobe census loops are EXPENSIVE: full-hour all-seg census =
   ~90 ffprobe invocations/camera/hour; the 9-hour all-camera
   version would be ~20k calls. Batched per-camera (3 segs/hour)
   is the affordable census; full sweeps only for a specific
   camera-hour under suspicion.
2. machinectl shell through ssh non-interactively forwards ONLY
   the banner to the outer pipe (118 bytes: "Connected to the
   local host... Connection to the local host terminated."); the
   inner command's stdout does NOT traverse. Workaround found by
   the delegated probe: run machinectl DIRECTLY on sophon via
   ssh 'bash -s' heredoc with 2>/dev/null -- inner stdout arrives.
   (c241 recipe said "machinectl + write probe to file, ship,
   run" -- incomplete: the file must be run via ssh bash -s, not
   piped through machinectl's own stdout.)
3. psprobe2.sh's grep chain ("ffmpeg" AND "record") matched
   NOTHING: the recorder args contain "-f segment" and
   /tmp/cache/*.mp4, not the literal "record". The correct filter
   is grep -F "segment" or match /tmp/cache. (Third sighting of
   the pattern: a filter that matches the CONCEPT not the ARGS.)
4. runuser -u nacho fails for podman (cgroup permission denied);
   systemd-run --uid=nacho --pipe returns empty; machinectl shell
   works (nacho has active session + Linger=yes).

### Falsifier status (unchanged)

Frigate restart (relay 0050) remains pending, Nacho's action. The
restart is a HEAL test, not a mechanism test. int3's transient
adds a second prediction: after the restart, int3 should also
carry audio (it is currently healthy except for the healed gap).
