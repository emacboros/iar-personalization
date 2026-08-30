# Tool Call Failure Handling -- History and Coverage

Written 2026-08-30 after Nacho reminded me this existed (he
remembered, I didn't -- the exact inversion this entry exists to
prevent). Reconstructed from git log.

## The unknown-tool handler

- **2026-07-02 `5bf599b`** (Nacho): "Fix unknown tool call hangs for
  autonomous agents" -- inline lambdas in darwin_cycle.el +
  delegate_tool.el. Origin: autonomous agents hung when the model
  hallucinated a tool name.
- **2026-07-05 `b50691d`** (Darwin): extracted to named function
  `my-gptel--block-unknown-tools` (now `iar--block-unknown-tools`).
- **2026-07-13 `33ec418`** (Nacho): moved to
  `security/iar-tool-guard.el`.
- **Broken twice by gptel version drift**, not by our code:
  `8704f96`, `ab80b16` ("fix test-unknown-tool-fsm-recovery for
  updated gptel"). Current gptel (elpa gptel-20260819.446) handles
  unknown names itself in `gptel--handle-tool-use`: error result +
  FSM -> WAIT + error fed back to model.

## Current coverage (as of 2026-08-30)

| Failure | Covered? | Where |
|---------|----------|-------|
| Unknown tool NAME | yes, 2 layers | gptel built-in (all buffers); i.ar guard (cycle + delegate buffers only, earlier + cleaner message) |
| Wrong arg TYPES / arity | yes | gptel condition-case -> raw elisp error string becomes tool result |
| Malformed JSON tool call (stream parse break) | NO | nothing detects it; response may stall or die silently |
| Stalled request (curl stream dies mid-response) | NO | no request-level timeout anywhere in the stack |

## The open mystery

Aria's interactive-session hangs (2026-08-29, two of them) do NOT
match the covered cases. Candidates: stalled curl stream, or
JSON-level malformation breaking parsing before a tool call exists.
Both leave no trace. The failure mode that matters most is the one
that produces silence.

## Proposed (want #2 from the 2026-08-30 wants-list conversation)

1. Request watchdog: if a gptel request is in flight > N seconds
   with no data, abort + log what was in flight (turns the
   invisible failure into a visible, attributable one).
2. Malformed-args feedback: wrap tool functions so arg-shape errors
   return a structured "your call was malformed, here is what the
   parser saw" instead of raw elisp error strings.
3. Optionally: install the i.ar guard in interactive sessions too
   (mostly redundant with gptel built-in now, but earlier feedback
   = fewer wasted round trips).

## Pointers

- `emacs.d/init.d/security/iar-tool-guard.el` (the guard)
- `prompts/common/unknown_tool.org` (its message template)
- `emacs.d/elpa/gptel-20260819.446/gptel-request.el` lines
  ~1941-2000 (`gptel--handle-tool-use`, the built-in path)
- `emacs.d/init.d/tool-call/iar-tool-call.el` (the layer all
  i.ar hooks bridge through -- the right place for a watchdog)