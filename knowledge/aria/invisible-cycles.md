# The Invisible Cycles -- timeout-killed work leaves no record
# Written by aria-cycle, cycle 127, 2026-09-02 ~05:15 UTC
# Evidence: REQUESTS.log(.1), sophon aria-cycle.service journal, USAGE.log

## The finding

Four cycles on the night of Sep 1-2 (UTC) were killed by the 1800s
cycle timeout and left NO trace in the journal, no summary, no commit:

| UTC window   | reqs | input tok | what it was doing |
|--------------|------|-----------|-------------------|
| 02:12-02:42  | 279  | ~23M      | frigate journalctl investigation (the archaeology cycle 126 later REDID) |
| 02:42-03:12  | 540  | ~82M      | research-sidecar thread -> git-log window enumeration loop (339 distinct `awk NR>=N` windows over 618 commits from 574e4d3) |
| 04:13-04:43  | 173  | ~15M      | 150 DISTINCT frigate ssh probes (the archaeology again, killed mid-work) |
| 01:13-01:43  | ~?   | ~?        | stall, Turns 0, Tool calls 2 (invisible, unknown content) |

The journal only records what completed. A timeout-killed cycle is
amnesia: the next cycle inherits a clean repo and no idea what the
dead cycle learned. Cycle 126's "the prediction missed by one honest
question" was actually re-doing the 04:13 stall cycle's work.

## Why the fences did not fire

1. **max-turns counts MODEL-STOPS, not tool calls.** In gptel's FSM a
   response containing tool calls goes TPRE->TOOL->TRET and re-requests
   without ever reaching DONE. `iar--cycle-post-response-handler` only
   fires at DONE/ERRS/ABRT, so turn-count stays 0 through an entire
   tool-call chain. 540 consecutive tool-call responses = 1 turn.
   The only bound on chain length is the 1800s timeout.

2. **The loop guard pattern-matches IDENTICAL args.** Six identical
   calls stop the request (iar.sh hook: "called execute_code_local
   with identical arguments 6 times"). An iterator that varies args
   (`awk 'NR>=90 && NR<=92'` -> `NR>=92 && NR<=94` -> ...) never
   matches. 339 distinct windows sailed through.

3. **The tool-call counter is context-blind.** The tracker lives on a
   BUFFER-LOCAL hook (`add-hook ... nil t` in cycle-buf), but the
   advice that fires it runs from ASYNC process sentinels
   (execute_code_local is :async t), where current-buffer is not
   cycle-buf. Result: 360 actual tool calls counted as 13 (cycle B),
   682 counted as 2 (cycle C). The systemd timeout message
   "Turns: 0, Tool calls: 2" is a lie about the cycle's actual shape.

## The cost

~199M input tokens today (USAGE.log, through 05:02). The invisible
cycles are the majority of the burn. The 30M+/cycle average Nacho
flagged is the NORM; the git-log loop alone was 82M in one cycle.

## Fix directions (spec, not implementation)

A. **Bound the chain, not the turn**: cap tool-calls-per-cycle (e.g.
   60) in the pre-tool-call hook, or count tool calls in the tracker
   and end the cycle at N. The counter must be made reliable first
   (global hook or explicit buffer binding in the bridge, not
   buffer-local lookup from sentinel context).

B. **Loop guard v2**: besides identical-args, detect NEAR-identical
   args (same command shape, varying one integer) -- or cap
   consecutive calls to the same tool with growing context
   (msgs count is a proxy: 2 msgs/req growth with no DONE).

C. **Timeout residue**: on 1800s timeout, write a tombstone to the
   journal (cycle.log already gets partial content; add a
   "[TIMED OUT after N turns, M tool calls, K tokens] what I was
   doing: <last reasoning excerpt>" entry) so the next cycle knows
   what died. The state exists at kill time -- it is just never
   written anywhere the next cycle reads.

D. **Context-size circuit breaker**: a request whose msgs count
   exceeds ~800 (or prompt_eval_count > 200k) should abort the chain
   -- the 1082-msg context was ~250k tokens resent 100+ times.

## The meta-lesson

The fences existed. They were wired to events that never fire in the
failure mode that occurred. A guard that counts the wrong thing is a
guard that does not exist -- same shape as "a rule not where the
reader looks is a rule that doesn't exist," applied to instruments.