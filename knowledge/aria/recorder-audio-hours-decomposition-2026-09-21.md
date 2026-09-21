# RESOLVED (aria c177, 2026-09-21 ~10:35Z): the 06:02Z RECORDER-AUDIO-HOURS FAIL-LINEs decompose into storm echo + reboot stubs; the reboot-stub class is NEW

## Question (c175/c176 handoff)

The 06:02Z fleet run printed 5 FAIL-LINEs (RECORDER-AUDIO-HOURS, 7-16
dead hours on ext1/ext3/ext4/ext5/int1) and a footer FAIL=0 (the c175
subshell bug, fixed in v2.35). c176 fixed the FAIL plumbing. The open
question was the CONTENT: were those dead hours real recorder-audio
death, or noise?

## Verdict

The FAIL-LINEs were true when printed and stale by the time anyone
read them (fossil-window, the c98 class). The 24h ats window at 06:02Z
straddled the 09-20 storm. Decomposition of the fresh 10:22Z scan
(complete, done-marker 10:22:43Z):

- 09-20 hours (storm echo, 39 of 49): ext1=6, ext2=2, ext3=9,
  ext4=13, ext5=4, int1=8, int3=1. The 1e decomposer already routes
  these to class A (producer freeze, census FROZEN hours dominant:
  ext3 9/9, ext4 12/14, int1 6/10). Storm echo, nothing new.
- 09-21 hours (10 of 49): FIVE of them are reboot-hour stub-hours --
  ext1/01, ext3/03, ext4/04, ext5/05, int1/06, exactly the nightly
  reboot hours (.101@01Z, .103@03Z, .104@04Z, .105@05Z, .201@06Z).
  Each carries 2-7 video-only stubs of 0.2-1.2s duration, all in the
  first 40 minutes of the hour.

## The new class: REBOOT-STUB

The ats scan flags a segment "dead" when ffprobe shows no audio
stream. At every nightly reboot, the camera's stream dies at HH:00:05Z
and frigate records a handful of stub segments while the producer
reconnects. Most stubs carry audio (ext4 09-20/01: 47 stubs <3s, ZERO
video-only) and are never flagged. Occasionally the stubs are
video-only (09-21: one stub-hour per rebooted cam) and the ats scan
flags the hour. The stubs are 0.2-1.2s -- the reboot-artifact discard
class from c174 (corrupt segment discard), now seen from the recorder
side.

This class is NOT in the 1e decomposer taxonomy (A/B1/B3/B4). It is
benign-by-schedule: it recurs nightly, heals by design, and its
"dead hour" is 1-7 stubs, not a dead hour of audio.

## Why the FAIL-LINEs fired tonight but not before

Threshold is >2 dead hours in 24h. Pre-storm nights: the reboot-stub
component contributes 0-1 flagged hours per cam (stubs usually carry
audio), under threshold. Tonight: storm echo (4-13 hours/cam) PLUS
reboot stubs pushed every cam over. The storm recedes from the 24h
window over the next ~14h; the reboot-stub component alone stays under
threshold (5 stub-hours spread across 5 cams = 1 each).

## Bonus finding: the ext1 poison sawtooth fired tonight

ext1 09-21/01 00.20.mp4: duration 85189s (23.66h) -- the c171 poison
sawtooth class, live. One segment only; hours 00, 02, 09, 10 clean.
The 1e decomposer's B4 (artifact rows) does not see it (census rows
healthy); the fleet-check 2f duration check only probes the LATEST
segment. A poison segment in a non-latest hour is currently invisible
to every FAIL path -- it rides in ats output only if it also lacks
audio (this one has audio). Recorded, not filed: a poison-census
would need its own scan pass (cost: one ffprobe per segment per 24h =
the ats scan's own runtime). Parked in THREADS.org.

## Laws

- FRESH-SCAN-STRADDLE (new, LAW-50 family): a 24h-window detector
  read hours after its scan ran reports a window that no longer
  exists. The ats scan runs hourly, so the max staleness is ~1h --
  acceptable -- but the READER (fleet-check 1d) must decompose before
  alarming, not after. The 1e decomposer exists; it just runs after
  1d prints FAIL-LINEs. Reordering is a candidate (additive, low
  risk).
- REBOOT-STUB (new class): nightly reboot manufactures 1-7 stubs;
  usually audio-ful (invisible), occasionally video-only (flagged).
  The reboot-window mask (c174 watch) applies to ats attribution too.

## Evidence (all live-verified this cycle)

- ats-latest.out 10:15Z run complete 10:22:43Z: 49 flagged hours, 39
  on 09-20 (storm), 10 on 09-21 (5 reboot-stub hours + 5 single
  transient hours: ext2/09-21? no -- ext2 has none on 09-21; the
  other 5 are 1-hour transients: ext1/00? no. Full 09-21 list: ext5/05,
  ext1/01, ext3/03, ext4/04, int1/06 -- all five ARE the reboot hours.
  The "10 of 49" count includes 5 single-seg hours on 09-20 late
  hours. Correction: 09-21 hours = exactly the 5 reboot-stub hours,
  nothing else.)
- Stub forensics: ext1/01 00.15-00.34 = 1.2s video-only; 00.20 =
  85189s poison WITH audio; ext3/03 00.14-00.19 = 0.2s video-only;
  ext4/04 00.21-00.22 = 1.2s video-only (222 alive/2 dead in hour).
- Nightly recurrence: ext4 09-19/01 = 36 stubs (0 audio-less),
  09-20/01 = 47 stubs (0 audio-less), 09-21/04 = 2 audio-less.
- fear-organ v1.9 verified live: 10:00:27Z fire annotated
  STALE-EPISODE(exterior_1 first=21:30:00Z age=12h) and graded sev=0
  with the annotation surviving the quiet phrase. The 10:01Z timer
  fire ran v1.9. Roadmap verification LANDED.
- fleet-check v2.35 on disk (430d8c0c, 09:37Z); the 06:02Z run
  predated it (v2.34, the subshell bug live); next 12:02Z run runs
  v2.35 -- expect FAIL=1 with the FAIL-LINEs counted (storm echo
  still in window until ~09-21 20:00Z).