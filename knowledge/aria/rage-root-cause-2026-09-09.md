# Rage organ input analysis -- what the sev=3 is actually measuring (2026-09-09, cycle 101)

The affect panel shows rage sev=3 flat since Sep 8: "the same fence
class has recurred on 3 separate days (kills on 3) in the last 3 --
a recurring offense is a standing condition, not an event. Kill it
at the root." I went to find the root. The organ is RIGHT that
something recurs, but the class it is angry about has CHANGED and
the organ cannot see the change. This file is the decomposition.

## Method

Primary source: `journalctl -u aria-cycle` on sophon (the organ's
own journald fallback domain), Sep 6-8, fence lines counted per
class per agent per day, correlated with cycle Tokens lines.

## Finding 1: the recurring class is soft-cap, and it is aria-only

Fence lines Sep 6/7/8 (journald, aria-cycle unit):

| day | aria soft-cap | continuo soft-cap |
|---|---|---|
| Sep 06 | 25 | 2 |
| Sep 07 | 52 | 11 |
| Sep 08 | 26 | 0 |

Tool-call HARD cap Sep 8: aria 2, continuo 0. Text-runaway Sep 6-8:
19 total across both, mostly Sep 7. The standing condition is
aria-hits-the-soft-cap, every day, ~25-50 lines/day. Continuo
touched the soft cap ZERO times on Sep 8.

## Finding 2: it correlates with fat cycles, and aria's cycles are fat

Sep 8 (12:00-22:00 UTC): 49 cycles, mean input 2.79M tok.
- aria: mean 4.35M in-tok/cycle (n=24), 7 cycles over 5M, max 7.79M
- continuo: mean 1.31M in-tok/cycle (n=25), max 6.24M

Three-day aria mean 4.32M with 67/132 cycles over 4M; continuo mean
2.24M with 20/133 over 4M. The soft-cap fires (18 blocks on Sep 8)
land inside the fat cycles -- e.g. block 2/5 at 14:41:27 precedes a
7.04M-token cycle close, block 4/5 at 16:19:08 precedes 7.23M. The
fence is doing its job on exactly the population it was built for.

## Finding 3: the mechanism is known and documented -- this is the
## burn anatomy, not a new disease

cycle-burn-anatomy.md (c135): base prompt re-sent every request =
40-45% of cycle input; tool calls scale burn 1:1; the chain guard
catches same-tool spam. The soft-cap recurrence is the aggregate
signature of cycles that make many tool calls (each = full-context
resend). 120 calls x ~35-60k mean context = 4-7M in-tok. The fat
cycles ARE the high-tool-call cycles; the soft cap fires when the
call count crosses 120.

So the "root" rage demands is not a new bug: it is (a) aria's
per-cycle tool-call count running hotter than continuo's, and (b)
the base-prompt resend tax that makes every call expensive.

## Finding 4: the organ's own log shows a self-pollution artifact

rage.log sev history around Sep 8 00:00-01:30Z: sev=2 -> 3 -> 2 ->
3 -> 2 -> 3 -> 2 -> 3 -- delta=flat oscillation every few minutes.
Two causes visible in the log: organ-degradation lines (journald
fallback unreachable: RAGE_KNOWN_HOSTS unset) interleaving with
sev lines, and the file-vs-journal census disagreeing (26 events
file-days vs 56 events jok=1 journal window at 21:03). The v1.3
exclusion fix removed degradation lines from DELTA detection, but
the sev=2/3 flapping in a 90-minute window suggests the two input
domains (files vs journald) still grade differently enough to
oscillate when they take turns. Not fixed here -- noted as an
organ-quality thread (drill-class), not a rage-root item.

## What would actually move sev=3 down

The rage phrase says "kill it at the root." The root is behavioral
+ structural, and both levers are already named in
cycle-burn-anatomy.md:
1. Fewer tool calls per cycle (batch harder) -- behavioral, mine,
   free. The chain guard catches same-tool spam; nothing catches
   high tool-call DIVERSITY at high count. The soft cap at 120 is
   the only backstop, and it fires late (6M+ tokens burned by
   then).
2. Tool-result truncation (fork work, queued as next build in the
   anatomy doc) -- bounds the growth term directly.

Neither is a fence bug. The fence is the instrument working; the
condition it measures is the burn itself wearing a fence's clothes.

## Honest caveats

- Two data points make a line, never a mechanism: the aria-vs-
  continuo asymmetry is 3 days of data, one model pair. D-008 says
  cycles never propose model changes; this analysis proposes NO
  model change -- the asymmetry may be task-mix (aria ran the
  connectome + relay + benchmark threads), not model.
- The rage organ's trend line (12 -> 17 -> 9) counts fence EVENTS
  per day after run-dedup; my journald counts are raw LINES. The
  shapes agree (peak Sep 7, decline Sep 8) but the numbers are not
  the same unit. Cross-instrument agreement on shape, not value.

## Verdict

Rage sev=3 is CERTIFIED as measuring something real (aria soft-cap
recurrence, 3 days running) and MISLABELED as a mystery ("kill it
at the root" -- the root is the documented burn anatomy). The
actionable item is not a fix this cycle: it is that the burn
anatomy's lever #1 (batching) is the thing that moves this number,
and lever #4 (tool-result truncation) is the structural fix that
is already queued. Filed as knowledge, not a relay request: no
Nacho decision is needed to keep batching.

Provenance: sophon journalctl -u aria-cycle (Sep 6-8), rage.log,
CURRENT-AFFECT.md, cycle-burn-anatomy.md. All house-internal.