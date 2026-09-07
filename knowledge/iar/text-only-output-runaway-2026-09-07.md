# Text-only output runaway (deepseek-v4-flash degradation)

## Date
2026-09-07

## Symptom
Continuo cycle failed exit 1 after 770s (01:00:44 -> 01:13:31). The
cycle.log tail shows a degenerate repetition loop: "Let me check the
caller. Let me look at the caller." repeated thousands of times
(5573 occurrences in cycle.log).

## Primary evidence (REQUESTS.log, epoch 260907010044)
- REQ-51 at 01:13:15: `tools=0 specs=none error=nil stop=length
  tokens_in=49067 tokens_out=65536`
  A SINGLE request produced 65536 output tokens of pure text (no
  tool call), hitting the max output length cap (`stop=length`).
  This is the degenerate loop.
- REQ-52 at 01:13:20: `tools=1 ... stop=stop tokens_in=49887
  tokens_out=596` (a sed on gptel-ollama.el)
- Cycle then hit 770s timeout, exit 1.

## Root cause
Model degradation: deepseek-v4-flash entered a text-only repetition
loop, producing endless repeated text with NO tool calls. The single
request burned the entire 65536-token output budget.

## Why the fences did NOT catch it
- Loop guard: counts TOOL CALLS, not text-only output. A text-only
  runaway makes zero tool calls -> loop guard silent.
- Context circuit breaker: measures INPUT buffer size, not output.
  A text-only runaway grows output, not input -> breaker silent.
- Neither fence detects a text-only output runaway.

## Current-cycle confirmation
The NEXT cycle (this one, epoch 260907012126) shows the SAME
degenerate pattern in its own cycle.log: "Let me look at the actual
end of the cycle.log" repeated. The model is currently degraded and
prone to repetition loops.

## Gap
No fence catches a text-only output runaway. This is a real
machinery gap, but the fix (a repetition/output-runaway detector) is
a project, not a one-cycle change. And while the model is degraded,
any cycle risks burning itself in the same loop.

## Recommendation
1. File a task: text-only output runaway detector (detect repeated
   identical output text across a request; abort/end run).
2. If the model stays degraded, consider switching the cycle model
   or pausing cycles until the model recovers.
3. Per protocol: when the model feels degraded, stop early, log,
   CYCLE_COMPLETE -- do not burn the cycle investigating.
