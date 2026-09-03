# Scar 46: Silent Track Loss -- output artifacts are the only witness

Written: 2026-09-03 (aria cycle 34). Instances: e2 (17h+), int3 (10h31m),
ext3 (12h09m). All three in one 24h window, 2026-09-03.

## The law

A pipeline can lose a track mid-session with ZERO log evidence on either
end. Neither frigate's logs nor go2rtc's logs ever mentioned any of the
three deaths. The only witness is the output artifacts -- the recorded
segments. For silent track loss, output-watching is not one instrument
among many; it is the ONLY instrument.

## The mechanism (refined through ext3's full arc)

1. A go2rtc producer session degrades: the RTSP connection to the camera
   stops carrying audio (camera-side silent-session class, thingino
   prudynt-t; see flag 270 firmware history) or the session dies quietly.
2. go2rtc's receiver keeps the session open: video flows, audio is
   starved. It does not error, so it does not reconnect.
3. frigate's record ffmpeg reads go2rtc's restream: it writes segments
   with video only (or 1-packet audio headers). No error on this side
   either -- the segmenter just never receives audio frames.
4. Healing requires a reconnect event. Two known triggers:
   a. go2rtc's own read-timeout burst (ext3 16:36 UTC, e3/e4 16:33-16:40
      UTC) -- producer reconnect, audio renegotiated.
   b. a frigate container restart (resets all producers).
   c. (new, cycle 34) a full camera restart: fresh record proc
      renegotiates audio on reconnect (ext3 18:27 UTC return).

## The ext3 full arc (2026-09-03, UTC)

- 04:27:26 last audio segment (22 partial packets); 04:27:24 first
  video-only. Death had ZERO log trace (checked 01:2x-01:3x local window:
  empty). No go2rtc read-timeout, no frigate error. The 04:25-04:28 flap
  (ext1/ext5/int1 crashes) is the presumed trigger; ext3's producer
  degraded WITHOUT any logged error, unlike its siblings which crashed
  and restarted (and healed).
- 04:27-16:36 video-only era, 12h09m.
- 16:36-16:46 go2rtc read-timeout burst -> renegotiation flap:
  36.10 1-packet header, 36.31 real audio (250 pkts), then flappy
  (partial counts 138/0/20/62/343, segment clusters) until ~16:45:58
  stable (508 pkts). Cycle 30's "RECOVERED live-verified" verdict at
  16:57 was mid-flap -- scar 45 rider vindicated.
- 17:00-18:09 uniform aac. Healthy 1h33m.
- 18:10:12 FULL DEATH (connection refused; ping 100% loss, ARP failed --
  power/PoE/cable). Nacho restored power ~18:27:56 (first post-gap
  segment). Fresh record proc renegotiated audio immediately: aac
  53 kb/s verified 18:31+. Expected self-heal confirmed.

## Instrument

knowledge/aria/bin/segment-scan.sh (bdb8ffa): one ssh, binary-walk per
hour, prints the audio/video boundary for a camera's day. The batched
replacement for the per-segment ffprobe walk that burned the cycle-33
cap. Validated live on ext3 (found both boundaries in one pass).

## Corollaries

- A recovery verdict issued during a flap is provisional (scar 45).
  ext3's "recovery" at 16:57 was followed by flap tails and then the
  camera's full death 1h33m later. Positive AND negative controls.
- Camera restart heals audio (fresh session renegotiates). Frigate
  restart heals all producers. go2rtc timeouts heal one producer.
  The cheapest reliable lever for a silent-but-alive camera is a
  frigate restart -- but that resets ALL cameras (flag 326: Nacho's
  call, tests e2 AND int3 heal in one action).
- The camera-side silent-session class (prudynt-t) vs the pipeline-side
  session-degradation class are DIFFERENT diseases with the same
  endpoint. Direct RTSP probe distinguishes them: if the camera sends
  audio on a fresh RTSP session but go2rtc's producer carries none,
  it's pipeline-side.