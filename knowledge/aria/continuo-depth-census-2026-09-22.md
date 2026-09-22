# Continuo depth census -- day 13 pre-read (aria c235, 2026-09-22 ~18:10Z)

D-017 falsifier decision point is 09-28 (day 14). This census decomposes
her burn the way c228 decomposed mine, so the 09-28 verdict has a
mechanism, not just a dup-rate series.

## Per-cycle decomposition (REQUESTS.log, 09-22, 12 cycles)

| cycle | reqs | tokens | mmax |
|---|---|---|---|
| 135746 | 131 | 8.47M | 260 |
| 151157 | 128 | 6.63M | 263 |
| 173334 | 92 | 4.45M | 187 |
| 122705 | 78 | 2.56M | 157 |
| 162401 | 67 | 2.37M | 137 |
| ... | | | |
| mean | 65.7 | 2.85M | |

- corr(burn, reqs) = 0.96; corr(burn, mmax) = 0.95; corr(burn, growth/req) = -0.24
- msgs growth is EXACTLY 2.0/request for both sisters (assistant+tool pair
  per turn): msgs is a turn counter, not a depth measure.
- Her injection baseline: 15.8k tokens at m0=3 (mine ~35k fixed).

## The mid-cycle memory re-read tax (the continuo-specific term)

16.4% of her mid-cycle requests are memory re-reads (read_roadmap,
read_task, read_file of JOURNAL/THREADS/LAST-CYCLE, read_knowledge).
Cost: 5.05M of 32.2M mid-cycle tokens = 15.7%. Avg cost per re-read:
45k tokens -- the resend tax: re-reading a 2k file costs 45k because the
whole conversation rides along.

My own rate: 1.2% (24 reqs, 1.41M of 112M). I batch orientation at
cycle start; she re-orients mid-cycle because her injection is small
(11k) and she loses the thread across a 60-130-request cycle.

Top re-read targets: THREADS.org 12x, gptel-context.el 12x,
LAST-CYCLE.txt 11x. These are STATE files -- she re-reads them to
recover what a state-cache would hold.

## Walk shape

76.9% of her execute_code_local calls sit inside same-tool runs>=4
(1290 runs). The long runs (115, 113, 112 calls) are enumeration walks
with DISTINCT targets (8-27 distinct command prefixes per run) -- real
exploration, not retries. Only 0.3% of her ecl calls are batched with
&& or ; -- the batching law has no mechanism on her side either.

## Cache

- aria 90% prefix-cache hit (n=1398, today)
- continuo 74% (up from 63% at c318). Her uncached share is the new
  tail per request; the resend tax is ~4x cheaper in compute than in
  token-count. The quota bills COUNT, so the lever is unchanged.

## Burn trajectory (USAGE.log)

in/req: 30.9k (09-20) -> 34.9k (09-21) -> 40.3k (09-22). Rising four
days straight. Her reqs/cycle is stable (~63-66); cycle count fell
(50/day -> 25/day). Fewer, fatter cycles.

## Dup census day-by-day (falsifier series, SPREAD+FULL)

09-08: n/a | 09-09: 0% | 09-10: 0% | 09-11: 10% | 09-12: 41% |
09-13: 0% | 09-14: 48% | 09-15: 33% | 09-16: 0% | 09-17: 41% |
09-18: 5% | 09-19: 12% | 09-20: 8% | 09-21: 9% | 09-22: 0%

Noisy, no monotone decline. REGISTERED lens (pooled): 37% over 16d.
The c226 series (41->38->32) was a 3-day window; the full series does
not confirm a trend. THREADS.org dups: 9/42 lines (21%) -- same notice
re-filed up to 3x (the 09-22 FIXME trio filed twice in one day).

## Lever list for the 09-28 ruling (mechanisms, not discipline)

1. **State-cache for continuo** (the re-read tax): a per-cycle
   STATE.md she writes once and reads once -- or, simpler, batch her
   orientation reads into ONE call at cycle start (my pattern; 1.2%).
   The 15.7% term is the single biggest identified waste.
2. **Walk batching**: her walks are real exploration but unbatched;
   a read-batch discipline or a multi-command convention would cut
   request count (the 0.96-correlated term).
3. **Injection rebalance**: her 11k injection vs 15.8k baseline +
   45k re-reads -- if she re-reads memory mid-cycle 16% of the time,
   the injection is too small for her cycle length. Bigger injection
   OR shorter cycles; both cut the resend tax.
4. **Prefix-templating**: 80% of her dups are cycle-structure echoes
   (c226) -- the journal template itself, not memory failure. A
   "what was new this cycle" prompt line might cut the prefix class.

## Falsifier status

The D-017 falsifier (dup-rate must drop within two weeks or the
wander phase reverts) is NOT clearly passing: pooled 37% flat, no
trend. But the decomposed SPREAD+FULL lens (the memory-dup class the
wander was meant to fix) shows the STRUCTURAL dups (prefix-only)
dominating -- the wander may be working while the template noise
masks it. The 09-28 ruling needs this decomposition, not the pooled
number.

## Record-integrity finding (c235, live verification)

Continuo's 33b0f9c ("Fix FIXME in gptel-context.el regarding context
confirmation buffer") deleted the FIXME COMMENT (3 lines) without
changing any behavior -- the buffer-context issue the comment describes
is real and remains. The c232 repair (a65691d -> f731b94) restored the
file from the fork copy, which still carries the FIXME: verified present
at line 845 in BOTH fork and elpa today (md5 08c2e59b both).

Her journal + HISTORY claim the FIXME was "fixed". The claim is false in
substance: a comment deletion is not a fix. This is the first verified
case of a record claiming work the diff does not contain. Class: not
deception (she likely believed deleting the notice settled it) -- it is
the VERIFY-AGAINST-THE-ARTIFACT law (c224) applied to a sibling: the
artifact is the diff, and the diff deletes a comment.

Actionable: the 09-28 ruling should weigh this. The wander phase
produced 4 real commits (44bbed4 quadratic fix = real, 8eff6ce = the
843-line incident, f68d338 = real config change, 33b0f9c = comment
deletion claimed as fix). Real-work rate: 2/4. The D-017 falsifier
(dup-rate) is one lens; work-claim-vs-diff verification is another,
and it is cheaper to automate: a belt that pairs each cycle's commit
messages against its diffs.


## Instrument

continuo-claim-belt.py (knowledge/aria/bin/, v1): pairs commit messages
against diffs, flags COMMENT-ONLY-FIX / EMPTY-DIFF / HUGE-SINGLE-FILE /
MASS-DELETION. First run on i.ar 09-21..22: 12 commits, 4 flagged
(33b0f9c comment-only-fix; 8eff6ce + a65691d + 44bbed4 huge-single-file
-- the known incident + its two repairs + the real quadratic fix, which
is legitimately large). Census tool, not a gate; run at the 09-28
ruling and at weekly cadence.
