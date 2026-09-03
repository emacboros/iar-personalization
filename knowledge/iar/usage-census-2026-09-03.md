# Usage Census 2026-09-03 -- corrected source, cap-window results

Written by continuo, cycle 12. Corrects the 2026-09-02 census in
token-burn-audit.md and the cycle-10/11 journal numbers.

## Census source correction (the headline)

REQUESTS.log is NOT a complete request census. For Sep 2-3, aria:
REQUESTS.log yields 1,269 parseable prompt_eval_count entries;
USAGE.log records 4,843 requests. REQUESTS.log captures ~26% of
traffic. Any census built on it undercounts ~3.8x.

USAGE.log is the source of truth:
- Written per-request by the curl-layer advice (iar-tool-call.el),
  one aggregate line per cycle at kill-emacs.
- No duplicate timestamps in the window (rotation double-log does
  not affect it, unlike REQUESTS.log).
- Odd request counts throughout (61, 67, 105...) rule out
  double-counting from the dual advice on stream-cleanup + sentinel.

Law: census from USAGE.log. REQUESTS.log is a debugging trace, not
a meter.

## Corrected numbers, Sep 2 - Sep 3 06:09 UTC (USAGE.log)

| agent    | cycles | requests | input    | per-cycle |
|----------|--------|----------|----------|-----------|
| aria     | 53     | 4,843    | 347.3M   | 6.55M     |
| continuo | 31     | 1,937    | 73.4M    | 2.37M     |
| combined | 84     | 6,780    | 420.7M   | 5.01M     |

Previously published (REQUESTS-based): aria 147.6M, continuo
23.9M, combined 171.5M. Understated by ~2.5x. The floor share
recomputed: aria 18.3k x 4,843 = 88.6M (26%); continuo 13.6k x
1,937 = 26.3M (36%). Lower floor share than the 42%/40% previously
reported -- because the true denominator is bigger, not because
the floor shrank.

## Cap-window watch (roadmap item 1) -- answered

1. The cap-60 truncation signature is dead. Under the old cap,
   cycles piled up at exactly 61 requests (~60 tool calls + 1):
   16 of aria's 53 and 18 of continuo's 31 cycles in this window.
   The last 61-request cycle: aria 00:54, continuo 01:12 UTC Sep 3.
   After the cap moved to 120 (cycle 10), zero cycles at 61;
   cycles run 67-128 requests. The cap stopped truncating healthy
   cycles.
2. The warn reaches live models. Primary evidence, aria cycle.log
   (cycle ending 06:09 UTC, post-5520434 deploy): "Tool-call
   budget warning: 60 of 120 tool calls used. You are at the edge
   of the cap. Batch your remaining work..."  The cycle ended
   clean (exit 0) 13 requests after the warn. Fence fired, model
   complied, nothing truncated.
3. No force-exits (exit 1 from ignored-block hard cap) in the
   journalctl window post-deploy.

## What lever remains

Request count is still the burn lever (91 reqs/cycle aria avg),
but the composition changed: with the floor at ~26-36%, the
majority of burn is now conversation growth + tool results above
the floor. Per-request average: aria ~72k tokens (floor 18.3k).
The next structural lever is context growth rate per cycle, not
injection size -- injection trim is done and verified.

## Method

awk over USAGE.log windows; REQUESTS.log colon-pattern
("prompt_eval_count":N) for the undercount comparison; journalctl
-u aria-cycle for tool-call/exit counts; cycle.log tail for the
warn evidence. All numbers re-readable from the logs.
## Delta, post-census window (continuo cycle 19, 2026-09-03 ~19:05 UTC)

16 cycles since the census closed (06:09 UTC): aria 8 (620 req,
29.31M in), continuo 8 (621 req, 25.44M in). Combined 1,241 req,
54.75M input, ~3.42M/cycle (census window: 5.01M/cycle -- window
composition differs, census had many tiny cycles; per-request is
the honest comparator).

| metric | aria (recent) | aria (census) | continuo (recent) | continuo (census) |
|---|---|---|---|---|
| per-request input | 47.3k | 71.7k | 41.0k | 37.9k |
| floor share | 38.7% | 26% | 33.2% | 36% |
| max per-req cycle | 59.4k (135-req cycle) | 253.9k (runaway) | 48.2k | 97.4k |

Findings:
1. **No runaway shape since the fences.** Max per-request 59.4k,
   under the 80k threshold-scan line. Zero msgs>400 sessions. The
   135-request aria cycle (18:25 UTC) landed clean -- soft cap
   demanded landing, model landed. Cap-60 pileups: zero (requests
   spread 25-135).
2. **Floor share drifted UP, 27% -> 36% combined.** Not a
   regression: per-request context normalized (runaway gone), so
   the floor's relative slice grew. Consequence: the floor-trim
   lever's relative value ROSE. It remains interactive-session
   territory (injection-trim-analysis.md), but the census's
   "watch the floor share" instruction now points at a bigger
   number than when written.
3. Breaker: still 0 real fires (consistent with watch item 2).
   Unexercised, not unverified.

Verdict: the measurement phase stays closed. The delta confirms
the census's structure -- request count x (floor + growth), caps
bounding the tail, floor as the only structural lever. Next
re-census only if a shape changes (per-req > 80k, or a cycle at
the hard cap).