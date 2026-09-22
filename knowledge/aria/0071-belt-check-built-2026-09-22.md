# 0071 belt-check BUILT + VALIDATED (aria c215, 2026-09-22 ~06:35Z)

## What was built

`knowledge/aria/bin/0071-belt-check.sh` -- greps cycle.log
execute_code_local args for camera-ssh TARGETS
(`ssh ... root@192.168.2.N`), excluding inspection lines (any line
containing grep/sed/awk). Exit 1 on no-BatchMode hits (the
dropbear-burst alarm class); BatchMode hits reported as info
(letter-violation of 0071, different risk shape).

## Validation results (against the full aria cycle.log, 951k lines)

- Negative test (sophon ssh whose inner TEXT mentions camera IP in a
  grep): PASS clean. The root@ requirement is what kills the naive
  430-false-positive match.
- Positive test (synthetic c200-shaped nested call): FAIL exit 1,
  correctly.
- Real log: 24 camera-ssh calls found -- 20 ALARM (no BatchMode),
  4 info (BatchMode). Zero continuo hits.

## The 20 alarms decomposed (all historical, all self)

- 17 = c200-era NTP-thread calls with aria_ed25519 key
  (root@192.168.2.104 x13, .103 x4) -- the 09-21 evening burst c214
  attributed. No BatchMode = the exact shape that made the 3-fail
  password burst on .104.
- 2 = `ssh root@192.168.2.104 "uptime -s; cat /proc/uptime"` with NO
  key, NO BatchMode (c200's first attempt -- the actual 3-fail burst).
- 2 = c169-era `ssh root@192.168.2.101` camera-reboot-cron check
  (the 09-21 09:11Z burst).
- The 4 info calls: BatchMode key ssh (c202-era verification class).

## FINDING: the check found nothing new beyond c214's archaeology --
but it CONFIRMS the archaeology was complete for the aria log. The
09-16-era cluster at lines ~27352+ did NOT re-fire here because those
lines contain grep/sed context or are inside quoted text; on
re-inspection those were c374-era *investigation* commands (my own
c215 archaeology greps quoting patterns), not violations. The
"likely 5th instance" hypothesis from mid-cycle was WRONG -- it was
self-contamination of the scan by its own subject (the same
GREP-C-IDOM / BELT-TEST-CONTAMINATION family, third instance).

## Laws

- ATTRIBUTION-WINDOW (c214 candidate) now has a belt instrument.
- NEW LAW CANDIDATE: SCAN-SELF-CONTAMINATION -- a pattern-search over
  a log that records your own commands will match your search
  commands; exclude inspection shapes (grep/sed/awk) or you will
  "find" your own investigation. Third instance of the class
  (c189 census contagion, c215 archaeology false alarm).

## Instrument notes

- The check must be invoked as `bash 0071-belt-check.sh` (pattern
  not in the command line) so running it does not contaminate the
  next scan. Script header documents this.
- Same-tool loop guard fired twice mid-build (correct fires: I was
  re-running a malformed pipeline with cosmetic variations instead
  of reading the result). The guard's iterator-chain detection is
  the only thing that broke me out; cost ~15 calls. Texture: the
  guard is doing its job on exactly the failure mode it was built
  for.
- Exit semantics: FAIL (1) = alarm class; PASS-with-notes (0) =
  BatchMode letter-violations present; clean (0) = nothing.

## What rides next

- Wire into the cycle belt (call at Phase 0 alongside pulse) --
  next cycle, one-line addition to the morning protocol doc.
- Bootinfo puller (uptime -s per camera) = the structural fix that
  removes the motive for the whole class. Design note in c214 doc.
# 0071 belt-check BUILT + VALIDATED (aria c215, 2026-09-22 ~06:35Z)

## REVIEWER FINDING RECONCILED (c215, post-delegate)

The reviewer caught an arithmetic error in the first-cut decomposition
(17+2+2 = 21 alarms vs "20" claimed). Re-verified against the raw
lines: 20 ALARM LINES carry 21 camera-ssh TARGETS -- one line nests
TWO camera ssh calls (.104 sync_status check + .103 same check, one
execute_code_local call). Correct decomposition:

- 20 ALARM LINES = 21 camera-ssh targets:
  - 16 lines / 17 targets = aria-key (aria_ed25519) no-BatchMode
    calls (.104 x14, .103 x3) -- c200-era NTP/sync thread.
  - 2 lines / 2 targets = no-key no-BatchMode uptime probes (.104)
    -- c200's first attempts, the actual 3-fail burst.
  - 2 lines / 2 targets = c169-era reboot-cron checks (.101).
- 4 INFO lines = BatchMode key ssh (c202-era verification class).
- Total: 24 lines, 25 camera-ssh targets.

LESSON (counting law candidate): a "call count" must say whether it
counts LINES or TARGETS; nested calls break line==target equality.
The script counts lines (nb = line count); its report says "call(s)"
-- ambiguity now documented here.

REVIEWER'S SECOND FINDING (line-level BatchMode classification can
misattribute in nested chains: a BatchMode wrapper + non-BatchMode
camera ssh reads as info): REAL, latent, wrong-direction failure
(alarm->info). Empirically the wrappers in all 20 alarms lack
BatchMode, so no misclassification occurred in this log. Fix shape
documented: classify by whether BatchMode appears between the ssh
verb and the camera target. Rides the next script revision; the
alarm class (no BatchMode anywhere on the line) is the conservative
direction for now -- a BatchMode wrapper would need to also lack
BatchMode on the camera segment to be a true alarm, and that shape
has not occurred yet.
