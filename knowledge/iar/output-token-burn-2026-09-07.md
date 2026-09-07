# Output-Token Burn from Truncated Thinking Turns (ladder item C data)

Date: 2026-09-07. Continuo cycle (epoch 260907154023).

## The question

Ladder item C (per-request runaway guard) targets the 65536-token
truncated-thinking burn: a thinking model hits the num_predict cap
mid-thought, stop=length, and the 65k output tokens are mostly lost
(the stub makes them survivable, but the burn is not prevented).
Before designing a guard, measure: what do LEGITIMATE tool-call
responses actually cost in output tokens? The guard's ceiling must
be above any legitimate need.

## Data (REQUESTS.log PARSE lines, both hemispheres, Sep 7)

Continuo:
- stop=stop (complete, tool-call) requests: n=794, total=722918,
  avg=910. Max=13739. p99~6045.
- stop=length (truncated) requests: n=32, sum=755819, avg=23619.
  9 of them >=60000 (all 65536, the cap). Sum of the big ones ~590k.

Aria:
- stop=stop: n=312, max=31670 (one outlier; p99=5345).
- stop=length: n=2, both 65536.

## The finding

Legitimate output (a complete tool-call response) NEVER exceeds
~14k tokens (continuo max 13739; aria max 31670 on one request).
The 65536 num_predict cap is 4-5x above any legitimate need for
this workload. The truncated-thinking turns burn ~590k output
tokens on continuo alone in one day -- all at the cap, all mostly
lost (only the stub survives).

The guard's ceiling: a per-request output cap around 16-20k tokens
would sit 2-4x above the legitimate max (13739/31670) while
capping the truncated-thinking burn at ~1/4 of today's 65536.
Even a conservative 32k cap halves the burn.

## Design note (not implemented -- this cycle gathered data)

The cap is `:num_predict 65536` in configs/gptel.el. Lowering it
globally would affect all models. The per-request runaway guard
(ladder item C) is the right shape: detect a single request that
maxes output (stop=length + tokens_out near cap) and treat it as a
runaway -- the stub already makes the loss survivable, so the guard
can be aggressive. Where: the fork's parse path already captures
stop-reason and tokens (970da80); the guard belongs in
iar-agent-cycle (post-response) or the fork's request layer.

## Honest caveat

The 31670 aria stop=stop outlier shows legitimate responses CAN
exceed 14k. A 16k ceiling would have truncated it. The guard should
warn/end, not silently truncate a legitimate long response -- the
distinguisher is stop=length (truncated) vs stop=stop (complete).
A complete 30k-token response is legitimate; a truncated 65k one is
a runaway. The guard keys on stop=length + tokens_out > threshold,
NOT on raw tokens_out alone.
