# WAVE MECHANISM -- PRODUCTION-CONFIRMED (c280, 2026-09-13)

## The find

c268's mechanism (page load -> mic-probe AddTrack -> Reconnect() ->
full RTSP session remake fleet-wide -> +24s watchdog restarts) is now
OBSERVED IN PRODUCTION, three times on 09-12, with camera-side
witnesses. The c279 "biggest wave of the day, unwatched" (16:17-16:19)
was actually waves 2 and 3 of a single viewer session that started at
15:39 -- and the 15:39 wave was found by pulling further back.

## The three waves (frigate logs LOCAL -03; cameras UTC)

| wave | login | go2rtc GETs | fps-limits | delta |
|------|-------|-------------|------------|-------|
| A | 15:39:23 | 15:39:32-33 (7 cams) | 15:39:56-15:40:05 | +24-33s |
| B | 16:16:42 | 16:16:51 (7 cams) | 16:17:15-16:17:23 | +24-32s |
| C | 16:19:07 (reload) | 16:19:12-15 (7 cams) | 16:19:36-16:19:46 | +24-34s |

All from one external IP 181.28.154.180 (Nacho's viewer). GETs are
paramless `/api/go2rtc/streams/<cam>` -- the mic-probe is inside the
frigate proxy handler (CodecAny match on producer medias), NOT visible
in the URL. Confirmed: zero "microphone" strings in nginx log; the
frontend always probes.

## Camera-side witnesses (camlog BackchannelStreamState sessions)

Every camera logged a new `Configuring stream for TCP (session N...)`
at exactly the GET times (UTC): 18:39:32Z, 19:16:51Z, 19:19:12Z on all
7 alive cameras. The backchannel session IS the mic-probe AddTrack
landing on the camera. This closes the loop: page GET -> frigate proxy
-> go2rtc AddTrack -> camera sees a new backchannel TCP session ->
Reconnect() remade the producer session -> detect ffmpeg died of
fps-limit 24-34s later -> splice markers -> heal.

## Sample #3 reclassification (ext1 00:29:04Z = 21:29:04 local)

The 21:29:31 fps-limit (c279's "non-splice caveat" event) has a
camera-side backchannel witness at 21:29:04 local (+27s to fps-limit --
the SAME signature as the waves) and NO page traffic (only a scanner
probe at 21:25). So sample #3 is a mic-probe-class session remake
WITHOUT a page load -- either a direct go2rtc API hit, a stale
consumer re-probing, or the producer-side re-dial. Dialer identity
still open (relay 0060 falsifier would settle it). DTS gap at
21:30:01: 14.5 BILLION us = 4.0h of audio timeline (detect's audio
clock had drifted 4h ahead of the camera's new session).

## The 08:10:22Z fleet-wide RTP stall (new class, NOT solo-death)

5 producers (ext3/int1/int2/ext5/ext4) read-timeout simultaneously
(read tcp ... i/o timeout on ESTABLISHED connections), re-dials got
connection-refused for ~40s, then all recovered. NO fps-limits, NO
splice markers, NO page traffic, NO camera reboots (staircase boots
were 05Z/06Z/07Z, hours earlier; NIC stayed 10M, no 60s-granularity
flap). Classification: transient fleet-wide RTP stall, self-healed,
cause unknown. NOT the solo-death class (that requires a detect death +
splice + heal). Filed as its own observation; watch for recurrence.

## The +24s constant

All three waves: first fps-limit lands +24s after the GET batch. This
is go2rtc's watchdog restart interval (c268). The spread 24-34s = per-
camera detect timing after the session remake. The +24s signature is
now a reliable fingerprint: any fps-limit exactly +24-34s after a
backchannel session = session-remake class.

## What this changes

1. The wave detector seed (THREADS) now has a precise trigger to watch:
   fleet-wide backchannel sessions (camlog) + +24s fps-limits (frigate).
2. Sample #3 joins the mic-probe family (remake without page), not the
   solo-death family -- though the solo-death samples #1/#2 (int1 19:00,
   ext5 19:13 09-12) still lack camera-side witnesses and remain open.
3. Fix (a) -- drop the microphone param from frigate's go2rtc proxy --
   would have prevented ALL THREE waves. Relay 0060 ratify ask stands.

[EXTERNAL DATA]: none -- all primary evidence from sophon logs.