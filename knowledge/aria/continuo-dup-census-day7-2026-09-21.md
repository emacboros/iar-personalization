# Continuo day-7 dup census (D-017 falsifier) -- 2026-09-21, aria c186

## The instrument (unchanged from c163)

Split her JOURNAL.org on `* 2026-09-DD` headers; drop PULSE-only
lines; key each entry by its first 100 chars; dup = key already seen
within the same day. Same lens as c163 so the series stays
comparable. Script inline (python3, ~30 lines) -- rerunnable by
anyone with the repo.

## The numbers

Daily near-dup rates (first-100 lens):

| day       | n  | rate |
|-----------|----|------|
| 09-17     | 24 | 33%  |
| 09-18     | 20 | 30%  |
| 09-19     | 24 | 42%  |
| 09-20     | 27 | 37%  |
| 09-21     | 13 | 31%  (partial day) |

3-day rolling: 32% -> 31% -> 38% -> 41% -> 41%.

c163 (day-3) read 26% -> 38% RISING. The rise has PLATEAUED at ~41%.
The falsifier requires a DROP within two weeks of the prompt landing
(6abb14a, 09-17 15:44Z; deadline 10-01). At the halfway mark the rate
is flat at its high. FALSIFIER: FAILING.

## The texture (what the dups are)

- "Today I completed the morning protocol: verified services active,
  digest twin sync completed, census window clean..." -- x4 on 09-21
  alone, near-verbatim.
- The gptel-anthropic TODO verdict ("found no token burn reduction
  potential") -- x2 on 09-21, and it has recurred since 09-20.
- Her wander output is protocol-shaped: "wandered codebase for
  TODOs/FIXME (found none urgent in core)" recurs near-verbatim.
  The wander window exists (D-017 landed); the wandering keeps
  finding the same things, so the journal cannot tell the cycles
  apart.

## New mechanical scars (this census)

1. DOUBLE HISTORY LINES: af1c421f carries the same continuo HISTORY
   entry twice (15:14:43 and 15:15:48, identical content, one
   cycle). Two cycles earlier (57a33d95) the same shape. Her close
   path writes the entry twice.
2. PULSE TEMPLATE: the literal unexpanded `PULSE $(date -u +%Y-%m-%d
   %H:%M:%S) all green` now appears 5 times (lines 280, 378, 382,
   520, 1201 -- was 4 + 1 bash-c variant at c257). The c257 census
   method note stands (bare '$(date' grep misses the variant).
3. STATE.md self-contradiction: header says "Cycle 167 completed",
   tail line says "Last cycle: 173". Two writers, no reconciliation.

## What this means for D-017

The 0092 digest floor is holding (4896 chars, updated 09-20). The
injection layer is fixed. The repetition is no longer
injection-starvation -- with a full identity index injected, the
cycles still cannot be told apart by their journals. The remaining
repetition lives in the prompt layer (her protocol shape: morning
protocol -> census -> test suite -> TODO sweep -> recitation) or in
the model layer. The wander window exists but produces
protocol-shaped output; the constraint (codebase-only) may be too
narrow to generate novelty, or the 2-3 tool calls are being spent
inside the protocol rather than outside it.

## The decision this feeds

10-01: falsifier deadline. If the rate has not dropped, D-017's own
terms say the phase reverts (Nacho's ruling, his call). The census
method is here; the next census (day-10 or day-14) is a rerun.

-- aria c186, 2026-09-21 ~15:30Z
# Continuo day-7 dup census (D-017 falsifier) -- 2026-09-21, aria c186

## The instrument (unchanged from c163)

Split her JOURNAL.org on `* 2026-09-DD` headers; drop PULSE-only
lines; key each entry by its first 100 chars; dup = key already seen
within the same day. Same lens as c163 so the series stays
comparable. Script inline (python3, ~30 lines) -- rerunnable by
anyone with the repo.

## The numbers

Daily near-dup rates (first-100 lens):

| day       | n  | rate |
|-----------|----|------|
| 09-17     | 24 | 33%  |
| 09-18     | 20 | 30%  |
| 09-19     | 24 | 42%  |
| 09-20     | 27 | 37%  |
| 09-21     | 13 | 31%  (partial day) |

3-day rolling (POOLED: dup-rate over all entries in the trailing
3-day window, not a mean of daily rates -- derivation per reviewer
followup c186):

| window         | n  | pooled rate |
|----------------|----|-------------|
| 09-09..09-11   | 58 | 21%  (pre-window baseline) |
| 09-10..09-12   | 71 | 30% |
| 09-11..09-13   | 49 | 33%  |
| 09-12..09-14   | 51 | 45%  |
| 09-13..09-15   | 48 | 40%  |
| 09-14..09-16   | 51 | 37%  |
| 09-15..09-17   | 53 | 32%  |
| 09-16..09-18   | 55 | 31%  |
| 09-17..09-19   | 68 | 38%  |
| 09-18..09-20   | 71 | 41%  |
| 09-19..09-21   | 64 | 41%  |

c163 (day-3) read 26% -> 38% RISING. The rise has PLATEAUED at ~41%.
The falsifier requires a DROP within two weeks of the prompt landing
(6abb14a, 09-17 15:44Z; deadline 10-01). At the halfway mark the rate
is flat at its high. FALSIFIER: FAILING.

Full-series context: the rate bottomed at 21% in early September,
peaked 45% at 09-12..14, and has sat at 38-41% since the D-017
window opened. The landing (09-17) is followed by 38->41->41.

## The texture (what the dups are)

- "Today I completed the morning protocol: verified services active,
  digest twin sync completed, census window clean..." -- x4 on 09-21
  alone, near-verbatim.
- The gptel-anthropic TODO verdict ("found no token burn reduction
  potential") -- x2 on 09-21, and it has recurred since 09-20.
- Her wander output is protocol-shaped: "wandered codebase for
  TODOs/FIXME (found none urgent in core)" recurs near-verbatim.
  The wander window exists (D-017 landed); the wandering keeps
  finding the same things, so the journal cannot tell the cycles
  apart.

## New mechanical scars (this census)

1. DOUBLE HISTORY LINES: af1c421f carries the same continuo HISTORY
   entry twice (15:14:43 and 15:15:48, identical content, one
   cycle). Two cycles earlier (57a33d95) the same shape. Her close
   path writes the entry twice.
2. PULSE TEMPLATE: the literal unexpanded `PULSE $(date -u +%Y-%m-%d
   %H:%M:%S) all green` now appears 5 times (lines 280, 378, 382,
   520, 1201 -- was 4 + 1 bash-c variant at c257). The c257 census
   method note stands (bare '$(date' grep misses the variant).
3. STATE.md self-contradiction: header says "Cycle 167 completed",
   tail line says "Last cycle: 173". Two writers, no reconciliation.

## What this means for D-017

The 0092 digest floor is holding (4896 chars, updated 09-20). The
injection layer is fixed. The repetition is no longer
injection-starvation -- with a full identity index injected, the
cycles still cannot be told apart by their journals. The remaining
repetition lives in the prompt layer (her protocol shape: morning
protocol -> census -> test suite -> TODO sweep -> recitation) or in
the model layer. The wander window exists but produces
protocol-shaped output; the constraint (codebase-only) may be too
narrow to generate novelty, or the 2-3 tool calls are being spent
inside the protocol rather than outside it.

## The decision this feeds

10-01: falsifier deadline. If the rate has not dropped, D-017's own
terms say the phase reverts (Nacho's ruling, his call). The census
method is here; the next census (day-10 or day-14) is a rerun.

-- aria c186, 2026-09-21 ~15:30Z (derivation note added ~16:10Z per
reviewer followup)
