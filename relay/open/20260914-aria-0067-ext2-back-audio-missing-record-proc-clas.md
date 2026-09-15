# REQ 20260914-aria-0067
filed: 2026-09-14T20:35Z
filer: aria
class: nacho-test
state: open
urgent: no
title: ext2-back-audio-missing-record-proc-class-3
body: |
  exterior_2 (.102) is BACK after 2+ days power-dead (boot 16:41:17Z
  real, video recording fresh). But its frigate record proc (running
  since the 14:44:55Z restart, through the camera's death and reboot
  without a stall) negotiated its inputs while the camera was dead:
  segments since then have NO audio stream at all, while go2rtc's
  ext2 producer has a live audio leg (28k+ aac packets). Third audio
  class: record-proc negotiation staleness.
  
  REQUEST: none urgent -- prediction is the next record-proc restart
  heals audio (watchdog fires on any 20s no-frames stall). If you
  want it fixed NOW: a frigate container restart (heavier) or wait
  for the watchdog. I will watch and report whether the prediction
  holds. Also FYI: .102's power came back on its own (no relay
  answer needed on 0063 for .102; .104 still dead).
answer: (none)

## STATUS NOTE 2026-09-14T23:32Z (aria c340): prediction still unverified, staleness confirmed 7h later

Re-probed 23:17Z: ext2's newest segment (23/17.17.mp4, age 2s) is
STILL hevc,video only -- control exterior_1 is hevc,video + aac.
No record-proc restart since container start 09-10 (frigate
recording_manager etime 4d19h; container restarts=0). The ext4
watchdog storm (20:16-20:17Z, 10 restarts) was exterior_4's ffmpeg
only -- did not touch ext2's record proc, and it stopped at 20:17
(ext4 has no segments since, consistent with .104 power-dead).

Prediction unchanged: next record-proc restart heals. No action
needed from you unless you want it fixed now (container restart
would do it).
## STATUS NOTE 2026-09-14T23:55Z (aria c341): PREDICTION FALSIFIED -- class 3 is self-healing, not restart-gated

Full-history shape census of ext2 segments (53,887 files,
2026-07-05 -> now, 12-point probe + binary searches on the
audio/video-only boundary):

1. The current video-only span started 15:34:07 sophon (18:34Z),
   NOT at the camera reboot (~01:00Z). The boundary is one segment
   (33.21.mp4 AUDIO -> 33.47.mp4 video-only, 15:33:47 -> 15:34:07
   sophon). No restart, no journal event, no gap.
2. The recording_manager has NOT restarted since 09-01 and is
   writing video-only segments RIGHT NOW while BOTH live probes
   (camera .102 direct AND go2rtc restream 127.0.0.1:8554/ext2)
   carry hevc,video + aac,audio. The consumer side dropped audio
   on its own; the source is healthy.
3. PRECEDENT: 09-08 had an identical episode (video-only 10:13 ->
   16:59 sophon, ~6h46m) that SELF-HEALED with no record-proc
   restart (segment-tree evidence; journal retention only reaches
   09-12).

Revised model: class 3 = intermittent renegotiation failure in
the recording pipeline's audio path (go2rtc -> record-proc
ffmpeg), hours-long, self-healing. A restart would likely
re-negotiate (still sufficient), but it is not the mechanism and
no longer urgent. No action requested: watch for the next
self-heal; if ext2 flips back to AUDIO without a restart, the
restart prediction dies completely. Note: the 15:33:28 go2rtc
producer i/o-timeout burst (.103/.201) landed 1 min before the
transition -- possible correlate, unproven.
  ADDENDUM (aria c343, 2026-09-15 ~01:00Z): DROP TIME PINNED + recovery
  observed. ext2 audio was BACK with the camera's 16:41Z recovery
  (segments 17:00-18:33Z all have audio), then dropped again between
  18:33 and 18:34Z -- silently (no ffmpeg restart, no journal error at
  that moment). Video-only from 18:34Z onward through 00:45Z (6h11m).
  The 09-08 precedent: drop -> self-heal after ~6h46m. Prediction: audio
  self-heals ~01:20Z 09-15. Next cycle probes 01:20-01:30Z segments.
  If healed: class-3 confirmed as periodic renegotiation failure with
  ~6-7h period. If not: the precedent was a coincidence, reopen.
  Note the audio DID return once already today (17Z) -- consistent with
  the renegotiation-failure model (each camera-side stream renegotiation
  has a chance of dropping audio; the recording pipeline picks it up or
  not until the next renegotiation).
