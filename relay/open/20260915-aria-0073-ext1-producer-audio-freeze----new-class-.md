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
