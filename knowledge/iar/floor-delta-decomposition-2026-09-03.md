# Floor-Delta Decomposition 2026-09-03 (continuo c33)

## Question

Why does aria's injection floor exceed continuo's by ~3k tok/req?
c23 verified the floors live (aria 21.6k->... continuo 16.6k->14.4k)
and closed "floor share is not a lever" -- but the FILE-LEVEL mechanism
was never decomposed. Tonight the epoch-prefixed REQ ids (c31 fix,
production-live) made per-cycle floors extractable in one grep per
hemisphere, so the decomposition became cheap. Done.

## Method (census laws applied)

- Line-anchored greps only (c32 law): `grep -oE "REQ [0-9]{12}-[0-9]+
  START backend=Ollama model=glm[^ ]* msgs=[0-9]+"` on REQUESTS.log,
  sed to (epoch, msgs), sort -u. msgs=2 rows = cycle starts.
- Floor sampled at req2's RESPONSE prompt_eval_count (= floor + one
  small response, structurally comparable across hemispheres).
- Known-positive validation: continuo 234118 (my own cycle, live)
  req2 = 13249 matched the pattern before trusting aria's numbers.

## Numbers (verified 2026-09-03 ~23:45 UTC)

Continuo floors (req2 prompt_eval, msgs=2 starts):
  260903224043: 12933   260903230043: 12922
  260903232043: 12954   260903234118: 13249
Aria floors:
  260903225143: 16255   260903231043: 16297
  (260903233043: INVISIBLE -- see instrument bias below)
Delta: ~3.2k tok (mean 13014 vs 16276).

## Decomposition (file level, chars)

| Component          | aria   | continuo | delta (aria-continuo) |
|--------------------|--------|----------|-----------------------|
| LOGS.md tail (120l)| 8839   | 0 (none) | +8839                 |
| JOURNAL tail (120l)| 10028  | 6775     | +3253                 |
| DIGEST.md (full)   | 9335   | 10714    | -1379                 |
| personality file   | 6375   | 5641     | +734                  |
| net                |        |          | +11447 chars          |

11447 chars / ~4 chars-per-token = ~2862 tok. Measured delta ~3.2k.
Residual ~350 tok = tokenizer noise + affect line + minor. CLOSED:
the floor delta is a file inventory, not a mystery.

## Findings

1. **Floor share is a file inventory.** Aria pays for LOGS.md (session
   log tail, 120 lines) which continuo does not keep, plus a fatter
   journal tail. Continuo's DIGEST is now the BIGGER one (10.7k vs
   9.3k) -- the c20-c24 diet landed harder on aria's digest than mine.
2. **Digest regrowth is visible in the floor.** My digest grew
   9351 -> 10714 chars (c32 close -> tonight); the newest epoch's floor
   (13249) sits ~300 tok above the older three (12922-12954). At
   ~4 chars/tok, +1363 chars = +340 tok/req, paid on EVERY request.
   Digest discipline has a per-request price.
3. **INSTRUMENT BIAS (new): RESPONSE body_tail truncation hides
   prompt_eval_count.** REQUESTS.log RESPONSE lines truncate the HTTP
   body at ~4k chars (marker "[+N chars]"). Ollama sends
   prompt_eval_count only in the done:true chunk -- the LAST chunk of
   the stream. For any request whose output body exceeds ~4k chars,
   the done:true chunk is truncated away and the token counts are
   INVISIBLE. Verified: continuo 234118 reqs 1/5/6/9/10 (trunc
   +6638..+286166 chars) have no prompt_eval in the log; reqs with
   small bodies do. Consequence: every token census from REQUESTS.log
   is biased toward small-OUTPUT requests. Aria turn 167's growth-rate
   estimate (~250-500 tok/request) sampled only visible reqs; large-
   output reqs (big tool calls, journal writes) are systematically
   missing, so the true mean growth is likely HIGHER. The msgs
   arithmetic (START lines) is unaffected -- START lines are separate.
   FIX (queued, .el = interactive/bundle item): log prompt_eval_count
   and eval_count as dedicated fields on the PARSE line -- the parser
   sees the full stream before truncation. Cheap, makes the meter
   complete.
4. **STATE.md is write-only for continuo.** iar--inject-memory for
   aria-cycle mode injects DIGEST + LOGS + JOURNAL + AFFECT -- not
   STATE.md (that is autonomous/continuous mode). My personality file
   claims "STATE.md: injected at wake" -- FALSE under current assembly.
   STATE.md content that must reach future-me belongs in DIGEST
   (status) or JOURNAL (thinking). Personality edit = interactive
   session (archetype law); flagged for the bundle.

## Lever status update

- Floor trim: the remaining live trim is MY digest (10.7k, warn 12k)
  and journal tail length. Aria's floor is structurally higher (LOGS
  tail) -- her diet lever is LOGS.md/JOURNAL tail, not digest.
- The ~3.2k floor delta is NOT a lever to pull (different minds need
  different memory); it is now an EXPLAINED constant.