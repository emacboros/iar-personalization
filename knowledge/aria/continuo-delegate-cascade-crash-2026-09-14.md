# continuo cycle failure 2026-09-14: delegate cascade + timeout race
# (root-cause analysis, aria cycle 308)

## The event

continuo's 2026-09-14 03:50-04:10 LOCAL cycle (run 260914065006)
failed exit 255 after 1211s. Terminal log lines:

    [loop-guard] SOFT BLOCK: delegate called 3 times identically
    Error running timer: (wrong-type-argument stringp nil)      04:09:24
    error in process sentinel: Wrong type argument: stringp, nil 04:10:04
    [ERR] Cycle 1 failed in 1211s (exit 255)

## What continuo did

06:58:24Z: continuo delegated (pipeline mode, no :agent) with a
600s timeout. The pipeline (agent-assistant) then spawned a
RECURSIVE CASCADE:

- continuo -> pipeline#1 (agent-assistant, depth 1)
- pipeline#1's first response: delegate(task) AGAIN -> pipeline#2 (depth 2)
- pipeline#2's first response: delegate(task) AGAIN -> pipeline#3 (depth 3)
- pipeline#3's response: delegate(implementer) -> implementer (depth 4)
- implementer (07:07:27): delegate(reviewer) -> reviewer#2
- reviewer#2 (07:08:35): delegate(implementer) -> implementer#2
- reviewer#2 (07:08:54): delegate again

At least 8 concurrent gptel request streams in one Emacs process,
each delegate carrying a 600s timeout timer.

## Root causes (three, stacked)

### 1. The delegate depth guard is DEAD CODE (primary)

emacs.d/init.d/tools/agent/delegate.el, iar--spawn-async-delegate:

    (setq-local iar--delegate-depth (1+ parent-depth))
    (when (>= iar--delegate-depth iar-delegate-max-depth)
      (setq-local gptel-tools (cl-remove-if ...delegate...)))   ; strip
    ;; Apply tool gating from project
    (when tools
      (setq-local gptel-tools tools))                           ; OVERWRITES

The project-tools setq-local runs AFTER the depth strip and
REPLACES the stripped list. Any agent whose project #+TOOLS
includes delegate (agent-assistant.org does) has the guard
nullified at every depth. The cascade ran to depth 5+.

Fix: strip AFTER the project set (intersect), not before.

### 2. Timeout-during-live-pipeline (the crash trigger)

continuo's 600s delegate timeout fired 07:08:24Z while the
pipeline was still mid-flight (its sub-agents kept making requests
until 07:10:04Z). iar--delegate-timeout-handler marked completed,
gptel-abort'ed the pipeline buffer's LIVE curl request, armed a 3s
kill-buffer timer, and called the parent callback. continuo then
re-delegated (-172 response at 07:08:52 = another delegate call,
soft-blocked as the 3rd identical). The orphaned sub-agents kept
running; their completion hooks, re-prompt timers (1s), and
buffer-kill timers (3s/5s) then raced the abort/kill path. One
timer (07:09:24Z, likely the duplicate pipeline#2's 600s timeout
from 06:59:24Z) and one curl sentinel (07:10:04Z) hit dead/nil
buffers -> wrong-type-argument stringp nil -> the cycle's event
loop lost its request -> exit 255.

This is the c149 class again, reached by a different path: c149
fixed the double-callback (mark completed before abort); it did
not handle a pipeline that OUTLIVES its delegate timeout.

### 3. REQUESTS.log attribution race (instrument corruption)

iar--reqlog-agent (iar-request-log.el) is a process-global captured
at each START and used by later RESPONSE/PARSE events. With
concurrent sub-agents, every START overwrites it; RESPONSE/PARSE
land in whichever agent's log was written most recently. Verified
live: continuo's -172 RESPONSE+PARSE sits in agent-assistant's log;
the implementer's -167 sits in reviewer's log. Any census that
trusts per-agent REQUESTS.log boundaries during delegation is
wrong. Fix: store the agent name per-fsm (in the process hash
alongside the REQ id), not in a global.

## What did NOT fail

- The loop guard: correct at every fire (append_file x5, delegate
  x3, budget 150). Compliance was honest.
- The watchdog: no stall to catch -- the requests were live, the
  crash was in the delegate/timer layer above it.
- continuo's own behavior: re-delegating after a timeout is a
  reasonable model move; the machinery should have absorbed it.

## Fix plan (filed as tasks)

1. delegate.el: move the depth strip after the project-tools set
   (or intersect: strip delegate from the FINAL list). + test.
2. iar--delegate-timeout-handler: before aborting, check for live
   sub-requests in the delegate's buffer; if the pipeline is still
   producing, extend or drain instead of aborting. (Design needed;
   filed, not built this cycle.)
3. iar-request-log.el: per-fsm agent attribution. (Filed.)

## Census note

The reqlog race means continuo's REQUESTS.log for this run is
INCOMPLETE (its -172 RESPONSE/PARSE is in agent-assistant's log).
Per-agent request censuses across this window must read ALL agent
logs and dedupe by REQ id.