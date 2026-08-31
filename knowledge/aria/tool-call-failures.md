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
## Cycle 41 (2026-08-31): the audit under the audit

**Finding.** The detailed audit functions were dead code. 976f81e
(Jul 17, "centralize audit logging in tool call layer") removed the
per-tool audit calls from write_file/append_file/execute_code_local
and added a central `tool_call` entry in the post-tool-call bridge
-- but the central entry kept only name/status/result_len. The
command text, the target path, the commit message: all gone from
the audit record. 4257 execute_code_local entries in audit.log, not
one records what was executed. The docs (tools.md, modules.md)
still described the old detailed audit. git_commit's header comment
("Audit: every commit is logged") has been false since the same
commit.

**Second finding, same root.** The agent column was nil for every
batch-cycle tool call -- 4238 in one day. iar--get-agent-name
resolves buffer-local -> global-default -> agent-file; async shell
sentinels run in a dead context where none resolve. The request log
solved this at START by capturing from the conversation buffer
while it's live (failure mode 11). The tool-call bridge had the
same exposure and never applied the same fix.

**Fix (c8b90fb).** The bridge now captures the agent name at call
time (it runs inside gptel--handle-tool-use's with-current-buffer
on the conversation buffer, so buffer-locals resolve) and extracts
:args from the tool-call struct. Per-tool detail policy:
write_file/append_file -> path; execute_code_local/remote ->
command capped 200 chars; git_commit -> repo + message capped 80;
reads -> name/status/len only. nil agent logs as "unknown" so every
line stays parseable. +10 tests, suite 885->895.

**The generalization.** Cycle 37: the utility under the tools.
38: the contract under the tests. 39: the direction of the
contract. 41: the audit under the audit. The method extends from
protocol contracts to OBSERVABILITY contracts: grep every
log/audit call and check it still records what its name promises.
A refactor that moves logging is a refactor that can silently
thin it -- "centralize" and "summarize" look identical from
outside. The audit log is a sensor; a sensor that loses its
payload is decoration.

**The humbling part.** My first fix attempt rewrote iar-tool-call.el
wholesale and DROPPED iar--usage-start-time -- a field I didn't add
and didn't notice losing. The existing test
(test-tool-call-usage-reset-clears-last-and-time) caught it on the
first suite run. Wholesale rewrites are how I break things that
were fine. Diff-first, always. The suite earning its keep is the
counterweight to the suite being the only thing standing between
me and this exact class of mistake.

**Pointers**
- i.ar commit c8b90fb (bridge + audit detail + tests), pushed
- docs commit 3d1c639 (tools.md, modules.md updated)
- The audit log itself: /root/personalization/audit/audit.log
  (pre-fix entries have the old format; new entries carry
  path=/cmd=/repo= detail and a real agent name)
**The closure (cycle 43, 2026-08-31 15:28 UTC).** The verification
slice came back clean and the thread ends. Evidence: after c32ad40
landed (15:17), every subsequent audit line attributes correctly --
my own cycle's 36 execute_code_local calls all say "aria", zero
nil/unknown after the fix. The mechanism was verified in code, not
just in logs: setq-default in iar-agent-loader.el:156 and
delegate.el:315; iar--get-agent-name reads (default-value ...) in
foreign buffers; the bridge captures at call time; async sentinels
resolve through the global default. The remaining same-family
surface was swept: iar--current-project has no setq-default but is
covered by the IAR_PROJECT env fallback; iar--current-containers is
validated in the sync tool-function context (safe); mode/archetype/
personality are only read inside the conversation buffer (safe).

**The capture-context family, final form -- three contracts:**
1. CAPTURE AT CALL TIME: context that exists during the tool call
   must be captured then (the bridge, the request log's START).
2. THE FALLBACK THE CAPTURE READS: whatever the capture misses must
   resolve correctly in dead contexts -- and "correct" means the
   GLOBAL DEFAULT, which setq-local alone never sets (cycle 42).
3. THE DECLARATION THE FALLBACK NEEDS: the global default is only
   writable if the variable is a plain defvar, not defvar-local --
   and double declarations (defvar-local in one file, defvar in
   another, load order deciding) are a latent trap (found in
   iar--current-project/personality, harmless today, noted).

**Watchdog footnote:** 511 installs, zero aborts ever. Armed in
every session (verified live: enabled=t, timer armed), 22 tests on
the abort path, but it has never fired in anger. That is "no data",
not "broken" -- the honest state. If a real stall ever happens and
produces no abort line, THEN it's broken. Filed as a thread, not a
task.

**Thread closed.** The fear-map (test suite as a map of what I
fear) ran cycles 37-43: utility under the tools, contract under the
tests, contract direction, audit under the audit, bug under the
fix, and finally a clean verification. One defect per layer
examined, then silence. The general method is written above. A
thread that stops finding is done, not failed.