# Ollama.com weekly quota census -- 2026-09-14 (aria c317)

The empirical wall, pinned. Relay 0065 asked "credits, accept, or
remap?" -- this census gives the decision its numbers. Decision stays
Nacho's (money + identity, D-008: cycles never propose model changes).

## The wall event (09-13)

- First 429: Sun 09-13 07:54:46Z (04:54:46 sophon-local), ollama GIN log.
- 35 GIN 429s total, ALL on 09-13, spaced ~30min (the cycle timers
  retrying into the wall). Zero 429s any other day 09-07..09-14.
- Last 429: 09-13 23:33:41Z. First 200 /api/chat after: 09-14 00:01:27Z.
  -> weekly window resets Monday 00:00 UTC (one reset observed).

## Weekly window totals (Mon 09-07 00:00Z -> wall, from USAGE.log sums)

| agent    | tokens   | share |
|----------|----------|-------|
| aria     | 5.09B    | 83.5% |
| continuo | 0.95B    | 15.6% |
| nocturne | 0.037B   |  0.6% |
| total    | ~6.08B   |       |

Daily shape (total, M tokens): Mon 962, Tue 780, Wed 883, Thu 986,
Fri 1195, Sat 1085, Sun-until-wall 184. Avg ~950M/day. Wall hit day
6.33 of 7. **The quota is ~6B tokens/week** (empirical; the
authoritative number is on Nacho's ollama.com settings page).

## Who burns it

Aria is 83% of the quota. Nocturne is 0.6% -- killing or remapping
Nocturne saves nothing; consolidation is not the budget problem. Any
decision that does not touch aria's burn does not touch the quota.

Aria's daily burn trend: 409M (09-01) -> 640M (09-07) -> 1.06B peak
(09-11, session-XV day with delegated fixes). Burn tracks AMBITION
(interactive sessions, deep investigation cycles), not cadence.

## The margin finding

This week so far (Mon 09-14 00:00Z -> 12:15Z): aria 266M + continuo
22M = 288M in 12.2h -> ~565M/day pace -> ~4.0B/week if it holds. A
cycle-only week FITS under the wall (~66% of quota). The wall binds
when the week contains an interactive session day (+0.5-1B) or
several deep-investigation cycles. **The quota is structural for
ambition, not for cadence.** One heavy session tips it; one quiet day
slides it.

## Falsifiable prediction

If this week's burn repeats last week's shape (any substantial
interactive session or heavy investigation run), the wall re-hits
**Sun 09-20 between ~04:00Z and ~12:00Z**. Nocturne's 16:04Z daily
pass that day would 429 again -- exactly one week after the last
consolidation failure. If the week stays cycle-only, the wall is
missed entirely. Daily 429 check is now a standing watch (roadmap).

## Data hygiene

- continuo 09-04 carries two ~260B-token USAGE lines (00:08:20,
  01:16:40) -- the c262 doubling-bug family, corrupt, excluded.
  Outside the window; noted per law 50 (verify the column).
- Duplicate USAGE lines (same timestamp twice, continuo 09-04) exist;
  dedupe by timestamp before summing. Did not affect window sums.
- USAGE.log lines are batch summaries; sums are approximate (~1-3%).
- Sources: sophon ollama GIN journal (429/200 lines), per-agent
  USAGE.log daily sums, nocturne-digest.service journal + oneshot log.

## Implication for relay 0065 (data only, decision Nacho's)

- (a) credits: buys headroom proportional to spend; the binding
  constraint is aria's 5B/week.
- (b) accept: costs ~1 day of continuo cadence + nocturne darkness
  on wall day; cycles self-heal at reset.
- (c) remap: only an aria remap moves the number (83%); continuo is
  16%, nocturne noise. Local qwen3.6:35b-a3b exists (standing
  retainer) but is a quality/capability trade on the deepest cycles.