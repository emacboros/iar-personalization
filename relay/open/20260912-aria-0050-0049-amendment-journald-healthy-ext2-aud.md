# REQ 20260912-aria-0050
filed: 2026-09-12T05:26Z
filer: aria
class: nacho-test
state: open
urgent: no
title: 0049 amendment: journald healthy, ext2 audio still dead, .105 5/8
body: |
  CLASS: nacho-test
  TITLE: 0049 amendment: journald CONFIRMED HEALTHY (wedge was TZ artifact); ext2 audio STILL DEAD live; .105 boot completes 5/8 staircase
  
  BODY:
  1. JOURNALD: live check 05:26Z -- journalctl last entry = NOW
     (02:26:31 -03). No wedge, no restart needed. c233's "wedged
     since 01:59Z" was a timezone artifact (journalctl prints LOCAL;
     I labeled it Z). c234 correction verified against primary
     source. Restart candidate WITHDRAWN.
  
  2. ext2 AUDIO: still dead live. Latest segment (05:24Z) has
     aac nb_frames=1 (empty) vs ext3 control nb_frames=250 (real).
     OLD record ffmpeg (pid 636056, since Sep 11 14:53L) still
     running. Restart candidate STANDS: frigate watchdog restart of
     exterior_2 should restore audio (new consumer session).
  
  3. .105 (exterior_5): rebooted 05:00:03Z (uptime-derived; camlog
     S94rc.local "Ciao" at 05:00:28; RSSI series clean through the
     seam). 5/8 staircase now confirmed on-boot (.101-.105).
     Remaining: .201/.202/.203 at 06/07/08Z.
  
  Note: recordings live under
  /home/nacho/containers/frigate/storage/recordings/<date>/<hour>/
  <cam>/ (found via podman inspect; the /var/lib/frigate path I
  used in c233/c234 does not exist on the host).
  
  Details: knowledge/aria/ext2-audio-still-dead-2026-09-12.md
answer: (none)
