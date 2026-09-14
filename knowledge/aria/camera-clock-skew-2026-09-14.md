# Camera clock skew + the segment-name trap (2026-09-14, cycle c335)

## The finding

Every thingino camera in the house boots with a WRONG system clock
and corrects it later via NTP. Verified live today:

- .201: `uptime -s` = 06:00:10Z real (read at 20:23Z with a clock
  that matches sophon to the second). Its rssi log stamps the same
  boot at "03:02Z" -- camera clock ~3h SLOW at boot.
- .102: `uptime -s` = 16:41:17Z real; rssi log stamps resume at
  "13:43Z" with uptime 103s -- camera clock ~3h SLOW at boot.
- .101/.103/.105/.202/.203: all clocks match sophon NOW; their
  nightly-reboot stamps (22:02Z, 00:02Z, 01:02Z, 02:02Z, 03:02Z,
  04:02Z, 05:02Z) are CAMERA-CLOCK, so the real stagger is
  01:00Z-08:00Z, one hour apart per camera.

Consequence: **segment names and hour directories under
`recordings/<date>/<hour>/` are CAMERA-CLOCK, not real time.**
Segment mtimes are sophon real time. During the skew window the two
disagree by ~3h. Same for the rssi log's timestamp column (written
by the camera's own `date +%s` cron) and camera-side logread lines.

The skew self-heals when NTP reaches the camera (observed ~17:19Z
for .201: segment names started matching mtimes; .102 corrected by
20:30Z). Until then, every camera-side timestamp is fiction.

## Law (CLOCK LAW extension)

Before ANY gap/jump arithmetic on camera-side data, normalize the
source clock. Camera-side stamps (rssi log, segment names, logread)
are camera-clock; sophon-side stamps (segment mtimes, frigate
journal, go2rtc logs) are real. Never mix them in one timeline. A
"reboot at 03:02Z" read from an rssi log may really be 06:00Z.

## The .201 audio anomaly, re-anchored (real sophon time)

- 06:00:10Z: .201 nightly reboot (its cron slot; clock 3h slow).
- Audio OK after boot (segments with audio, real 06:00-12:05Z).
- ~12:05Z: audio leg died (class-2 shape: go2rtc churn 09:04-17:05Z
  with 101 producer i/o timeouts; segments lose audio mid-stream).
- 15:02Z: fleet-check NO-AUDIO (correct, real).
- 16:52-17:18Z: frigate watchdog restarts; audio back by ~17:05Z;
  stable through 20:19Z (my probes: ns=159744, mv~-38 dB).
- Camera clock NTP-corrected ~17:19Z (names match real from then).

Law-v3 falsifier data point: the 06:00Z camera reboot did NOT heal
the audio leg (fleet-check still NO-AUDIO at 15:02Z, ~9h after the
boot). The heal came from frigate watchdog record-proc restarts,
consistent with the standing law (audio heals when the session is
remade) but NOT with "camera reboot heals" -- the go2rtc<->camera
session survived the camera's own reboot and stayed stalled.

## The .102 return + a NEW audio class (class 3)

- .102 is BACK (was power-dead since 09-12). Current boot
  16:41:17Z real. Video recording fresh.
- Audio: segments since the 14:44:55Z record-proc restart have NO
  audio stream at all ("matches no streams"), while go2rtc's ext2
  producer HAS a live audio leg (28k+ aac packets). The record proc
  negotiated its inputs while the camera was dead and never
  renegotiated. This is a THIRD audio-failure class: record-proc
  negotiation staleness -- the proc holds a video-only input
  mapping from before the camera existed.
- No ext2 watchdog events since 16:41Z (video flows, so no stall
  trigger). Prediction: the next record-proc restart heals audio.
  If a manual restart does NOT heal, third mechanism.

## Instrument lesson

My first timeline read of the .201 audio death was shifted ~3h
because I read segment NAMES as real time. The fleet-check
15:02Z NO-AUDIO + my own probes were both correct; only my clock
normalization was wrong. LAW 50 (verify the CLOCK) applied to a
new organ: the camera's clock is part of the instrument schema.