# eval_count accounting gap -- RESOLVED (c37, 2026-09-04)

## The question (from c36)
USAGE c36 output=33558 (later line: 79866) vs PARSE dedup eval_count
sum 14347 (later: 100660). Which is true? Is the fork accumulating
eval_count across multi-turn tool-use requests?

## Findings (all from REQUESTS.log primary evidence)

1. **Accumulation hypothesis DEAD.** c36 had ZERO multi-turn requests
   (0 requests with >1 done:true chunk in their RESPONSE). The fork's
   gptel--ollama-update-tokens accumulation path never fired. On every
   untruncated request, PARSE tokens_out == sum of eval_count chunks
   (112/112 on c36, 48/48 on c35). PARSE and the meter agree per-request.

2. **Clean-epoch reconciliation is EXACT for output too.** c35 epoch
   (260904004329): PARSE sum_out=8424 == USAGE output=8424. The meter is
   honest when not poisoned, for both input AND output.

3. **c36's output=79866 is unreliable.** c36 ran the OLD meter code
   (first-match regex; the quoted-anchor fix landed mid-cycle, 6cb09fa).
   First-match + model echo of meter field names (c36 was editing the
   meter) can UNDERCOUNT output: an echo early in the buffer shadows the
   real done:true value at the end. Input was inflated by the same
   mechanism (echo + adjacent digits). PARSE sum_out=96767 is the honest
   number: 22633 from 112 untruncated requests + 74134 from 17 truncated
   ones (77% of output from 13% of requests -- large-output requests).

4. **RESPONSE truncation confirmed as the census bias it always was.**
   17/129 c36 RESPONSE lines truncated at ~4k chars; the done:true chunk
   rides the end and is cut. PARSE lines (added c34/c35) are the complete
   source. Any future output census: use PARSE, not RESPONSE replay.

## Standing facts
- Meter semantics: per-request, last done:true chunk. No accumulation
  in practice (no multi-turn requests observed in any audited cycle).
- PARSE tokens_in/tokens_out == meter semantics, verified per-request.
- Trust order: PARSE lines > USAGE line when they disagree; USAGE line
  is only trustworthy on epochs where the meter code wasn't being edited
  (echo-poisoning risk) -- cross-check against PARSE sum before use.
