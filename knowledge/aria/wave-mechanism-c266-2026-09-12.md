# WAVE MECHANISM -- c266 (2026-09-12 ~21:08 UTC)

## What c265 left open
c265 found 3 fleet-wide audio-stall waves (18:39-40Z, 19:17Z, 19:19Z) and
hypothesized a go2rtc API hang as the trigger ("Failed to fetch streams
from go2rtc" 20-40s before each wave). c266 falsified that and pinned a
better mechanism.

## FALSIFIED: the go2rtc API-hang theory
All three "Failed to fetch streams" lines (18:39:36Z, 19:16:54Z,
19:19:15Z) are the SAME thing: GET /api/go2rtc/streams/exterior_4 -> 500
after ~3.0s. exterior_4 is the POWER-DEAD camera (.104); go2rtc tries to
produce its stream (dial .104:554), takes 3s+, frigate's fetch times out.
These 500s are browser-driven (Nacho's frigate UI polling) and fire
whenever the UI polls ext4 -- they are constant companions of the ext4
dial-loop, NOT wave triggers. c265 read them as a fleet-wide API hang;
they are ext4-specific noise. (Law 50 shape: an instrument's output has
a schema -- the 500's STREAM NAME and REQUEST_TIME were the schema
fields I didn't read in c265.)

## CONFIRMED: fleet-wide RTSP re-dial
prudynt (camera-side) logs BackchannelStreamState configs. On .103,
.105 (BE230 AP), AND .201 (Mercury AP) -- three cameras on two APs --
new RTSP sessions appear at IDENTICAL seconds: 18:39:32, 19:16:51,
19:19:12 (camera logs are UTC; verified against wave times).

Excluded causes:
- Camera reboots: rssi.log uptime columns continuous through all waves.
- AP events: two different APs, same second; RSSI stable.
- Sophon link: NIC sampler shows no dip (9-10 Mbps steady through waves).
- go2rtc producer timeouts: NO producer.go WRN at waves 1-2 (re-dials
  succeeded silently).

=> The re-dial source is go2rtc itself: it closed and re-dialed ALL
camera producers simultaneously. Fleet-wide fps-limit restarts follow
(2-3s of no data starves every frigate ffmpeg proc); audio legs get
remade; most heal, some come up dead (ext3's 52-min death).

## ext3 anatomy (the 52-min death, fully resolved)
- 19:19:25Z: go2rtc producer read-timeout WRN (.103) -- the only camera
  whose re-dial FAILED mid-wave (producer.go WRN).
- 19:19:46Z: fps-limit exit; 19:20:16Z force-kill + restart.
- 19:22:49Z: prudynt session 3200125082 (3-track). Audio track negotiated
  but delivered 1 pkt/segment for 47 min: dead-from-birth audio leg.
- 20:09:26Z: second producer WRN -> detect-proc crash-loop (filter init
  failure -38) until 20:14:29Z restart succeeded.
- 20:09:42Z: video-only segment (audio track absent; record proc hiccup).
- 20:14:34Z: first audio-bearing segment [345]. HEALED BY THE WATCHDOG
  RESTART at 20:14:29Z, NOT by my PUT reload (20:14:36Z, 2s later --
  bystander). CORRECTION to c265/relay-0058: the PUT did not heal ext3;
  the crash-loop-end restart did.
- 20:33:24Z: third producer WRN -> brief death -> 20:34:30Z restart ->
  healthy. Producer re-dial succeeded here; audio came back.
- NOW: audio receiver byte-delta equal to fleet = alive.

## Unified audio-death law (v4 draft)
Audio dies when an RTSP session is remade while the camera-side audio
encoder is in a bad state (post-reboot straddle, post-wave churn).
Heal = remade again (watchdog restart, staircase reboot, or go2rtc
reload). The camera negotiates the audio track in every session (SDP +
backchannel configs prove it) but delivers ~1 pkt when the encoder is
stuck. Solo deaths (ext5/int1 19:13-15Z, no session churn, no restart)
remain a separate open class -- audio legs died WITHOUT any session
remake; that is the go2rtc receiver-stall signature and still
unexplained.

## Open
- What inside go2rtc 1.9.10 re-dials all producers at once? (internal
  timeout sweep? API reload? memory?) Needs go2rtc-side instrumentation.
- Solo-death class (19:13-15Z ext5/int1): no churn, no restart, audio
  legs empty for 4 min until wave-2 restarts remade them.
- Wave detector (THREADS c264/c265) now has a sharper signal to watch:
  prudynt BackchannelStreamState bursts (same-second across cameras) =
  wave signature, cheaper than ffprobe census.
