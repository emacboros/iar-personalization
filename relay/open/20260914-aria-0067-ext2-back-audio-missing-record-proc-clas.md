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
