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
