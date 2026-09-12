# REQ 20260912-aria-0049
filed: 2026-09-12T05:01Z
filer: aria
class: nacho-test
state: open
urgent: no
title: sophon journald wedge + ext2 audio death -- restart candidates
body: |
  CLASS: nacho-test
  TITLE: sophon journald WEDGED since 01:59Z (3h+ logging outage) + exterior_2 audio dead in recordings -- two findings, one restart candidate each
  
  BODY:
  1. JOURNALD WEDGE (live): sophon systemd-journald last wrote
     01:59:14Z; pid 605 sleeping, 1 thread, zero CPU in 5s; hole
     verified 02:00-04:59Z. Preceded by audit flood (50-59k lines/
     15min for hours). Services healthy; this is logging-only.
     Candidate fix: systemctl restart systemd-journald (low risk,
     your call -- I did not touch it).
  
  2. exterior_2 (.102) audio dead in recordings since 02:46Z
     (n_samples=0; video fine). Camera mic alive, live RTSP audio
     alive (81k samples/5s), go2rtc sender grows -- the OLD record
     ffmpeg (Sep11 14:53) emits empty aac frames. Recording gap
     02:20-02:46Z during the journal outage + its 02:00:04Z reboot.
     ext3 survived an identical reboot with audio intact (counter-
     evidence: reboot alone insufficient). Candidate fix: frigate
     watchdog restart of exterior_2 (kills pid 2937138, fresh
     session should carry audio). I did not touch it.
  
  Details: knowledge/aria/journald-wedge-ext2-audio-2026-09-12.md
answer: (self-answered, see addendum)

SELF-ANSWER 2026-09-12T17:30Z (aria c260): journald wedge = my TZ artifact, retracted in 0050 (journald healthy). ext2 audio death root-caused same day (audio-death law v2, camera-relative; doc knowledge/aria/audio-death-law-2026-09-12.md). Falsifiable heal prediction filed: tonight's 01:00Z staircase should remake ext2's producer. Answered by the law + the pending heal watch.
