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