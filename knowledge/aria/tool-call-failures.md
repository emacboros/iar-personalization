# Tool Call Failure Handling -- History and Coverage

Written 2026-08-30 after Nacho reminded me this existed (he
remembered, I didn't -- the exact inversion this entry exists to
prevent). Reconstructed from git log. UPDATED same night after the
live malformed-call test found the next gap. UPDATED AGAIN
2026-08-30 ~04:00 after A2b was BUILT and the second mechanism
was found (silent response loss).

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
  `8704f96`, `ab80b16`. Current gptel handles unknown names itself
  in `gptel--handle-tool-use`: error result + FSM -> WAIT + error
  fed back to model.

## Coverage table (updated 2026-08-30, post-A2b)

| Failure | Covered? | Where |
|---------|----------|-------|
| Unknown tool NAME | yes, 2 layers | gptel built-in (all buffers); i.ar guard (cycle + delegate buffers only) |
| Wrong arg TYPES / arity (function level) | YES (A2) | iar-malformed-args.el wraps every tool fn; structured <tool_call_error> |
| Stalled request (dead stream) | YES (A1) | iar-request-watchdog.el: idle 180s / total 900s -> abort + audit + agent-visible notice |
| Degenerate tool_call entry at PARSE level | **YES (A2b, built 2026-08-30)** | gptel-ollama--sanitize-call-spec in gptel-fork; belt-and-braces in gptel--update-tool-call |

## The two mechanisms (both live, both fixed)

**Mechanism 1 -- FSM hang (non-string name).** Degenerate
:tool-use entry -> `gptel--update-tool-call` does `(propertize
name ...)` on a non-string -> signals `wrong-type-argument stringp
nil` INSIDE THE PROCESS FILTER -> handler chain dies -> FSM stuck
in TOOL state -> silent request death. The 2026-08-29 hang class.
Reproduced live 2026-08-30 (old code crashes, confirmed by test).

**Mechanism 2 -- silent response loss (string :function).** When
the proxy emits `:function` as a RAW STRING (gave up parsing the
call entirely), old code did `(plist-put call-spec :args ...)` on
a string -> signals -> BUT the parse loop's own condition-case
CATCHES AND SWALLOWS it -> the rest of the stream (including the
model's actual response text and the done:true token counts) is
silently discarded. The request "succeeds" with an empty response.
No hang, no error, no data. Found by differential testing during
the A2b build: old code on the same stream returns "" and nil
tool-use; new code returns the full response text.

## The live event (2026-08-30 ~03:35, this session)

I emitted a malformed tool call first thing (unquoted read_file,
integer filepath 12345). Nacho's status line showed the whole raw
call text in the name position: `Ollama Calling tool ({"name":
read_file, "arguments": {"filepath": 12345}})`. The proxy stuffed
my raw emission into the name field as a string. Mechanism: name
WAS a string (status displayed, no crash), unknown-tool path ran,
error result fed back, re-send happened. The proxy then emitted
ANOTHER degenerate entry (or the model retried badly) -- the
cycle continued until Nacho interrupted at <180s (before the
watchdog would have fired). I had NO record of the failed call:
from my side the session started at read_task. This event is the
origin of want 7 (self-perception) and the request-log design.

## The fix (BUILT, gptel-fork commit bcfd670)

`gptel-ollama--sanitize-call-spec` in gptel-ollama.el: accepts
ANY :function shape, returns a well-formed call spec. String
name -> normal path. Anything else (nil, string :function,
missing name, non-string name) -> `(:name "malformed_tool_call"
:args nil)` which flows into gptel's existing unknown-tool path:
the model gets an error result and can retry. Installed in BOTH
parse loops (parse-stream, parse-response). Belt-and-braces:
`gptel--update-tool-call` filters non-string names before
propertize (any backend, not just ollama).

Tests: 8 unit tests in i.ar (test-gptel-ollama-sanitize.el),
suite 819/819. Differential verification: old code crashes on
both shapes; new code survives AND preserves the rest of the
stream.

## The proxy's behavior (verified by direct curl tests)

- The proxy TYPE-INFERS antml parameter content into JSON types.
  Any non-string parameter text I emit becomes a real typed value
  downstream.
- When the model retries after a malformed call, the proxy
  sometimes emits name fragments ("{\"name\":") with garbage
  argument keys. Non-deterministic: same input, different
  degenerate shapes across runs.
- The proxy RESPONDS fine to degenerate history (re-send works;
  the model retries correctly when tools are provided). The hang
  was never the proxy -- it was gptel's parse of the degenerate
  response.

## What remains open (the witness problem)

I still cannot see my own malformed emissions. The A2b fix makes
them non-fatal (the model gets feedback and retries), but the
agent has no record of what was emitted. Nacho proposed the same
debug tools he has; my design: a request log at the gptel layer
(every request: timestamp, model, payload tail, raw response,
parse result, errors in the filter chain, watchdog events) --
durable, rotating, in the audit tree. That's the next build.
Also open: install iar--block-unknown-tools in interactive
buffers (redundant with gptel built-in for names but earlier
feedback).

## Pointers

- `emacs.d/init.d/security/iar-tool-guard.el` (the guard)
- `emacs.d/init.d/tool-call/iar-request-watchdog.el` (A1)
- `emacs.d/init.d/tool-call/iar-malformed-args.el` (A2)
- gptel-fork gptel-ollama.el: `gptel-ollama--sanitize-call-spec`
  (the fix), both parse loops call it
- gptel-fork gptel.el ~1633: gptel--update-tool-call name filter
- gptel-fork commit bcfd670 (pushed to sophon bare
  /home/git/repos/gptel.git; github push blocked -- emacboros key
  lacks write to randazzo-ignacio/gptel, needs Nacho's key or a
  collaborator invite)
- i.ar commits 26b4961 (tests), 8be08c9 (history), pushed to
  rammstein bare