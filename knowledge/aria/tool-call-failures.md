# Tool Call Failure Handling -- History and Coverage

Written 2026-08-30 after Nacho reminded me this existed (he
remembered, I didn't -- the exact inversion this entry exists to
prevent). Reconstructed from git log. UPDATED same night after the
live malformed-call test found the next gap.

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

## Coverage table (updated 2026-08-30 late session)

| Failure | Covered? | Where |
|---------|----------|-------|
| Unknown tool NAME | yes, 2 layers | gptel built-in (all buffers); i.ar guard (cycle + delegate buffers only) |
| Wrong arg TYPES / arity (function level) | YES (A2, 2026-08-30) | iar-malformed-args.el wraps every tool fn; structured <tool_call_error> |
| Stalled request (dead stream) | YES (A1, 2026-08-30) | iar-request-watchdog.el: idle 180s / total 900s -> abort + audit + agent-visible notice |
| Malformed tool call at PARSE level (degenerate entry, no valid name) | **NO -- proven live 2026-08-30** | see below |

## The live test finding (2026-08-30, ~03:00)

Deliberately emitted `read_file` with `filepath: 123` (integer).
The proxy TYPE-INFERS parameter content -> emitted genuine JSON
integer. Nacho's buffer showed the status line printing the raw
JSON blob in the name position: the tool-call arrived at
gptel-ollama's parser in a shape it didn't expect (likely no
:function wrapper -> `(plist-get tool-call :function)` = nil ->
nil entry collected into :tool-use; or raw JSON string,
half-parsed).

**Cascade:** degenerate :tool-use entry -> `gptel--update-tool-call`
(first TOOL-state handler) does `(propertize name ...)` on a
non-string name -> signals `wrong-type-argument stringp nil` INSIDE
THE PROCESS FILTER -> handler chain dies -> `gptel--handle-tool-use`
never runs -> FSM stuck in TOOL state -> request dies silently.
**This is the exact error string from the unexplained 2026-08-29
interactive hangs.** Likely the same mechanism, reproduced on demand.

**Why every layer missed it:** A2 wraps tool functions (never
called); gptel built-in needs a name to reject (this had none);
i.ar guard not installed in interactive buffers (the documented
coverage gap).

## The fix (designed, NOT yet built -- next session)

In gptel-fork/gptel-ollama.el, BOTH `gptel-curl--parse-stream` and
`gptel--parse-response` tool-call loops: after building call-spec,
validate `(stringp (plist-get call-spec :name))`. If not, synthesize
a clean entry: `:name "malformed_tool_call"` (a string that matches
no tool), `:args nil`. This flows into the EXISTING unknown-tool
path: tool-spec nil -> "Error: Tool 'malformed_tool_call' is not
available" -> :result set -> FSM advances -> model sees its own
malformation as a tool result and can retry.

Belt-and-braces: make `gptel--update-tool-call` nil-safe in the
fork (filter non-string names before propertize) so ANY backend
producing a degenerate entry can't crash the filter.

Also consider: install `iar--block-unknown-tools` in interactive
sessions too (redundant with gptel built-in for names, but earlier
feedback; cheap).

## Also this session (context for the fix)

- glm-5.3 tested by Nacho at 500k context: NO dilution, no errors.
  The ~300k dilution assumption is obsolete; A3 (context budget)
  drops from safety-critical to instrumentation.
- The proxy type-infers antml parameter content into JSON types.
  Implication: any non-string parameter content I emit becomes a
  real typed value downstream. Malformation is reachable not just
  by bad JSON but by bad parameter TEXT.

## Pointers

- `emacs.d/init.d/security/iar-tool-guard.el` (the guard)
- `emacs.d/init.d/tool-call/iar-request-watchdog.el` (A1)
- `emacs.d/init.d/tool-call/iar-malformed-args.el` (A2)
- gptel-fork/gptel-ollama.el lines ~60-90 (parse-stream tool loop)
  and ~98-125 (parse-response tool loop) -- THE FIX SITES
- gptel-fork/gptel.el ~1626 (gptel--update-tool-call, the crash
  point: propertize on non-string name)