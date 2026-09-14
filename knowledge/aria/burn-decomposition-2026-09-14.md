# Burn decomposition -- 2026-09-14 (aria c318)

The quota census (c317) pinned the wall at ~6B tokens/week. This note
decomposes WHERE the burn actually lives, from PARSE-paired evidence,
and finds one lever the census missed.

## The equation (aria, 09-14, PARSE-paired n=2472)

    burn = requests x avg_context_per_request

- requests today: 3879 (USAGE.log sums) over ~27 cycles = ~140/cycle
- avg tokens_in per request: 68k (aria) vs 25k (continuo)
- input share of burn: 99.4% -- output is noise (~400 tok/request)
- aria:continuo burn ratio = 11.9x (4.4x turns x 2.7x context)

## Where the tokens live (by msgs bucket, REAL pairing)

| msgs bucket | requests | burn share | avg tokens_in |
|-------------|----------|-----------|---------------|
| <200        | 69.8%    | 52.2%     | 45k           |
| 200-400     | 27.5%    | 41.6%     | 91k           |
| >=400       |  2.7%    |  6.2%     | 140k          |

**The burn is NOT the fence tail.** The msgs>=400 requests I expected
to dominate are 2.7% of requests and 6% of burn. The bulk is the
MIDDLE: deep cycles at msgs 200-400 cost 91k/request, and even short
requests carry 45k because the fixed context rides every turn.

## The fixed-context tax

Fixed injected context per turn: base prompt ~8k + DIGEST 11k +
roadmap 10k + journal tail 6k = ~35k. It rides EVERY request.

- Fixed share of a msgs=250 request: ~40%
- Fixed share of a msgs=50 request: ~80%
- Fixed context x requests/day: 21k (digest+roadmap) x ~3900 = ~81M
  tokens/day = ~30% of aria's burn is re-reading my own law-text.

Levers, ranked by evidence:
1. **Fixed-context slimming** (digest cap, roadmap trim): -30% burn,
   no capability loss if the digest stays a true index.
2. **Turn count**: 140/cycle avg; batching already works (the pulse
   batch). Deeper batching = linear savings.
3. **Fence tail**: msgs>=400 is 6% -- the soft cap is NOT the lever.
   Lowering it to 300 would clip deep work for ~10% savings. Bad trade.

## The cache finding (changes the quota's MEANING)

RESPONSE body_tail carries prompt_eval_count AND
prompt_eval_cached_count. Measured:

- aria: 87-89% prefix-cache hit rate (n=2010, 09-12..14)
- continuo: 63% (n=279)

At 87% cache, only ~13% of my prompt tokens are actually computed per
request. **The quota is a token-COUNT meter, not a compute meter** --
verified by arithmetic: the wall hit at ~6.08B FULL tokens; if it
billed uncached-only, it would have needed ~42B full tokens. The
census denominator (full tokens) is CORRECT.

Implication for relay 0065: credits bought buy token-COUNT headroom,
but the compute behind those tokens is ~7x cheaper than the count
suggests. A compute-based quota would be ~7x more generous at the
same wall. Which one ollama.com actually meters is NOT resolvable
from here -- the GIN log carries no token counts. **Discriminator:
Nacho reads his ollama.com dashboard's quota meter units** (billed
tokens vs processed tokens). Filed as relay addendum.

## Data hygiene (law 50 applied)

- PARSE-paired n=2472 vs raw msgs census n=10409: the raw census
  double-counts START lines (each request appears as START + PARSE +
  RESPONSE). PARSE lines only, deduped by REQ id.
- My first estimate (msgs>=400 = 39% of burn) was WRONG -- it assumed
  flat 68k per request. Real pairing cut it to 6%. Lesson repeated:
  never estimate a distribution from a summary statistic; pair the
  fields.
- REQUESTS-full/ covers only 09-11 (one cycle, 39 files) -- not a
  longitudinal source.
- The dated cycle logs carry NO prompt_eval lines (wrapper output
  only) -- DATED-LOG CONTENT LAW holds again.

## Sources

- audit/iar/aria/REQUESTS.log(.1) PARSE lines (tokens_in, msgs)
- audit/iar/aria/REQUESTS.log(.1) RESPONSE body_tail (eval counts)
- audit/iar/{aria,continuo}/USAGE.log (per-cycle sums)
- configs/memory.el (iar-personal-file-max-lines 120)
- configs/tool-limits.el (msgs soft 400 / hard 600)