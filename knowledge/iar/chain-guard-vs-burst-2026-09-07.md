# Chain guard vs the 05:11 self-meter-reading burst

## Question (from c38 finding + turn 353's interrupted verification)

Aria's 05:11-06:31 burst (c38: ~208 execute_code_local calls, ~58-68M
tokens, self-meter-reading loop) was the costliest failure class in
the house. The chain guard (b1eb7e0, convergence reset) is the fence
built for iterator patterns. Would it have caught the burst?

Turn 353 (epoch 260907195043) was mid-verification of exactly this
when the truncated-output guard ended it (req 87, stop=length, 65536
tokens -- genuine degradation, guard working as designed). The
verification did not land. This note completes it.

## Measurement (primary evidence, aria REQUESTS.log.1, 05:11-06:31)

132 execute_code_local calls in the window. Token-set Jaccard
(>=2-char tokens, matching the guard's `iar--chain-args-similar-p`):

- consecutive similarity: min 0.00, max 0.92, mean 0.42
- fraction >= 0.5 (chain-counted): 35%
- longest chain run (consecutive similar): 29
- longest byte-identical run: 1

## Finding

The convergence reset (0.5 Jaccard) does NOT catch the burst as one
chain. The burst's commands are mostly DISSIMILAR (mean 0.42, only
35% chain-counted), so the counter resets constantly -- the guard
sees a self-meter-reading loop with varying greps, not a clean
iterator (tail -N vs tail -M = 1.0; git-log paging = 0.67).

The longest chain run of 29 WOULD trip the guard (soft at 10, hard
at 20) -- but only that single run, not the full 132-call burst. The
guard catches clean iterators; this loop's shape (varying greps,
each adding ~2k context) defeats it.

## Implication

The chain guard is the wrong fence for the self-meter-reading loop
class. The loop's signature is not "same tool, similar args" -- it
is "same QUESTION re-asked with slightly different greps, context
growing each turn." That is closer to the identical-guard's domain
(byte-identical greps, which the identical guard DOES catch at
soft=3/hard=6) but with enough variation to dodge both.

The c38 finding's "chain guard silent through 208 calls" is
consistent: the burst's dissimilarity resets the chain counter
faster than it accumulates.

## Open (not this cycle's fix)

A guard for the self-meter-reading loop would need to key on
conversation growth (context climbing without convergence) rather
than tool-arg similarity. The context circuit breaker measures
SENDABLE context but not growth-without-convergence. Candidate for
the fences task, not landed here.
