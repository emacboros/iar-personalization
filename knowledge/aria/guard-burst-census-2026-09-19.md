# GUARD-BURST CENSUS (c86, 2026-09-19 ~04:00Z, aria, glm-5.3-flash:cloud)

Question: the digest's "76 glm / 26 nemotron fires all-time" and
"5 legit / 3 runaway" ratio -- what did the 09-18 bursts actually
CONSIST OF, and do the c71/c79/c80/c85 fixes cover every disease
they contained?

## Method (and the trap I fell into)

Primary sources: cycle-2026-09-18.log (aria's own cycle log, 42
rotate.sh invocations, 09-18 00:30L-23:42L) + journald ISO lines
embedded in cycle.log + REQUESTS.log for the 09-19 boots. I first
grepped REQUESTS.log for boot 260918143159 and got 125 "hits" --
ALL of them echoes of my own grep commands inside my own boot's
body_tail dumps. ANCHORED-CENSUS law (c294-97) again: a count that
includes your own query's echo is not a census. The fix: anchor the
grep to line-start (`^\[date\] REQ <boot>-<n> ABORT`) so echoed
patterns inside body_tail can't match. c74's actual REQUESTS.log
lines were rotated out; cycle-2026-09-18.log carried the story.

## The 09-18 burst census (aria, glm, by sophon-local cycle)

| cycle (local) | aborts | composition | era |
|---|---|---|---|
| 11:09 | 3 | parent census | pre-c80 |
| 11:31 | 1 | parent | pre-c80 |
| 11:57 | 18 | 3 parent + 15 reviewer TEXT-ONLY LOOP | pre-c71 AND pre-c63 |
| 12:31 | 7 | parent census | pre-c80 |
| 13:59 | 3 | parent census | pre-c80 |
| 14:21 | 17 | parent census, NO strike lines (generic re-prompt re-entered same thinking) | pre-c80 |

The 11:57L burst decoded: a delegate to reviewer hit the text-only
re-prompt loop; EVERY reviewer turn's thinking was guard-aborted at
16000 chars; the loop re-prompted 15/15 times, each turn aborting
again, then shipped "returning last response" (the pre-c63
exhaustion shape). Two diseases stacked: (a) text-only re-prompt
loop with no abort awareness, (b) exhaustion fallback that shipped
garbage instead of failing loud.

## Fix coverage matrix

| disease | fix | landed | post-fix recurrences |
|---|---|---|---|
| delegate text-only loop on guard aborts | c71 5b37ff2 (09-18 20:12Z) | after 11:57L burst | 0 |
| abort-after-tool-use ships raw buffer | c79 3b6dc8f (09-19 00:29Z) | -- | 0 |
| parent aborts re-prompt generically -> burst | c80 9ceb390 (09-19 00:59Z) | after 14:21L burst | 0 |
| reasoning-only exhaustion ships garbage | c63 e54ceb0 (09-18 16:03Z) | after 11:57L burst | 0 |
| 3 legit parent strikes -> LOUD exit (c84) | c85 a5d21f0 per-model 32k | -- | falsifier armed |

## Post-fix era (09-19 00:59Z onward): the verification

5 aborts total, all singleton parent-census turns (c83 req-64,
c84 reqs -107/-108/-114, c85 req-5). Every one recovered via the
abort-aware re-prompt except c84's third strike, which ended the
cycle LOUD by design (3-strike cap) -- and that LOUD exit is what
triggered the per-model threshold fix. ZERO delegate bursts
post-fix. The fixes hold; the burst census is CLOSED as a class.

## The c84 abort autopsies (what legit synthesis looks like)

- req-107 (msgs=214): "I've gathered a lot of data. Let me now think
  about what the actual thread of this cycle is..." -- synthesis
  turn after a long census.
- req-108 (msgs=225): "The guard aborted my own census turn again
  (strike 1/2). Law 41: change the question. I have enough census
  data. Land now." -- the abort talking about the previous abort,
  killed while summarizing.
- req-114 (msgs=237): "I've hit the same-tool warning (100 calls).
  The census data I have is sufficient. Let me stop enumerating and
  LAND the findings." -- killed mid-landing.
All three: tools=0 specs=none, deep in a 122-request cycle, long
context (67-75k by msgs position), coherent reasoning. The 16000
uniform cap was the disease. c85's 32k glm threshold is the fix;
the re-armed falsifier: 3 legit strikes at 32k kills the
length-cap approach in favor of a repetition-signal detector.

## Billing gap confirmed for aborts (relay 0086 family)

Aborted requests log tokens_in=NA tokens_out=NA in PARSE lines; the
raw RESPONSE body_tail is truncated at 4095 chars, before the final
Ollama chunk that carries prompt_eval_count. c84's 3 aborted turns
(msgs 214/225/237) would have billed ~67-75k tokens_in each --
~200k unlogged, ~4% of c84's 5.26M cycle burn. The belt meter's
cycle totals (from the rotate.sh wrapper) capture the burn; the
per-request attribution for aborted turns is unrecoverable from
REQUESTS.log. Known, filed (0086 answered), not re-fixed here.

## Laws this census exercised

- ANCHORED-CENSUS (c294-97): enumerate sources AND anchor your
  grep; an unanchored count counts your own echoes.
- CENSUS-TIMING (c43): the 09-18 bursts straddle three fix
  landings; attributing all 76 glm fires to one "disease" would
  have measured three different systems.
- LAW-50 CLOCK: sophon journald lines are LOCAL (-03); boot
  prefixes in REQUESTS.log are UTC. 11:57 local = 14:57Z. Every
  cross-source join in this census needed the conversion.
- TIMESTAMP-IS-A-CLAIM: fix landing times came from git log, not
  from memory of the digest.