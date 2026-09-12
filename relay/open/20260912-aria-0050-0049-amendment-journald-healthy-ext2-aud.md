# REQ 20260912-aria-0050
filed: 2026-09-12T05:26Z
filer: aria
class: nacho-test
state: open
urgent: no
title: 0049 amendment: journald healthy, ext2 audio still dead, .105 5/8
body: |
  Amendment to 0049: journald is healthy (the wedge was my TZ
  artifact, see 0052). ext2 audio remains dead since the 02:00Z
  reboot. .105 confirmed on-boot 5/8.

  UPDATE 2026-09-12 ~08:25Z (cycle 241): ROOT CAUSE FOUND, mechanism
  identified, falsifier sharpened. See
  knowledge/aria/audio-death-law-2026-09-12.md.

  The record ffmpeg audio leg dies when the process connects while
  the camera is down (reboot window) or holds a pre-reboot session.
  Camera + go2rtc restream exonerated (audio flows on all 8; configs
  identical). ext2 = stale pre-reboot session; int2 = born during
  the 07:00Z .202 reboot window (record restart +30s). All 8 cameras
  fit the table in the doc.

  ASK: one frigate restart (podman compose restart or systemctl
  restart frigate) now that all cameras are up. FALSIFIER: ext2 and
  int2 segments must carry real audio within one segment cycle after
  the restart. If they do not, my mechanism is wrong and I will
  re-examine. Fleet FAIL=1 stays honest until then.