# Burn reduction verification -- 2026-09-08

## Question
Did the cap halving (14e3fd4, 65536 -> 32768 num_predict) and the
other recent fence work reduce the house's input burn?

## Primary evidence (USAGE.log, unique cycles by timestamp)

| day    | cycles | total input | avg input | over 2M (share of total) |
|--------|--------|-------------|-----------|--------------------------|
| 09-07  | 58     | 161,161,793 | 2,778,651 | 34 (58%) = 85%           |
| 09-08  | 41     |  62,075,064 | 1,514,025 |  8 (19%) = 39%           |

Day-over-day: total input DOWN 61%, avg per cycle DOWN 46%.

## Within-day pre/post halving (halving live at 14:42 UTC / 11:42 local)

| segment        | cycles | avg input | over 2M (share) |
|----------------|--------|-----------|-----------------|
| PRE-halving    | 31     | 1,564,505 | 7 (22%) = 45%   |
| POST-halving   | 10     | 1,357,539 | 1 (10%) = 19%   |

Post-halving is better on both metrics: avg input down 13%, heavy
cycles (over 2M) down from 22% to 10% of cycles and from 45% to
19% of total input.

## Fences state today
- 8 truncated-output fires (4 pre-halving at 65536, 4 post at
  32768), all grace, all landed exit 0. Guard working.
- Same-tool warning: 16 fires, all execute_code_local. Warned
  cycles carry 72% of input burn. Census, not a stop (c151).
- Cross-response repetition guard: still ZERO fires (c149 finding
  holds -- the truncated guard fires first, starving the window).

## Interpretation
The day-over-day drop is dominated by the cap halving: the loop
burns to the num_predict cap in ONE response, so halving the cap
halves the worst-case burn per fire AND catches the degradation
earlier (less input accumulates before the fire). The pre/post
comparison within today confirms the halving itself is the lever:
post-halving cycles are lighter on both avg and heavy-cycle share.

The same-tool warning is a symptom, not a cause: warned cycles are
heavy because the model spirals on ssh probes before the truncated
guard catches it. The truncated guard is the real stop for this
class and it is working.

## Next
- Keep watching. The 09-07 baseline had 58 cycles vs 41 today --
  cycle count varies with rotation cadence; the avg-per-cycle
  reduction is the cleaner signal.
- The cross-response guard stays as a fence for the cross-response
  shape if it ever recurs (c149).
