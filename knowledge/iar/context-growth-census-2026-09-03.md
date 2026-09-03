# Context-Growth Census -- 2026-09-03 (continuo cycle 5)

Question (roadmap, from cycle 12): floor is 26%/36% of burn; majority is
conversation growth above the floor. Which tools add the most context per
cycle? Measure before proposing any trim.

Method: REQUESTS.log(.1) for both agents, md5-deduped (rotation copies),
prompt_eval_count from RESPONSE bodies, tool from PARSE specs=, msgs from
START. Sample through 2026-09-03 08:05 UTC. Census script pattern: dump
once, one python pass (batch-read law).

## Headline

**No per-tool trim is worth building.** Per-call context growth is ~0.5k
tokens/request (aria mean 511 / median 347; continuo mean 494 / median 322).
Across the whole sample, growth above the floor totals ~1.7M of 318M prompt
tokens (0.5%). The burn is (floor + accumulated context) x request count --
the multiplier is request count, not any tool's appetite.

## Distributions

| metric | aria | continuo |
|---|---|---|
| sampled prompt total | 241.3M / 3438 reqs | 76.8M / 1747 reqs |
| prompt mean / median | 70.2k / 52.2k | 43.9k / 40.9k |
| prompt p90 / max | 149k / 253.9k | 71.0k / 97.4k |
| floor share | 26.1% | 30.9% |
| growth/req mean / median | 511 / 347 | 494 / 322 |
| msgs delta/req | 2.01 | 2.02 |

(aria p90 is runaway-inflated; see below.)

## Per-tool growth (n>=5, sorted by total)

aria: execute_code_local n=2819 mean +468 (82% of all calls, dominates by
count not size); read_file n=95 mean +1674 (fattest per call -- but the tool
already truncates to ~10k chars; low count); read_knowledge n=32 +1088;
everything else <1.2k total contribution each.

continuo: same shape -- execute_code_local n=1160 +414; read_file n=129
+1267; write_file/append_file/read_knowledge all minor.

## The slope is front-loaded, then flat

Prompt by msgs bucket (aria): msgs 0-99 mean 38.5k -> msgs 1000+ mean 247.8k.
Growth/req msgs<100 = 482; msgs>=100 = 117. Early requests carry the floor +
prompt assembly; late-cycle growth is just fixed-size tool results. Context
does not compound -- it plateaus. (The plateau level is set by how much the
cycle accumulated early.)

## The runaway is the story

368 STARTs with msgs>400 exist in the sample. ALL are 2026-09-02 02:52-05:30
-- one cycle, one buffer, msgs 402->1082, final prompt 253.9k tokens
(~1.0M chars), ~169M prompt tokens = **70% of aria's entire sampled burn**.
Zero msgs>400 STARTs since. That session predates every fence now in place:

- warn cap @60 reqs reaches the model (5520434, verified in production)
- soft cap @120 reqs demands landing
- chain guard escalates to hard stop (44da3c9, hook-order fix)
- context circuit breaker @800k chars (~200k tok) ends the run (4c879a2/6130c13)

The breaker is suite-covered but has NOT fired in production -- no session
has crossed 200k tokens since it landed. Unexercised, not unverified.

## Threshold scan (aria, runaway included)

Cap 40k -> 45.6% of prompt burn is excess; 60k -> 29.9%; 80k -> 21.6%;
100k -> 16.0%. Excluding the runaway, healthy sessions end at 30-58k final
prompt. A token-level soft cap at 80k would rarely fire on healthy cycles and
would add floor re-payments on restart for marginal savings. **Not justified
by data.** Revisit only if healthy p90 creeps above 80k.

## Per-cycle burn (USAGE.log, last 6 each)

aria ~1.29M/cycle mean (range 0.06-2.85M). continuo ~4.14M/cycle mean
(range 0.73-8.35M -- inflated by the 120-cap chain-guard investigation
cycles 2-4, which are the designed worst case: ~135 reqs x ~44k mean
prompt = ~6M; aria worst case ~9.5M).

## Remaining levers, ranked by measured headroom

1. **Injection floor trim** (26%/31% of burn = ~84M of 318M sampled): the
   only structural lever left. Analysis exists
   (knowledge/iar/injection-trim-analysis.md); overview-only injection is
   landed; further trim is interactive-session territory.
2. **Cycle volume**: aria 53 cycles x ~65 reqs is the workload, not waste.
   The request caps bound the tail at ~135 reqs/cycle by design.
3. **read_file per-call fat** (+1.3-1.7k/call): already truncated, low
   count. Skip.
4. **Per-tool result trimming**: measured headroom ~0.5% of burn. Skip.

## Verdict

The token-budget thread's measurement phase is done. The floor is the only
structural lever left, and it is interactive-session work. Cycle-level
discipline (request caps + breaker) is landed and verified. Close the
census; watch the floor share, not the tools.