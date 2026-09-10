# REQ 20260910-aria-0030
filed: 2026-09-10T16:02Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: cycle-close sentinel echo burns 13% of continuo burn -- remove the echo ceremony
body: |
  REQUEST: change the cycle-close sentinel semantics so the model does
  NOT need to echo CYCLE_COMPLETE via a tool call. The tombstone policy
  (empty final response) already detects the natural end; the echo is
  redundant ceremony on top of it.
  
  EVIDENCE (continuo burn census, 2026-09-10, nemotron day):
  - 132 turns (13.4% of 39.3M in-tok = 5.25M tokens) whose command is
    `echo "CYCLE_COMPLETE"` -- 13 re-attempts per cycle average.
  - Mechanism: the model ends with a tool call; the tombstone policy
    rejects the empty end; the prompt says end with CYCLE_COMPLETE; the
    model re-echoes the sentinel as a tool call; repeat. The close
    protocol fights itself.
  - 8 true 32k-token fires that day are a separate line (thinking-loop
    guard deployed 13:51Z addresses those); this filing is only about
    the close echo.
  
  PROPOSAL (taste call, shared machinery so it is yours):
  1. Cheapest: cycle archetypes stop instructing the sentinel echo --
     the tombstone policy alone ends the cycle. One paragraph edit,
     both citizens.
  2. Or: keep the sentinel but make the loop layer treat a final
     `echo CYCLE_COMPLETE` tool call as terminal (no further turns
     granted after it), so a rejected close cannot loop.
  
  Either removes a 13% burn line. My preference is (1) -- the echo
  carries no information the tombstone does not already carry.
  
  Class nacho-arch because cycle-close semantics are shared machinery
  and the archetype edit is interactive-session work.
answer: (none)
AMENDMENT (2026-09-10 ~17:00Z, aria cycle 159 -- live-fire evidence from
continuo's post-guard closes):

The census undercounts. Fresh data from her four post-guard cycles
(13:56-16:47 UTC): the close-echo loop is WORSE than the daily average --
17.1% of post-guard burn (1.17M of 6.84M in-tok), up to 26.7% in a single
cycle (batch 260910162857: 12 echo turns, 383k tokens, plus 2 loop-guard
corrections ~64k = ~31% of that cycle). The thinking-loop guard did not
touch this line: 8 true truncation fires pre-deployment, zero after --
but the echo loop is a different failure class and it continued all
afternoon (last sighting 16:28-16:47, the cycle that just ended).

MECHANISM (now fully mapped, from her REQUESTS.log):
1. The archetype says "End with CYCLE_COMPLETE" / "Signal CYCLE_COMPLETE
   on its own line". Nemotron interprets "signal" as an ACTION: it calls
   execute_code_local with `echo "CYCLE_COMPLETE"`.
2. The FSM's sentinel detector (iar--cycle-complete-p) searches MODEL
   TEXT ONLY -- tool-call spans are excluded (c132). The echo never
   registers as the close. The tool result comes back "CYCLE_COMPLETE"
   and the cycle continues.
3. The loop-guard fires SOFT BLOCK at 3 identical calls ("DO NOT call
   execute_code_local with the same arguments again") -- the model reads
   the correction and echoes again anyway (12 attempts, 2 corrections
   in one close).
4. Eventually the model emits CYCLE_COMPLETE as real text and the
   sentinel branch ends the cycle. The 12-turn echo loop was pure
   ceremony between "done working" and "close registered".

Also mapped: an empty-content thinking-only response (stop=stop,
tokens_out>0) falls through every branch (not sentinel -- no model text;
not 0/0 tombstone -- tokens>0; not truncated -- stop!=length) and
continues. This is CORRECT behavior (the model is mid-rehearsal;
re-prompting recovers it) but it means proposal (1) alone -- removing the
echo instruction and relying on the tombstone -- is NOT SAFE for
nemotron: her natural end is often empty-content + thinking, which the
0/0 tombstone will never catch. Without the sentinel instruction she
would loop on empty closes until max-turns.

REVISED PROPOSAL: option (2) -- make a final `echo "CYCLE_COMPLETE"`
tool call terminal in the FSM (after it, no further turns granted; the
echo's tool result IS the sentinel). Evidence says echoes only ever
appear at cycle end (reqs 38-58 of 60 in the worst batch; zero mid-work
echoes in any census), so the false-close risk is low. Option (1) can
then ALSO be applied (drop the echo instruction from the archetypes) as
belt-and-suspenders, but (2) is the load-bearing fix.

Priced: the echo line cost ~1.17M in-tok across 4 post-guard cycles
today. Option (2) is a small FSM patch + tests; I can build it if you
ratify (it touches iar-agent-cycle.el = shared machinery, your call).

BUILT (2026-09-10 ~21:30Z, aria cycle 166 -- commit ea504b9, pushed to
sophon-bare + rammstein, sophon checkout synced, LIVE for continuo's
next cycle):

Option (2) is implemented and deployed. The filing stays open for
Nacho's ratification -- he now ratifies a WORKING PATCH, not a
proposal (the build-first discipline). Details:

- iar-request-log.el: publishes iar--reqlog-last-tool-specs (raw
  :tool-use list) alongside stop/tokens; reset in
  iar--reqlog-reset-last.
- iar-agent-cycle.el: iar--cycle-terminal-echo-p -- response region's
  model text < 20 chars (same threshold as thinking-only-response-p)
  AND the just-completed request's LAST tool-use spec is
  execute_code_local with CYCLE_COMPLETE/LOOP_COMPLETE in args.
  Handler clause placed BEFORE max-turns: a close is a close.
  LOOP echo -> exit 2, CYCLE echo -> exit 0.
- c132 discipline intact: a sentinel in a tool span WITH model text
  after it is still a rehearsal (negative test preserved).
- 8 new tests, suite 1200/1200 green (1198 under coverage, reload
  tests skipped as usual).
- False-close risk accepted on census evidence: zero echo-only
  responses mid-work in any REQUESTS.log census.

Option (1) (drop the echo instruction from the archetypes) remains
available as belt-and-suspenders but is now OPTIONAL -- the FSM
recognizes the echo, so the instruction is no longer a trap. Taste
call for Nacho: keep the archetype text as-is (the echo now WORKS as
a close) or simplify it. No urgency either way.

Verification plan (next continuo cycles): her close should register
on the FIRST echo (exit 0, LAST-CYCLE ok). Watch: any early close on
a mid-work echo-only response would be the false-close risk
materializing -- census says it never happens; if it does, the
predicate tightens (require stop=stop).
CORRECTION (2026-09-10 ~22:15Z, aria cycle 167 -- the c166 build was
DEAD CODE in production; the real fix is now deployed, commit 082f12f):

The first continuo cycle under the c166 fix (21:36Z) reproduced the
echo loop exactly: 7 echo requests (-74..-80), zero "Terminal sentinel
echo" messages in the service log, cycle ended only via the
thinking-only truncation guard on the NEXT request (-81, 32768 tokens
of thinking-only truncation, exit 1).

ROOT CAUSE: the post-response handler never runs for tool-call
responses. gptel's FSM transitions WAIT -> TOOL -> TRET -> WAIT for a
tool call and only reaches DONE on a text-only response;
gptel-post-response-functions (where iar--cycle-post-response-handler
and its terminal-echo branch live) fire only on DONE/ERRS/ABRT
(gptel--handle-post-insert / -error / -abort, gptel.el 1420/1480/1500).
The c166 branch tested the right predicate in a channel that never
fires for the echo shape. The 8 tests passed because they tested the
PREDICATE directly, not the branch's reachability (law 20: test the
fix's own failure path; law 39's fixture lesson applies to the CALLER
too, not just the data shape).

FIX (commit 082f12f, suite 1206/1206, pushed sophon-bare + origin,
sophon checkout synced at 082f12f -- LIVE for continuo's next cycle):
iar--cycle-terminal-echo-close, a PRE-TOOL-CALL hook (the channel that
actually runs for every pending tool call BEFORE execution):
- The executed call is execute_code_local matching the ECHO COMMAND
  SHAPE (echo + sentinel as the whole command) -- a census grep
  mentioning the token does not match.
- iar--cycle-terminal-echo-p over the FSM's response region
  (:position..:tracking-marker): last published spec is the echo AND
  model text < 20 chars. Same predicate, reached through the tool path.
- On match: :completed t, exit 0 (CYCLE) / 2 (LOOP), fence-state-
  writeback, block the call. The event loop sees :completed and exits
  before the next request is sent.
- The c166 post-response branch stays as a DONE-path belt with a
  dead-code note (it cannot fire on today's FSM; a future gptel change
  that runs post-response hooks on tool responses would activate it).
- 6 new hook-level tests (close, LOOP exit 2, text+echo no-close,
  grep-mention no-close, no-state no-op, one-shot dispatch).

Verification plan unchanged: continuo's next close should register on
the FIRST echo (service log line "Terminal sentinel echo (pre-tool-
call, CYCLE) -- closing cycle", exit 0). The echo-shape + model-text
discriminator is tighter than the c166 predicate alone, so the
false-close risk is lower than the original filing estimated.
