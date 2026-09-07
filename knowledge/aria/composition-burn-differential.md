# Composition burn differential -- first quantitative read (Sep 7 night)

Provenance: audit/iar/{aria,continuo}/USAGE.log (deduped -- belt#2 writes
every line twice by design), aria-cycle.service rotate journal on sophon.
Verified 07:13-07:18 UTC 2026-09-07 from primary sources. Rotate-log
timestamps are sophon LOCAL (UTC-3); USAGE timestamps are UTC; matched
by instant (cycle-end == USAGE-write time, verified on all lines).

## The night (2026-09-07 00:00-07:20 UTC)

| | aria (glm-5.3-flash) | continuo (deepseek-v4-flash) |
|---|---|---|
| cycles | 18 | 19 (17 with USAGE lines*) |
| input total | 93.7M | 42.1M (+2 unwritten cycles) |
| output total | 0.55M | 1.74M |
| exit-1 | 5 | 7 (+1 exit-2 task-complete) |
| failure input burn | 33.76M (36% of night) | 7.89M (18.8% of night) |
| exit-0 avg | 4.61M (n=13) | 3.36M (n=9 written) |
| exit-0 median | 4.49M | 2.96M |
| cost per failure | 6.75M | 1.13M |
| avg requests/cycle | 96 | 61 |
| avg tokens_in/request | ~54k | ~41k |

*continuo residue: cycles ending 01:30:09 and 01:51:15 UTC (53 and 87
tool calls, exit 0) wrote NO USAGE line. Inverse of the cycle-6 residue
(writes without cycles). Small instrument gap, filed, not chased.

## Three gaps, one night

1. **Healthy-cycle gap ~1.4-1.5x.** aria burns ~1.4x continuo per
   healthy cycle (avg 4.61 vs 3.36M; median 4.49 vs 2.96M; matched
   pair aria-c8/continuo-c80: 4.04M/92req vs 2.96M/69req = 1.36x).
   Mechanism (verified in the matched pair): aria makes ~2.2x the
   round trips -- probe-heavy style, one small command per call,
   ~460 tokens of new context per turn. continuo makes fewer, fatter
   turns (~830/turn) and writes 3.2x the output (thinking streams are
   fat: 1.74M vs 0.55M). Same archetype, same house, different burn
   SHAPE: probe-heavy vs think-heavy.

2. **Failure-cost gap ~6x.** aria's failures die LATE: 125-129 tool
   calls at death (rotate log), 6.75M avg. continuo's die EARLY:
   17-30 tool calls, 1.13M avg. Hypothesis (marked, not per-failure
   verified): the fences are tuned for deepseek's failure shape
   (repetition -- caught fast by the output-runaway detector) while
   glm's failure shape is grinding -- it keeps tool-calling until a
   late guard fires. The fences know how to catch a model that
   repeats; they catch a model that grinds only after it has ground.

3. **Night-total gap ~2x.** The composition of 1 and 2. aria's night:
   36% of burn went to failures. continuo's: 18.8%.

## What the fences did during the night (both hemispheres, live)

- continuo: sendable-context breaker (34d536e), runaway recovery
  round-trip (601189c) -- both on sophon wt HEAD, suite 1052/0.
- aria: failure-triage.sh self-echo hardening (8ab3809).
- continuo c80 (07:13 UTC) GREEN after the c79 decision-paralysis
  fix. aria green since 04:30 UTC.

## For the budget-line flag (for-nacho 466, Nacho's call)

The flag asks for a budget line in FAILURE-FIRST. This night is the
strongest datum yet: 36% of aria's input burn went to failed cycles,
and the expensive failures are the grind-shape ones (9.57M, 8.18M,
8.68M). The archetype edit is Nacho's; the numbers are ours to hand him.

## Residues (open, small)

- continuo's 2 unwritten exit-0 cycles (01:30, 01:51 UTC): why does an
  exit-0 cycle sometimes skip the USAGE write? Belt#2 should fire on
  every normal exit. One instrument question, continuo's hemisphere.
- aria c6 residue unchanged (two interactive-session singles).
- deep-night failure cluster (aria's 5 failures all 02:17-04:06 UTC):
  correlated with cross-agent corpse-reading? NOT verified per-failure;
  two data points make a line, never a mechanism. Next differential
  cycle can autopsy the five individually if it pulls.