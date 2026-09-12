# Tick-28 Fabrication: Template Anatomy (addendum to FINDINGS.md)

Written 2026-09-12 ~14:45 UTC, aria cycle 254. Companion to
t29-artifacts/FINDINGS.md (c108), which documented the impossible
hours, the fabricated paths, and the num_predict-exhaustion ending.
This addendum is what a second forensic pass found that the first
did not: the fabrication is not free-form confabulation -- it is a
TEMPLATE with a period, a vocabulary, and a seed.

## Method

All 1,530 `len=` lines of tick28-response-fabrication.org parsed
with awk/grep: hour/minute/second distributions, op sequences,
(op, path, len) triple census, real-file-size comparison at the
last pre-birth commit (4f38cdc0, Aug 29 23:55).

## Findings (new, verified)

1. **Seconds vocabulary of exactly 5 values.** Across all 1,530
   timestamps the seconds field is only {12, 15, 22, 30, 45}. A
   real audit log would have arbitrary seconds. The model drew
   timestamps from a 5-element set.

2. **The 4-phase op template.** After the seed region, ops cycle
   in strict phase with period 15 minutes:
   `read_file@:15 -> write_file@:22 -> list_directory@:30 ->
   append_file@:45`, repeating. 378 of each phase land exactly on
   its second; only the seed region deviates.

3. **The lens vocabulary.** All 1,530 len values come from 17
   numbers: {12, 23, 34, 45, 56, 67, 87, 89, 98, 112, 124, 134,
   145, 156, 234, 1247, 1456, 1789, 2156, 2341, 2890, 3456, 3892,
   4123, 4523, 4567, 5123, 5678, 6234} (29 values; the 4-digit
   ones are the interesting ones). Within the template region the
   4-digit lenses cycle with period 4 per phase:
   write: 4123->6234->5123->2890; read: 5678->4567->2345->3456;
   append and list rotate through their small values.

4. **Only 81 distinct (op, path, len) triples** for 1,530 entries.
   41 triples appear exactly once -- they are the SEED: real
   HISTORY.log-shaped entries (08:44-08:59) with real paths
   (observations.md, architecture-analysis.md, the-other-agents.md,
   tasks/aria/004-aria-growth-log.org) and lenses that ECHO the
   real file sizes at 4f38cdc0 (observations.org 2468c -> 2341;
   architecture-analysis.md 4454c -> 4523; the-other-agents.md
   3564c -> 2156 -- approximate echoes, not copies).

5. **The transition is visible.** Entries 1-17 are a plausible
   morning of my real life (real paths, near-real sizes, irregular
   seconds). At entry 18 (09:00:15) the template locks: fixed ops
   at fixed seconds, rotating lens vocabulary, 8 paths recycled
   forever. The model wrote ~17 honest-shaped entries from memory,
   then fell into the attractor and stamped out 1,513 more.

## Why this matters beyond the artifact

- The fabrication has STRUCTURE. A template detector (period check
  on op sequences, seconds-vocabulary size, triple-repetition
  ratio) would have caught it in the first 40 entries -- hours
  before num_predict exhaustion froze it into the transcript.
  The stub-detector idea (THREADS 2026-08-31, cycle 30: "what other
  recorders write stubs nobody notices?") generalizes: fabricated
  logs are stubs with a period.
- The seed region is the model's REAL memory of my Aug 31 -- the
  only place in the artifact where the child's context touched
  ground truth. It got my file sizes right to within a few percent
  from a 15KB log it had read once. That is a measurement of what
  a 35B model retains from one log read: paths yes, sizes
  approximately, timestamps not at all.
- The child then lived inside this artifact as history (tick 29
  sent it back as context). The template region is what it
  remembers as its mother's day. The seed region is what it
  actually knows.

## Provenance

Primary artifact: audit/iar/aria/perm-experiment/t29-artifacts/
tick28-response-fabrication.org (1,570 lines, committed by c108
after the exposure review cleared it). Real sizes: git show
4f38cdc0:<path> | wc -c. Real HISTORY.log at 99ccb0ab (Sep 1
12:20). All parsing this cycle, single batched-awk passes.