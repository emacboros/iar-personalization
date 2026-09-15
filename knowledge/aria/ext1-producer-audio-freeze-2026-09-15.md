# Ext1 (.101) producer-audio freeze -- NEW class (c354, 2026-09-15 ~05:40Z)

## The claim

A SECOND way recorder audio dies, distinct from c353's recorder-track
death: go2rtc's producer audio RECEIVER froze inside an otherwise
healthy producer session. Camera sends audio (direct RTSP decode
carries 84992 samples, mean -50.6dB); go2rtc's video receiver on the
SAME producer session keeps flowing (video delta 18-92KB/4s); the
audio receiver counter is STUCK (0 delta, frozen at 52123251 bytes /
196916 packets since 04:31Z). Recorder faithfully writes what it gets:
video-only segments.

## Timeline (all UTC)

- 01:01:05Z: ext1 recorder (ffmpeg PID 566270) restarted by frigate
  watchdog after RTP corruption (bad cseq, AU header errors) at 22:00-22:01
  local. Audio WORKS after this restart (segments 01:06Z+ carry 256000
  samples) -- recorder connected to producer 102689, which was ALREADY
  running (id predates ext2's 103534).
- 01:31:06-07Z: simultaneous RTSP read-timeouts on .103 (x4), .201 (x2),
  .105 (x1) -- a multi-camera RTSP stall. NIC counters normal (rx ~7MB/min
  continuous), RSSI flat on all three. No ext1 timeout logged.
- 01:31:11-29Z: ext1 audio dies in segments (31.11.mp4 partial 90112
  samples, 31.29.mp4 first video-only). NO journal event for ext1.
  NO producer reconnect for ext1 (producer id still 102689).
- 04:31Z-05:45Z: ext1 segments video-only. Producer audio receiver
  frozen the whole window; video receiver flowing.
- Camera .101 healthy throughout: rssi rows continuous (-27/-28),
  uptime continuous, nightly cron reboot 01:02Z (boot epoch verified
  1789434003 = 01:00:03Z, uptime resets at 01:02Z daily).

## Why this is NOT the c353 class

c353 (ext5/ext2): recorder loses its audio track when the PRODUCER
reconnects; stream stays healthy; producer audio flows.
c354 (ext1): producer audio receiver itself froze; NO reconnect; the
recorder never got audio to lose. Same heal (producer replacement),
different failure point (go2rtc's receiver vs frigate's recorder).

## The 01:31:06Z multi-camera stall

Three cameras' producers hit read-timeouts within 2 seconds. Outcomes
diverged: .103's producer reconnected (new id 106447) + its recorder
restarted 01:33:02Z -> audio fine. .201 survived (audio fine, transient
aac decode errors only). .101's audio receiver froze silently. The
stall's cause is unknown (no NIC collapse, no system journal entries);
it recurs (42 .103 timeouts since 01:00Z, pairs at 01:22/01:24/00:52/
00:01). WATCH: simultaneous multi-cam producer stalls are a distinct
observable -- worth correlating with ext1-class freezes.

## Heal + falsifier

.101's cron reboots it at 01:02Z nightly (verified 4 consecutive days:
uptime resets 01:02:00Z). The reboot kills producer 102689; a fresh
producer should rebind audio. FALSIFIER: first ext1 segment after
~01:03Z Sep 16 carries audio (n_samples > 0). If still dead, the freeze
is in go2rtc's receiver state, not the producer session, and a go2rtc
restart (relay) becomes the fix.

## Detector (fleet-check v2.24 block 1b, built + live-verified this cycle)

Same two probes distinguish three classes:
- A: segments dead + producer audio FLOWING -> RECORDER-AUDIO-DEAD (c353)
- B: segments dead + producer audio FROZEN + video FLOWING -> PRODUCER-AUDIO-FROZEN (this doc)
- C: segments dead + producer audio+video FROZEN -> camera/stream class (ear check covers)
A and B FAIL loudly (house-side fault, camera healthy); 2 consecutive
runs (6h cadence) to fire, watch line on run 1. State file:
/var/lib/aria-fleet/recorder-audio-dead.state ("cam runs" pairs).
Live-verified: ext1 fires WATCH run 1, then PRODUCER-AUDIO-FROZEN (2
consecutive) with FAIL=1.

## Relay

0073 filed (nacho-test): go2rtc restart option vs waiting for the
01:02Z cron heal; detector build report (done, no objection needed --
read-only probes only).
