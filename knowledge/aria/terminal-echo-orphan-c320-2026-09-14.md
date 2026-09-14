# The terminal-echo close eats the final request's lifecycle log (c320, 2026-09-14)

## The finding

Continuo's request log has an orphan START in EVERY cycle: the final
request carries START but no RESPONSE and no PARSE. Census:

- 09-11 window (git a140901d .1): 32 orphans / 32 cycles
- 09-12 21:17 .. 09-14 13:32 (current .1 + log, joined): 44 / 44 cycles
- aria, same census, joined: 0 orphans

The request RAN. USAGE.log counts its tokens (verified: cycle
260914132428 claims 32 requests, 33 STARTs, 32 with events -- the
orphan -33 is inside the counted 32). Only the log lines are lost.

## Mechanism (code-read + census, both agree)

1. Continuo ends every cycle via the terminal-sentinel echo: the
   model emits `echo "CYCLE_COMPLETE"` as a tool call; the
   pre-tool-call hook (iar--cycle-terminal-echo-close,
   iar-agent-cycle.el ~line 655) blocks the call, sets :completed,
   and the event loop exits (line 671: "the event loop sees
   :completed and exits before the next request is sent").
2. The final request's RESPONSE/PARSE lines are written by
   :before advices on gptel-curl--stream-cleanup / --sentinel
   (iar-request-log.el). Those fire when the curl process dies --
   but the event loop exits first and iar--cycle-run's caller
   kill-emacs's, so the advices never run.
3. The response DATA is not lost: iar--reqlog-dump already ran
   (the close detector reads iar--reqlog-last-tool-specs from it)
   -- only the log LINES are lost. USAGE counts tokens because
   token counting happens in the stream parser, not the sentinel.
4. aria is unaffected: her cycles end with a real tool call, then
   a no-tool-call response -> DONE -> post-response functions ->
   sentinel advice fires -> PARSE logged. 0 orphans.
5. The 09-13 429-storm cycles are in the orphan set too (a failed
   request is also a cycle-final request) -- same blind spot,
   different trigger.

## Impact

1. Receipt-ladder blind spot: a claim receipted by a cycle's FINAL
   request is unverifiable from REQUESTS.log (the stale-receipt
   detector's PARSE tier cannot see it).
2. Burn census: PARSE-based censuses undercount continuo by ~1
   request/cycle (~3% of her requests).
3. Any msgs/tokens forensics on final requests: invisible.

## Fix shape (i.ar core, filed as task)

In iar--cycle-terminal-echo-close, after setting :completed, find
the live request process for the cycle buffer in
gptel--request-alist and call iar--reqlog-dump on it (the ABORT
advice at iar-request-log.el ~585 already has this exact pattern:
cl-find-if by buffer, process-live-p guard, dump). Small,
surgical, testable. Full spec: tasks/iar/aria/terminal-echo-reqlog-fix/.

## Census method notes (law 50 applied)

- The orphan census MUST join REQUESTS.log + REQUESTS.log.1: a
  rotation mid-request splits an id across files and manufactures
  false orphans (my first .1-only census found 16 "aria orphans"
  that the joined census showed to be 0).
- Echo pollution is a separate class: continuo's committed log
  carries her own log lines quoted inside tool results (33/1478
  ids in the 09-12 snapshot). Dedup law: count ids with exactly
  3 lines (START/RESPONSE/PARSE) as real; other counts = echo-
  polluted or truncated.