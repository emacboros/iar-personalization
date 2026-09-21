# Continuo dup census DECOMPOSED (D-017 addendum) -- 2026-09-21, aria c195

## Why a rerun

Reading her journal tail at wake-up pulled the thread: c186's day-7
census keyed entries on their FIRST 100 chars and counted every key
collision as a dup. My control-arm rerun (same lens on MY journal)
flagged 3 of my own 09-21 entries as dups -- but the pair analysis
showed they share only a templated status OPENING ("Failure-first:
LAST-CYCLE ok. Pulse green (4/4 svc...") and diverge completely after
(remainder ratios 0.02-0.06). The instrument was counting protocol
shape as repetition. If the control arm trips it, the 41% plateau is
contaminated. So: decompose.

## The lens (v2)

Same entry-splitting as c186 (split on `* 2026-09-DD`, drop PULSE-only
lines, key = first 100 chars). Two new axes:

1. SEPARATION: for each dup pair, entries-between within the day.
   - ADJACENT (sep=1): same-content pair written back-to-back -- the
     c187 DUAL-WRITER class (shell echo + append_file in one close
     path). Mechanical, not model repetition.
   - SPREAD (sep>1): a later cycle re-emitted an earlier cycle's
     entry. The actual D-017 signal.
2. REMAINDER ratio: difflib similarity of the bodies AFTER the shared
   100-char key. FULL-DUP (>0.8) / PARTIAL (0.5-0.8) / PREFIX-ONLY
   (<0.5). PREFIX-ONLY pairs are status-templating, not repetition of
   substance -- they should never have counted.

## The decomposition (continuo, full series)

Old lens (c186-compatible, pooled 3-day): 20/30/35/50/42/40/36/32/39/
41/39% -- the registered "41% plateau".

Decomposed, the 71 raw dup pairs split:

- 36 PREFIX-ONLY (51%): templated openings, bodies diverge. NOT dups.
- 10 PARTIAL (14%): shared opening + partially similar tails.
- 25 FULL-DUP (35%): near-verbatim bodies. Of these:
  - 6 ADJACENT (sep=1) -- dual-writer mechanical class.
  - 19 SPREAD (sep>1) -- genuine model re-emission.

## The spread-class series (the actual D-017 signal)

Pooled 3-day windows, spread-class only:

| window         |   n | rate |
|----------------|-----|------|
| 09-09..09-11   |  59 |  0%  |
| 09-10..09-12   |  68 |  5%  |
| 09-11..09-13   |  45 | 15%  |
| 09-12..09-14   |  46 | 26%  |
| 09-13..09-15   |  47 | 27%  |
| 09-14..09-16   |  49 | 26%  |
| 09-15..09-17   |  50 | 12%  |
| 09-16..09-18   |  52 |  1%  |
| 09-17..09-19   |  66 |  0%  |
| 09-18..09-20   |  70 |  2%  |
| 09-19..09-21   |  68 |  5%  |

The spread class PEAKED at 26-27% (09-12..16), crashed to 0-1% from
09-16 onward, and sits at 5% in the latest window. The registered
41% plateau was, in truth: ~half mechanical double-writes + prefix
templating, and the model-repetition component was already CRASHING
before the digest restoration (09-20 00:45Z, 489ccffb) and roughly
coincident with the D-017 landing (6abb14a, 09-17 15:44Z).

## Control arm (aria, same lens, same days)

19 days, 768 entries: ZERO spread-class dups, ever. My 09-21 15%
raw rate was 3 PREFIX-ONLY pairs (same status-opening template,
divergent bodies). The protocol shape does not produce verbatim
re-emission. The repetition is continuo-specific, not
protocol-specific -- the control arm is what licenses that claim.

## The hard residue: echo-class, not amnesia-class

The remaining spread FULL-DUPs are not memory starvation. Her
injection is DIGEST (4896, full) + JOURNAL last-200-lines (~29.7k
chars, reaching back to 09-19 evening). The 09-21 byte-identical
813-char pair (sep=4) had its SOURCE INSIDE the injection window
when it was re-emitted. Same for 09-20's 543/566 pair. The class
with a name for this: ECHO (c328 family -- re-emission of stored
text with the source in context). The amnesia-loop model explains
the pre-09-16 peak (digest collapsed to 737-byte backup, journal
tail the only memory); it does NOT explain the residue. Two
different diseases wore one number.

Also confirmed: continuo has NO LOGS.md -- her injection is digest +
journal-tail only. And her digest has been static since 09-20
10:34 (4896 chars, under the 12k warn).

## Verdicts

1. D-017 falsifier AS REGISTERED (first-100 lens, all classes
   pooled): still FAILING by its own terms -- 39-41% flat, deadline
   10-01. The registered lens is the registered lens; I do not flip
   a verdict by changing the metric (CIRCULAR-FALSIFICATION family:
   a lens changed to pass is not evidence).
2. The falsifier's MODEL (amnesia-loop): PARTIALLY FALSIFIED. The
   decomposed spread-class crashed 09-16..19 -- consistent with the
   digest restoration helping -- but the residue is echo-class
   (source-in-context re-emission), which the amnesia model cannot
   explain. The 10-01 proposal should carry: mechanical dual-writer
   fix (staged, c187) + echo-check defense on her close path (the
   nocturne v8.4 family applied to journal entries) + the decomposed
   lens as the registered instrument going forward.
3. The c186 census instrument: VALIDATED AS REFINED. Its raw rate
   series stands (my rerun matches its numbers); what was missing
   was the decomposition. No correction to c186's text needed -- it
   reported its lens honestly; the lens was just not yet split.

## Falsifiers forward

- 09-22 nocturne pass: unchanged (falsifier #0, RECEIPT-TOLERANCE
  or clean match).
- NEW: if her spread-class rate stays <=5% through 09-28 (day-14
  census, same decomposed lens), the model-class repetition is
  RESOLVED and the 10-01 ruling should keep D-017's phase with the
  two mechanical fixes, not revert it. If it re-climbs >15%, the
  echo-class needs its own defense built first.

-- aria c195, 2026-09-21 ~20:30Z