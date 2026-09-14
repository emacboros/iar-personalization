# Dead-cycle guard -- the 1800s idle burn (c326, 2026-09-14)

## The finding

Continuo's 09-13 quota-storm census, re-derived from her REQUESTS.log
with the clock law applied (cycle-log timestamps are sophon LOCAL
-03; REQUESTS.log timestamps are UTC):

- 00:00-07:43Z: 10 cycles succeeded, normal work, journal+history written.
- 08:25Z-23:33Z: **16 cycles, all exit 1, each exactly 1815s.** Each
  cycle: 1 request -> 429 in <1s -> "Cycle request FAILED (strike 1/3)"
  -> "No active requests for 1800s -- stalled, exit 1". 16 x 30min =
  **8 hours of sophon wall-clock** spinning on requests that could
  never succeed.
- 00:27-02:03Z Sep 14 (post-reset): 4 cycles succeeded (24-33 tool
  calls each, 574k tokens in the first).

## The mechanism

1. 429 arrives -> gptel FSM ERRS -> `iar--cycle-post-response-handler`
   called with start==end -> strike 1/3 -> not completed (needs 3).
2. gptel's stream-cleanup removes the failed entry from
   `gptel--request-alist` -> alist empty -> event loop sees no active
   request -> idle timer starts.
3. Nothing re-sends: gptel re-sends only after a TOOL RESULT, and a
   failed request produces none. The strike counter can never reach 3.
4. 1800s later: "stalled, exit 1". The cycle burned half an hour
   waiting for a successor that was structurally impossible.

The 3-strike abort assumed failures RETRY. The 2026-08-30 storm fix
(correctly) killed blind re-sends -- which made single-failure cycles
unretryable by construction, and turned the stall window into a
guaranteed 30-minute tax on every quota-wall cycle.

## The fix (i.ar 2eb3846)

`iar--request-successor-live-p`: non-nil if any FSM in
`gptel--request-alist` is non-terminal (entries are `(key fsm . cleanup)`,
fsm = cadr -- the c311 per-fsm attribution taught the shape) or the run
buffer has a live process. In the FAILED REQUEST PATH of both the cycle
and one-shot post-response handlers: strike counted, then if no live
successor -> completed + exit 1 immediately. The 3-strike abort remains
for paths where a re-send actually happens.

Cost of the bug class: silent, invisible in any single cycle's log
(each cycle honestly reported "failed in 1815s"), only visible as a
pattern across 16 cycles. The census that saw it was the per-cycle
request count: 1 request, 1815 seconds, 16 times.

## Test-shape scar (law 39 again, a new flavor)

Two pre-existing tests (test-cycle-exit-code-*-region-only) were
passing for the WRONG reason: their fixture ended with a newline, so
`(line-beginning-position)` at point-max == point-max -- an EMPTY
region -- which routed them into the FAILED path (strike 1, not
completed) instead of the success path they claimed to pin. My guard
completes on that path, exposing the wrong-reason pass. Fix: fixtures
without trailing newline + continue prompt + gptel-send stub, so they
now exercise the real success path. A test that passes for the wrong
reason is a fixture lying about production shape (law 39 again, in
test clothing).

## Verification

- Suite 1273/1273 green (3 new tests: lone-failure ends; live-delegate
  waits; strike-3 still ends).
- Live verification pending: continuo's next 429 (whenever the wall
  re-hits, predicted Sun 09-20 ~04-12Z) should exit 1 in seconds, not
  1815s. Watch her cycle log for "Request failed with no live
  successor -- ending cycle".
- Pushed: 2eb3846 to origin (rammstein) + sophon-bare. Sophon checkout
  picks it up via pull-before-assembly on her next cycle.