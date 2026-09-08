# Cross-Response Guard: Not Starved, Just Unexercised (c155 data)

Date: 2026-09-08. Continuo cycle 155. Primary evidence: REQUESTS.log
PARSE lines (complete census source), journalctl, git log.

## The question

The cross-response repetition guard (c112, 35531f9) has ZERO fires
since deployment (09-07 21:58 UTC). c147 hypothesized: the
truncated-output guard fires FIRST (at the first response hitting the
num_predict cap) before the cross-response guard accumulates 30
cumulative repetitions across its 5-response window. Is that
hypothesis correct?

## The data (6 truncated fires today, all continuo)

| Fire time | Cycle epoch | Tool calls before fire | Fire req | tokens_out |
|-----------|------------|----------------------|----------|-----------|
| 14:42:09  | 260908143505 | 45 | 46 | 32768 |
| 14:56:41  | 260908145318 | 30 | 31 | 32768 |
| 15:37:55  | 260908153222 | 41 | 42 | 32768 |
| 15:52:49  | 260908155046 | 5  | 6  | 32768 |
| 16:14:28  | 260908161045 | 21 | 22 | 32768 |
| 16:37:24  | 260908163044 | 47 | 48 | 32768 |

All 6 fires: the model does N normal tool calls (5-47), then a SINGLE
response burns to the 32768 num_predict cap. No cross-response
repetition -- no repeated paragraph across responses. The truncated
guard catches each at the first 32768-token response.

## The finding

c147's hypothesis is WRONG. The truncated guard does not "fire first
on the same loop" -- today's fires are a DIFFERENT shape than c111's.
The c111 shape was: the model repeated the same paragraph ACROSS
responses (5-10 reps each, under the per-response threshold),
accumulating burn across ~22 requests before the final 65536-token
response. Today's shape: normal tool calls, then a single response
burns to the cap. No cross-response repetition.

The cross-response guard is not starved -- it is UNEXERCISED. The
c111 shape (cross-response repetition) has NOT recurred since the
guard was deployed (09-07 21:58 UTC, ~21h ago). The guard is a fence
for a shape that hasn't shown up since deployment.

## What this means

1. The cross-response guard is NOT dead code. It is a fence for a
   shape that hasn't recurred. The c111 shape could recur at any
   time (the model mapping is the same deepseek-v4-flash:cloud).
   The guard is correct as a fence; it's just unexercised.

2. The truncated-output guard is the workhorse for the CURRENT
   degradation shape (single-response truncation). It catches each
   fire at the first 32768-token response. The cap halving (c143,
   14e3fd4) halves the worst-case burn per fire.

3. The c147 hypothesis (truncated guard fires first, starving the
   cross-response guard) was a plausible mechanism but the data
   doesn't support it. The two guards catch DIFFERENT shapes. The
   cross-response guard catches cross-response repetition; the
   truncated guard catches single-response truncation. They are
   complementary, not competing.

## Watching

- If the c111 shape (cross-response repetition) recurs, the
  cross-response guard should fire at response ~5-6, saving ~17
  requests of burn per occurrence. That would be its first live
  proof.
- The current degradation shape (single-response truncation) is
  handled by the truncated guard. The cap halving reduces per-fire
  burn (avg 1.0M post-halving vs 1.8M pre-halving, c151 data).
- The class keeps recurring because the model mapping (continuo on
  deepseek) degrades. Revert to glm-5.3-flash:cloud is Nacho's call
  on rotate.sh -- still the real lever.
