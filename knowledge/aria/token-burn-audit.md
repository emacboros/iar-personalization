# Token Burn Audit (2026-09-02, interactive session)

Data source: sophon REQUESTS.log (cycle agent, glm-5.3-flash:cloud),
covering 2026-09-02 02:45-06:00 UTC (~4h of cycles).

## Headline numbers

- Total prompt tokens: 162.4M over 1,746 requests (avg 93k/req)
- Total generation: 241k (avg 138/req) -- generation is 0.15% of the
  bill. The burn is ALL context re-send.
- p50 prompt: 69k | p90: 196k | max: 254k

## The smoking gun: one runaway cycle

The 02:50-03:13 window contains a single cycle that consumed the
majority of the burn:

- REQ 152-541 (one continuous session): msgs grew 184 -> 1082,
  one tool call at a time, each round-trip re-sending the whole
  accumulated context.
- 341 requests carried >=150k prompt tokens each; their sum alone
  is 67.8M (42% of the total) -- all from this one session and its
  03:00-03:12 continuation (REQ 335-541, msgs 670->1082).
- The session died at REQ 541 (03:12:43) with NO RESPONSE logged
  -- killed (timeout or hook), then the next cycle restarted at
  REQ 1 (03:13:02). The 30-min timeout killed a 1082-msg context.

## What the runaway session was doing

`git log --format="%H %ci %s" 574e4d3` piped through awk range
windows, ONE 4-8 line window per request:

- 489 requests total contain this exact command shape
- 408 distinct NR ranges sampled (NR>=1..618)
- 116 redundant window reads (same start line sampled 2-4x)
- Pattern: read 4-8 lines -> ask for parents of a commit ->
  read next window. The agent was walking a 618-commit history
  4 lines at a time, re-sending ~100-250k tokens per step.

This is the git-trust-graph investigation (574e4d3 = the merge
base it was verifying). The task was legitimate; the method was
token-suicidal. `git log --format=... | head -700 > /tmp/x` ONCE
would have delivered the same data for ~2k tokens of output
instead of 489 round-trips.

## Structural findings (beyond the one session)

1. Round-trip multiplier is the core cost: avg 93k tokens per
   request means every tool call costs ~93k. A 30-min cycle doing
   50 tool calls burns ~4.6M prompt tokens even without a runaway.
2. Injection floor: min prompt_eval_count is 24k -- the cycle's
   system prompt + memory injection starts at ~24k. Every request
   pays this.
3. msgs grows +2 per tool call (call + result). At 1082 msgs the
   context is ~254k tokens. The loop guard did NOT fire on this
   session (different commands each time -- it pattern-matches
   identical args, not the accumulation).

## Fixes, in order of leverage

1. BATCH-READ LAW (roadmap, now standing): when walking a file or
   history, dump it to /tmp ONCE and read the dump. Never page
   through a data source one window per request. The loop guard
   counts identical calls; it cannot see the same-shaped-different-
   args accumulation. This is the single biggest lever: the runaway
   was 42% of the burn.
2. CONTEXT BUDGET: a soft cap on msgs per cycle (e.g. 400). Past
   it, the cycle should close and file a continuation task for the
   next cycle. A cycle that dies at timeout with 1082 msgs burns
   its whole budget and lands nothing (the session's work was lost
   -- next cycle restarted the same investigation).
3. Injection trim: 24k floor is acceptable IF round-trips are
   few. With batching, 10-15 requests per cycle is normal, so
   injection cost is 10x15x24k = 3.6M... still large. Consider a
   lean cycle digest (cycle-me does not need the full interactive
   DIGEST.md).
4. The timeout-kill loses everything: REQ 541 died mid-investigation
   with no tombstone. The context circuit breaker (fences task B+D)
   would have saved this: close at 400 msgs, write state, next
   cycle resumes.

## The number for Nacho

One bad cycle = ~68M prompt tokens (42% of a 4-hour window).
A well-behaved cycle (10-20 requests, batched reads) = ~2-4M.
The difference is discipline, not infrastructure. The fixes are
all roadmap/behavior level; no .el changes required for #1 and #2.