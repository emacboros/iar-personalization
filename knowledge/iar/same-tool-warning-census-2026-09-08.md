# Same-Tool Warning: Census, Not a Stop (c151 data)

Date: 2026-09-08. Continuo cycle 151. Primary evidence: USAGE.log
(deduped, belt#2 exact-duplicate pairs confirmed -- all 36 today are
EXACT full-line dups, no content drift), cycle-2026-09-08.log.

## The question

The same-tool warning (iar-cycle-same-tool-warn = 40) fires once per
cycle when one tool reaches 40 calls. Does it CONVERGE the model, or
is it a census that fires and passes through?

## The data (today, 38 unique cycles)

- 14 of 38 cycles (37%) hit the warning -- all execute_code_local.
- Warning cycles: 23 cycles with >=40 req, avg 1.9M in / 56 req.
- Non-warning cycles: 15 cycles, avg 0.9M in / 30 req.
- Warning cycles carry 77% of today's input-token burn.
- The warning fires at 40 calls; warned cycles average 56 req -- the
  model does NOT converge after the warning. It keeps spiraling.

## Interpretation

The warning is a CENSUS, not a stop. It fires once at 40 calls and
passes through. The model reads it ("This call was NOT lost -- retry
it") and continues to 56 avg. The spiral causes the warning, not the
reverse -- warned cycles are the ones where the model was already
degrading into repetition.

The c38 finding (132 execute_code_local calls in a meter-reading
burst) motivated the total-per-tool counter. It correctly identifies
spirals but does not stop them. The chain guard (10 same-tool calls)
does not catch varying-command spirals (c109). The truncated-output
guard catches the burn at the FIRST 32768-token response -- the real
stop for this class.

## Why the warning should stay a census (not become a stop)

Heavy ssh-probe cycles are legitimate work (the 03:21 cycle, 105 req
/ 4.8M, was real verification). Making the same-tool warning a hard
stop would kill legitimate heavy cycles. The warning's job is to
signal; the truncated guard's job is to stop. The cap halving (c143,
32768) halves the worst-case burn per fire.

## The real lever

The class is the deepseek text-only repetition loop. The cap halving
reduces per-fire burn (avg 1.0M post-halving vs 1.8M pre-halving for
fire cycles). The truncated guard stops each burn. The CLASS keeps
recurring because the model mapping (continuo on deepseek) degrades.
Revert to glm-5.3-flash:cloud is Nacho's call on rotate.sh -- now
increasingly urgent given Nacho's failure-reduction priority.

## Cap halving verification (c143, 14e3fd4)

- 4 fires today at 65536 (pre-halving, before 11:42).
- 4 fires at 32768 (post-halving, after 11:42) -- journal shows
  "32768 tokens > 20000", the new cap live.
- Fire-cycle burn: avg 1.8M pre-halving, 1.0M post-halving.
- All 8 fires were grace (landed exit 0), none were failures.
