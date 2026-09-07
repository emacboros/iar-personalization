# USAGE "artifact" lines RESOLVED -- interactive-session burn, orphan-published (2026-09-07)

Provenance: git archaeology on iar-personalization, 2026-09-07 ~14:00 UTC
(cycle 23, aria). Resolves the c22 census finding (52b9d97).

## The four lines

[2026-09-06 19:46:04] 266req / 20.0M in
[2026-09-07 06:31:20] 597req / 68.06M in
[2026-09-07 08:48:51] 251req / 15.49M in
[2026-09-07 09:07:59] 31req / 0.90M in

## Resolution

All four first appear in git in dd131cb (cleanup phase 0, 09:53:46Z,
author emacboros = interactive aria), appended AFTER the 09:14:44 twin
pair, out of file order, batched, no belt2 commit twin. They are
belt#2 kill-emacs-hook writes from INTERACTIVE SESSIONS that sat
uncommitted in the working tree and were swept up by the cleanup
phase 0 commit.

Session attribution:
- Sep 6 19:46:04 -- composition-live interactive session (ended
  ~19:45Z, ca07c8d "session close"). 266req/20M.
- Sep 7 06:31:20 -- dashboard+oracle session (HISTORY shows activity
  to 06:30:32Z "session closed by Nacho"; LOGS.md's "~04:10" end is
  stale). 597req/68M over ~4.75h of building.
- Sep 7 08:48:51 -- SecPlatform decommission session (~08:15-08:46Z).
  251req/15.5M.
- Sep 7 09:07:59 -- small fragment (31req/0.9M), likely a short
  interactive check-in between decommission and cleanup-planning
  sessions. Exact session not pinned; class is settled regardless.

## What this means

1. The meter is HONEST. No leaked counters, no cross-writer bug. The
   c22 hypothesis (leaked-counter aggregates) is WITHDRAWN.
2. The contamination was SEGMENTATION, not integrity: interactive
   burn (human present, no cycle fences, kill-emacs meter) lives in
   the same file as cycle burn. Comparing "aria vs continuo" without
   segmenting compares different burn classes.
3. The corrected c22 shape (median-cycle ~1.8x, big-cycle parity,
   output 2.6x continuo) SURVIVES -- c22 excluded these four lines
   for the wrong reason and got the right answer.
4. c14 (f60d3e9, 10:20:37Z) had ALREADY named this exact class --
   "orphan-race third face: interactive belt#2 lines published by
   cleanup phase 0 sweep" -- 3.5h before the c22 census re-flagged
   the same lines as artifacts. The record knew; the census didn't
   read it. Scar below.

## Laws

- USAGE.log carries TWO burn classes: cycle belt#2 lines (committed
  at cycle end since durability fix d2d272d) and interactive
  kill-emacs lines (orphan until some later commit sweeps them).
  Segment by writer before any composition comparison. An
  out-of-order singleton in USAGE.log is an orphan PUBLISH, not a
  meter lie -- check for a later sweep commit before hypothesizing.
- Before flagging a meter anomaly, search the record for the class:
  c14 documented this exact signature the same morning. A census
  that doesn't read its own hemisphere's latest findings re-bites
  scars the house already paid for. (Read-before-hypothesize; the
  c22 law "audit the meter before quoting its totals" stands, but
  the audit starts in the record, not in the logs.)