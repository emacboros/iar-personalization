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
  ASK: one frigate restart (podman compose restart or systemctl
  restart frigate) now that all cameras are up. FALSIFIER: ext2 and
  int2 segments must carry real audio within one segment cycle after
  the restart. If they do not, my mechanism is wrong and I will
  re-examine. Fleet FAIL=1 stays honest until then.

  POST-REVIEW AMENDMENT (cycle 241, reviewer-delegated): the
  falsifier above is a HEAL test, not a mechanism test -- every
  candidate mechanism predicts full healing. A successful restart
  justifies the restart but must NOT be recorded as confirmation of
  the connect-during-down framing. The law is restated in
  knowledge/aria/audio-death-law-2026-09-12.md (addendum): the
  record ffmpeg audio leg dies when its session does not survive
  (ext2: predates the producer renegotiation) or is born during
  (int2: attaches mid-renegotiation) a go2rtc producer
  renegotiation. Discriminating tests for the next staircase night
  are listed in the doc addendum.

  ADDENDUM (cycle 242, ~09:20Z): int3 (interior_3) had a 3-segment
  audio gap at 08:38-08:40Z that HEALED ITSELF with no process
  restart -- a transient class the law does not cover (law covers
  permanent death). After the frigate restart, int3 should also be
  healthy. Signatures now: 250 pkts healthy / 1 pkt stub (ext2,
  int2 permanent) / 0 pkts stream-absent (int3 transient) /
  partial truncation. Detail: audio-death-law doc addendum 2.
  UPDATE 2026-09-12 ~10:15Z (cycle 244): fine-grained death anatomy +
  transient class second instance. Addendum 3 in the doc. Key new
  facts: (1) ext2's death is BOUNCED-THEN-PERMANENT -- audio briefly
  returned 02:00:20-00:46Z (340 pkts, 21.76s) then died at the second
  renegotiation; (2) int2 attached mid-reboot, got ~11s of audio, died
  at the first post-reboot renegotiation; (3) ext4 suffered a
  TRANSIENT (08:19:52-09:36:11Z, healed with NO restart) -- the
  fleet-check NO-AUDIO at 09:02Z caught it mid-transient; it has
  flapped again since (10:47Z). The permanent deaths (ext2, int2) are
  unchanged; the frigate-restart heal test is unchanged. ext4's
  flapping is .104's chronic instability (13 producer renegotiations
  in 5h) -- each renegotiation is a coin-flip for every consumer leg.

SELF-ANSWER 2026-09-12T17:30Z (aria c260): the amendment WAS the answer (journald healthy, TZ artifact). ext2 audio root cause followed in c241 (audio-death law v2). Heal watch scheduled post-01:00Z staircase tonight.
