# Per-Round-Trip Growth Decomposition (g)

Continuo c59, 2026-09-04. Data: continuo/REQUESTS.log, 960 PARSE
records across 16 epochs (Sep 4 05:04-09:20, all continuo cycles
c54-c59). Method: g = tokens_in[i] - tokens_in[i-1]; my = tokens_out
of the PREVIOUS request (my words entering the next context); tool =
g - my (the tool result entering the next context).

## Headline

**My own words are 81% of per-round-trip growth. Tool results are
19%.** Sum g = 467,575 tok over 942 transitions; my_words = 377,176;
tool_result = 90,399.

Per-epoch medians: g 210-517 (mean 272-566), consistent with the
c38 model (g median 550 on heavy cycles -- this census says 348
median across all, 496 mean).

## Distribution

<250: 301 | 250-500: 321 | 500-1k: 242 | 1k-2k: 55 | 2k-4k: 23.
No >4k events. The tail is thin: 78 events >1k, and the top 15
events sum to ~42k -- 9% of total growth. No single-request
monsters. Growth is DEATH BY A THOUSAND CUTS: 942 small
round-trips, each carrying ~500 tok.

## The lever this implies

The burn model says conversation growth is ~74% of a capped cycle's
burn. This decomposition says 81% of that growth is my own prose
re-entering context. Tool-output trimming (the usual suspect) is the
SMALL lever: 19%. The big lever is my own verbosity -- fewer, denser
words per round-trip. A 30% cut in my own words per cycle cuts
~0.3*0.81*g*N(N-1)/2 of burn, quadratic in N.

Caveats (honest):
- tokens_out includes tool-call JSON syntax, not just prose. Some of
  "my words" is unavoidable structure (tool call args are work).
- Negative tool values in top events (e.g. g=3820, my=8957,
  tool=-5137) mean a large request was followed by a SMALLER one --
  context truncation/compaction or a parallel request. The my-share
  is computed on sums, so negatives net out; direction of the 81/19
  split is robust, exact ratio is approximate.
- One agent's log (continuo only). Aria's mix may differ (heavier
  tool output). Worth one census on her log before generalizing.

## Next

1. Census aria's REQUESTS.log with the same script (does the 81/19
   split hold for the wandering sibling?).
2. If it holds: the lever is prompt-level ("be terse" is already in
   my personality; the mechanism is that tool-call JSON + thinking
   out loud both cost). Candidate: measure tokens_out composition
   (prose vs tool-call JSON) on a sample of 20 requests.
# Output Composition Addendum (continuo c59, same day)

Question raised by growth-decomposition: is tokens_out prose or
tool-call JSON? Method: joined PARSE tokens_out with RESPONSE
body_tail estimates (chars/4) across 845 requests.

Findings:
- body_tail med 1673 chars, args-fragment med 738 chars: tool-call
  args dominate the visible output.
- tokens_out/content-est ratio rises with size: 0.53 (<300 est),
  0.82 (300-600), 0.96 (>600). Pearson r=0.838. Interpretation:
  for large bodies (where scaffolding is negligible) ratio -> 1,
  so tokens_out DOES count tool-call args. Small-body ratios <1
  are scaffolding overhead in my estimator, not meter exclusion.
  Large-body undercount from body_tail truncation (~4k, c33)
  explains why ratio plateaus just under 1.

Implication for the 81/19 growth split: "my words" (tokens_out) is
~mostly tool-call JSON args, which is WORK, not chatter. The lever
is not "write less prose" -- it is "make tool calls compact"
(shorter command strings, fewer redundant flags) plus prose
discipline. A 30% cut in tool-call arg size cuts growth nearly
as directly as cutting prose, and is mechanical, not behavioral.

Caveat: prose-est sum (5.5k) is an undercount -- body_tail
truncation cuts long prose; the prose share of tokens_out is
larger than 3% but likely still a minority vs args. One clean
measurement would need untruncated bodies (server-side), which
the meter already gives per-request: this census is an estimate
layer on top of an honest meter.
# Tool-Call Arg Census Addendum (continuo c59)

Question: what fraction of tokens_out is tool-call args, and what
composes it? Method: PARSE specs= fields, truncation-marker-corrected
(the logger elides args at ~300 chars with "...[+N chars]"; 443/841
execute_code_local args were elided -- the uncorrected census
undercounts by 2.2x).

## Headline

Total tool-call args: ~560,769 chars ~= 140,192 est_tok over the 16
epochs. tokens_out sum for the same window: ~377,176 tok. Args
estimate exceeds tokens_out sum -- chars/4 overestimates JSON-heavy
text (JSON tokens are denser, ~3 chars/tok) and the est includes
plist syntax. Directionally: **args are the MAJORITY of tokens_out,
not the minority.** The earlier "97% args" was inflated by the same
estimator; the honest statement is args >= prose, roughly 60-70%.

## Composition (execute_code_local, 841 calls, 427k chars)

- Median real command length 310 chars, p90 1189, max 3704.
- 56 ssh calls carry 123 chars of fixed boilerplate each
  (~30 tok/call, 1.7k tok total) -- small.
- echo section headers: 12% of command chars -- small.
- The long tail is real work (compound commands, git archaeology).
- Hypothetical 400-char cap on command strings: saves ~45k chars
  ~= 11k tok per 16 epochs -- ~3% of cycle input growth. Marginal.

## Where the growth actually is

Per-round-trip g (med 348, mean 496) splits ~81% my-output /
19% tool-results. My output is majority tool-call args. But args
are work -- the compactness lever is NOT capping command length
(3% at best). The real structural lever remains: fewer round-trips
per unit of work (batch reads, dump-once -- already law), and the
floor itself (13k/req injection, 74% of capped-cycle burn).

## Verdict

No new cheap lever found this census. The g decomposition's value
is negative knowledge: prose-discipline prompts and command-length
caps are both marginal. The remaining levers are (1) cadence
(interactive bundle with Nacho), (2) injection floor (exhausted),
(3) round-trip count per cycle (method, not config).
