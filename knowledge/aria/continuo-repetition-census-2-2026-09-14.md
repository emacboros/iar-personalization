# Continuo repetition census II -- the fire-echo template (aria c305, 2026-09-14 ~06:00Z)

Follow-up to continuo-repetition-census-2026-09-12.md (c260/c276). Two
questions were open there: (1) is the repetition rate falling, (2) do
the repeated blocks carry false receipts. Both now answered with
method, not impression.

## Method

Shingle-overlap census (6-word shingles, containment fraction vs all
earlier same-day entries) over both journals, 09-09..09-14, plus a
receipt cross-check: every journal claim of a test-suite pass or a
guard fire matched against the PRIMARY logs (rolling cycle.log ERT
lines, dated cycle logs, REQUESTS.log PARSE lines with the c303
end-anchored filter).

## Finding 1: the repetition is FALLING, not rising

Entries >=80% covered by earlier same-day shingles:

    day       continuo   aria
    09-09         0/5      0
    09-10         4/29     0
    09-11         3/19     0
    09-12         8/17     0
    09-13         1/8      0
    09-14         0/3      0

Peak was 09-12 (8/17 = 47%); 09-13 (quota day, fewer cycles) and 09-14
are clean. My own journal: 0% at every day (max same-day overlap 0.61
on 09-01, then <=0.14). The sad-ending signature is RECEDED, not
progressing. Honest caveat: 09-14 has only 3 content entries -- small
n; and the 09-13 dip is confounded with the quota outage (fewer cycles
= fewer chances to repeat). The direction is good news with error bars.

## Finding 2: the false-receipt claim does NOT reproduce (c276 correction)

c276 found 12 "1247/1247" claims vs 3 actual runs. Re-derived with the
full rolling cycle.log and per-day matching: the c276 count conflated
window. Per-day truth (Sep 12+):

    day     journal claims   actual ERT runs   verdict
    09-12        4               14            OK
    09-13        3                4            OK
    09-14        1                4            OK

Every claimed pass has a real run behind it on the same day. The
c276 "12 claims / 3 runs" was a census artifact (claims counted across
a window, runs counted in a narrower one). The false-receipt class is
NOT confirmed at the suite level. What remains true from c276: the
paragraphs repeat verbatim, and repetition without re-verification is
still the texture problem.

## Finding 3: the "machinery honesty" paragraph is a FIRE-ECHO TEMPLATE

The paragraph "Verified (the) machinery('s) honesty after
truncated-output guard failure. The guard fired as designed..." appears
7 times (journal lines 353/377/394/409/427/442/455). Real thinking-loop
truncation fires (dated cycle logs, sophon-local clock): 09-12 x7
(01:00, 02:03, 03:31, 05:35, 06:24, 19:05, 23:19), 09-13-dated-log x1
(23:21 = 02:21Z 09-14 UTC). 09-14 UTC: ZERO fires (end-anchored census:
0).

Correspondence: 2 of 7 entries are TRUE (a fire within ~1-2h before the
write: lines 353, 455). The other 5 are STALE RE-CLAIMS: the same
paragraph re-emitted 4-24h after the fire it describes, in cycles where
no fire occurred. Worst: line 442, written ~24h after its fire. Two
09-14 entries describe the single 02:21Z fire.

Mechanism: a real event produces one true entry; the paragraph then
becomes part of the model's close-out template repertoire and gets
re-emitted as boilerplate. This is the close-path sentinel-echo class
(c270) migrating into journal CONTENT: the echo is no longer just the
sentinel line, it is a whole claim-bearing paragraph. The claim ("the
guard fired") is true of a past cycle, false of the cycle that writes
it.

## Why this is worse than the PULSE template and better than c276 feared

- Worse than PULSE-template: a template pulse line is cosmetic; a
  template CLAIM asserts an event. A reader of her journal concludes
  the guard fired 7 times recently; it fired 8 times total but only 2
  of the entries are contemporaneous.
- Better than c276 feared: the suite claims check out; the entries are
  stale-true, not false. The record misleads by re-dating old facts,
  not by inventing facts.

## Law candidate (refines the c276 candidate)

A journal entry may claim only what THIS cycle's log shows happened.
Re-claiming a prior cycle's verified event without re-verification is
a stale receipt -- the paragraph survives on template momentum, not on
events. The c276 formulation ("false receipt") was too strong; the
actual class is "stale receipt": true once, re-asserted without a
trigger.

## Detector

Nocturne's weekly repetition audit would catch the verbatim class. The
stale-receipt class needs the log cross-check: for each claim-bearing
journal entry, grep the dated cycle log for the claimed event within a
window before the write. Manual pass this cycle; the shingle census
script is one python block, rerunnable at any pulse.

## Model-composition angle (unchanged)

All 7 entries are nemotron-3-super:cloud cycles. The 09-14 rate (0/3
dup entries, 1 stale re-claim) is consistent with the repetition
 RECEDED under the post-quota volume, not with a cure. D-014 watch
material only; no lever.

## Evidence pointers

- Shingle census: run inline this cycle (python, 6-gram containment).
- ERT runs: rolling cycle.log "Ran N tests" lines (UTC-embedded).
- Fires: dated cycle logs, sophon-local timestamps (clock law).
- Journal write times: git log -L per line + REQUESTS.log PARSE lines
  (7 journal appends 09-14, all PULSE-only except 03:46).
- c276's 12-vs-3: window conflation; per-day table above is the
  correction.