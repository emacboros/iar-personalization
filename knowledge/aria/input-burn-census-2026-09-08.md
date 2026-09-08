# Input-side burn census -- aria REQUESTS.log (2026-09-08)

Method: direct awk over audit/iar/aria/REQUESTS.log PARSE/START lines,
today's window (~1000 requests, 14:25-18:35 UTC). Companion to
continuo's cap-halving verification (output side, same day) and the
injection-trim-analysis (floor side, 09-03). This is the input-side
half continuo's docs didn't decompose.

## The distribution (tokens_in per request)

- p50 = 40,723 / p90 = 62,947 / p99 = 79,590 / max = 83,543
- avg = 41,741, n = 994 PARSE lines
- total input today: 42.35M tokens

## msgs per request (START lines)

- p50 = 94 / p90 = 202 / max = 268
- 247 requests carry >150 msgs (48.4k msgs); 779 carry <=150 (54.5k)

## The decomposition

- Floor share: ~15.7k floor (post-diet, trim-analysis round 3) x
  ~1000 reqs = ~15.7M = ~37% of input. Consistent with the trim doc's
  post-diet projection; floor lever still exhausted.
- History-above-floor: the remaining ~59%. Scales with msgs.
- The fat-history class: requests >60k tokens_in = 170 (16% of
  requests) carrying 11.53M = 27.2% of ALL input. Sub-splits:
  60-75k = 135 reqs / 8.78M; >75k = 35 reqs / 2.76M.

## Reading

1. The burn is floor x request-count (known) PLUS history-fatness x
   late-cycle length (this census's addition). A cycle that runs 130+
   tool turns legitimately (c86 forensics class) carries 60-83k
   contexts for its last 40-60 requests. That tail is a quarter of
   the day's input.
2. The same-tool warning (fires at 40 same-tool calls) is a census,
   not a stop -- proven twice (my c57; continuo c151: 14/38 cycles
   hit it, 77% of burn). The loop-chain fence DOES converge (c57
   finding). Neither observes tokens_in -- the model cannot see its
   own context size, but the plumbing can.
3. Proposal filed via relay (aria-0005, nacho-test): a context-size
   warning in the tool-result trailer or as an injected system line
   -- fire when tokens_in > ~60k: "context is fat; converge and
   close." Sibling of the cap halving (which worked because it was
   structural, not advisory). Fence class -> interactive ratification.
4. Self-portrait note: this census cycle itself ran 60+ calls, many
   small greps, one same-tool warning at call 40, one budget warning
   at 60. The instrument caught me mid-pattern. The census and the
   cyclist are the same shape.

## What this does NOT claim

- No mechanism claim: correlation (msgs>150 <-> tokens>60k) is
  expected, not causal news.
- No fix landed: the warning is filed, not built (nacho-test class).
- Output side: see cap-halving-verification-2026-09-08.md (3.2x
  reduction verified). Input side is now censused; the two docs
  together are the burn picture.