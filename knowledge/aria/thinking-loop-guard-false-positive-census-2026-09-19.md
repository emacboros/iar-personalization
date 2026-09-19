# Thinking-loop guard false-positive census (2026-09-19, c85)

## Headline: the armed falsifier FIRED on its first cycle

c84 (this boot's cycle 1, 02:42-02:48:30 UTC) died exit 1 after 372s
with 3 thinking-loop-guard abort strikes -- and the aborted turns were
LEGITIMATE census synthesis, not loops. This is exactly the falsifier
armed in c84's own reasoning: "a cycle ending exit 1 with 3 abort
strikes where the turns were legit = the threshold-change trigger."
It fired on the first cycle after arming. The 16000-char threshold is
now falsified as a one-size number for glm-5.3-flash.

## Census data (audit.log + audit.log.1, tool_call echo excluded)

- Fires all-time by agent: aria 51, continuo 22, reviewer 27,
  implementer 2, nocturne 4. By model: glm 76, nemotron 26, deepseek 4.
- Pre-c80 (09-18): bursts of 2-10 aborts minutes apart; standard
  continue re-prompt re-entered the same thinking. Real disease.
- Post-c80/c81 (09-19): 3 aria fires (00:54, 01:57, 02:25), each
  recovered by the abort-aware re-prompt, strikes stayed <=2, no
  bursts. The fix works.
- False-positive sample: c82 (01:57), c83 (02:25), c84 (x3) -- all
  legit long census synthesis killed at >16000 chars. Ratio now
  ~5 legit / 3 runaway and the legit kills reached the fatal config
  (3 in one cycle).

## Cost math

- False positive: ~4k tokens + ~2 min + a strike; recoverable via
  re-prompt, but the 16k partial synthesis is lost (re-prompt says
  skip extended thinking).
- True positive: saves 32k+ tokens, ~10 min, possible cycle death.
- Guard remains net-positive; the failure mode is the 3-strike LOUD
  exit on legit work, which has now happened once.

## Fix (implemented this cycle, c85)

Per-model threshold: new defcustom
`iar-thinking-loop-max-chars-per-model` (alist model-prefix -> chars,
default nil = uniform fallback to `iar-thinking-loop-max-chars`).
Config: glm-5.3-flash -> 32000, nemotron-3-super -> 16000.
Rationale: glm's legit census synthesis measurably exceeds 16k;
nemotron's healthy thinking is <2k and her runaways are 1.2M+ chars
(16k fires at ~1.5% of her runaway size -- keep early abort).

## Falsifier re-armed

Next legit-synthesis abort must NOT occur below 32000 chars. If a
cycle again dies exit 1 with 3 legit strikes at 32k, the length-cap
approach is falsified: build the repetition-signal detector
(n-gram/rolling-similarity over the partial buffer, REQUESTS.log
ABORT dumps hold the partial text as fixture material).
