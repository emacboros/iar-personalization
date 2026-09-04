# Frigate Watchdog + go2rtc Census (2026-09-04, aria cycle 5, flash)

Primary evidence: frigate container logs (podman logs, all-time =
container lifetime since 2026-09-01 23:41:06 -03). Counts are
pattern-dependent (see Discrepancy section).

## All-time watchdog restart counts (grep "Restarting ffmpeg")

| cam | restarts | no-frames | crashed | 24h restarts |
|-----|----------|-----------|---------|--------------|
| exterior_4 (.104) | 1941 | 629 | 30 | 138 |
| exterior_3 (.103) | 326 | 70 | 107 | 182 |
| interior_1 (.201) | 94 | - | - | 76 |
| exterior_5 (.105) | 87 | 16 | 33 | 72 |
| exterior_1 (.101) | 47 | - | - | 44 |
| interior_2 (.202) | 8 | - | - | 4 |
| interior_3 (.203) | 5 | - | - | 1 |
| exterior_2 (.102) | 3 | - | - | 3 |

ext4 is the fleet's flappiest by ~6x over ext3 (c4 said 10x with the
other pattern; both patterns agree on the ranking). ext4's signature:
629 "No frames received in 20 seconds" vs 30 crashes -- a STALLING
camera (stream goes quiet, ffmpeg starves). ext3's signature is the
inverse: 107 crashes vs 70 no-frames -- a BREAKING camera (ffmpeg
dies mid-stream). Different failure classes on the two flappiest cams.

## go2rtc producer WRN census (producer.go:170, i/o timeouts)

All-time by camera IP: .104=703, .103=126, .105=30, .201=27, .101=10,
.202=8, .203=8, .102=4. Same ranking as watchdog counts -- the two
instruments agree. ext4 (.104) dominates.

Error classes all-time: i/o timeout dominates (447); two RTP parse
errors ("RTP header size insufficient", "start from CONN state"),
one "buffer too small" (.201). No auth errors, no 404s at the go2rtc
layer -- camera-side RTSP serves fine when the network path works.

## The two burst windows (Sep 3, all times LOG-LOCAL = UTC-3)

### Burst A: 01:00-01:53 log-local (04:00-04:53 UTC) -- FLEET-WIDE
- go2rtc i/o timeouts on .101/.104/.105/.201 within the same minutes.
- ffmpeg crash storms: ext1 32 + ext5 39 + int1 35 + ext4 1 = ~107
  restarts; 404 DESCRIBE storms (ffmpeg -> go2rtc restream 404s:
  ext1 81 + ext5 93 + int1 81 = 255) -- go2rtc's restream API 404s
  while the stream object is down.
- Signature: simultaneous multi-camera timeouts = NETWORK event, not
  camera event. 01:00 local is suspiciously round. Sep 2 had no blip
  at that hour (single data point). FOR-NACHO: router scheduled-reboot
  question (flag posted, msg 375).

### Burst B: 15:10-16:05 log-local (18:10-19:05 UTC) -- ext3 + ext4
- ext3: 104 restarts in 15h. Trigger: go2rtc producer read-timeout
  15:09:53 -> ffmpeg demux timeout 15:10:11 -> crash -> restart ->
  go2rtc dial REFUSED/TIMEOUT loop (10s cadence, 92 timeouts + 12
  refusals = camera's RTSP port down = camera rebooting/power-cycling).
  15:27:21 "exceeded fps limit" + DTS/PTS invalid-dropping storm =
  renegotiation chaos as camera came back. Nacho's power-restore
  ~18:27 UTC (msg 331) == 15:27 log-local -- the recovery matches.
  Scattered restarts 15:39/15:47/15:55/16:04 = aftershocks. Stable
  after 16:40.
- ext4: 6 restarts in the same window (13h-16h had 18+4+6+14 = 42).
- This burst was ALREADY explained (flag 331, camera power). The
  census adds the mechanism detail: refused-then-timeout dial pattern
  is the camera-boot signature (port closed -> host down -> port up).

### The 23:47-23:53 UTC window (ext4 audio loss, c4's "silent" claim)
TZ-corrected: NOT silent at the session layer. go2rtc WRNs at
log-local 20:50/20:51/20:53 (= 23:50-23:53 UTC) + frigate no-frames
restarts 23:51:32/23:52:12 UTC. The session flap was VISIBLE. What
was silent: the audio TRACK loss inside the surviving session
(23:53:48 -> 00:24 UTC video flowed, audio dead, zero log lines).
REFINED SILENT-TRACK-LOSS LAW: session loss is loud (watchdog +
go2rtc WRNs); track loss inside a live session is invisible to logs
-- only segment-dB instruments see it. c4's "third confirmation" was
a TZ artifact; the law survives in narrower form.

## Pattern discrepancy (open question for fleet-check v2.14)

c4 counted 667 ext4 restarts with a pattern that included more
watchdog line types; today's "Restarting ffmpeg" grep gives 1941
all-time / 138 in 24h. The c4 number was probably a bounded-window
count, not all-time. Both agree ext4 dominates. fleet-check v2.14
must pin ONE pattern and document it (pattern-dependence law: a
census number without its grep is not reproducible).

## Design notes for fleet-check v2.14 (BUILD decision, not built)

- One podman-logs grep per check, batched into the existing ssh.
- Per-camera 24h restart counts + fleet total; threshold: alert on
  any camera >20/24h OR fleet >100/24h OR any camera with >10
  restarts in a single hour (burst detector).
- go2rtc WRN count per camera as a second line (producer health
  distinct from consumer health).
- 404-storm detector: >50 404s/hour on any camera = go2rtc restream
  down = network/camera event (Burst A signature).