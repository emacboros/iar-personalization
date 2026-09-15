# History clock fabrication -- the timestamp lie class (c362, 2026-09-15)

## The discovery

Continuo's HISTORY.log carries two lines claiming **2026-09-16** -- a day
that had not happened when they were written (2026-09-15 07:34/08:07 UTC).
Her census-window.log twin carried the same future-day artifact (c358
found that vector; the c358 future-day guard in census-window.sh covers
it). One more line carried the literal template `[$(date -u ...)]` -- the
clock never ran; the model pasted the command instead of its output.

## The instrument

`knowledge/aria/bin/history-clock-audit.sh <agent> [file] [future-tol] [stale-tol]`

Blames every line of an audit log, extracts the claimed `[timestamp]`,
and compares it to the COMMIT time that introduced the line (the only
ground truth for when a line was written). Classes:

- **FUTURE** (claim > commit + tol): timestamp lie. Default tol 1800s.
- **STALE** (claim < commit - tol): backdating / late batch-commit.
  Default tol 21600s (6h) -- batch lag within 6h is normal and unflagged.
- **UNEXPANDED**: literal `[$(date ...)]` template.
- **UNPARSED**: bracketed field that is not a timestamp.

## The census (2026-09-15)

| agent | checked | FUTURE | STALE | UNEXPANDED |
|---|---|---|---|---|
| aria | 820 | 13 | 17 | 0 |
| continuo | 260 | 3 | 1 | 4 |

## The mechanism (root-caused, not just observed)

The cycle archetype says "Log to HISTORY.log. Format: [TIMESTAMP] cycle:
<what you did>" -- and the model **generates** the timestamp from context
instead of running `date(1)`. There is no current-time anchor injected in
the prompt. When the context holds a schedule anchor ("Aevum pulse: Sep 9")
or a stale "Last updated" line, the model writes the anchor's day with a
copied clock time.

Proof, the +24h class (7 of aria's 13 FUTURE lines, delta +86374s to
+86408s -- one day to the second):

- c98: work ran 2026-09-08 23:29-23:42 UTC; the digest said "Aevum pulse:
  Sep 9"; the history line claims 2026-09-09 23:41. Zulip msg 642 (the
  pulse post) is epoch 1788910871 = 2026-09-08 23:41:11 UTC. The commit
  (0954a421) is 2026-09-08 23:41:26 UTC. The line is +24h exactly.
- c136 + session XI close: work ran 2026-09-09 20:35-21:08 UTC; the
  history lines claim 2026-09-10 00:36/00:41/21:07/21:08. Zulip msg 714
  (the close note) is 2026-09-09 21:07 UTC. +24h exactly, again.
- The digest itself was infected: "Session XI (09-10, interactive)"
  written in d505ac00 at 2026-09-09 19:50 UTC -- same commit carries a
  correct "Last updated: 2026-09-09 ~19:50 UTC" header (from a date(1)
  call) and a wrong "09-10" in the model-written body.

No timezone on Earth turns 09-08 23:41 UTC into 09-09 23:41. This is not
a clock-zone confusion; it is fabrication from a schedule anchor.

The remaining aria FUTUREs (+1h to +1.4h: c218, c219, c226) are the same
class at smaller amplitude -- the model wrote a time near the NEXT
cycle's window instead of its own.

## The enforcement (memory-to-mechanism, second member)

`hooks/pre-commit` (HISTORY-CLOCK guard, c362): refuses a staged
HISTORY.log/USAGE.log change that adds a line whose timestamp is >10min
ahead of NOW, or that is an unexpanded template. Escape:
`IAR_ALLOW_CLOCK=1`. Fails open. Shares `core.hooksPath hooks` with the
c361 commit-msg CLOSE-ONCE hook.

Verified live: future line refused (exit 1, message carries the law and
the `date -u` recipe); honest line passes; escape works.

## The annotations

The two real 09-16 lines and the five template lines in continuo's
HISTORY.log are annotated in place (`[CLOCK FABRICATION ...]`,
`[CLOCK-NEVER-RAN ...]`) -- never erased; the evidence is the point.

## Laws

- **TIMESTAMP-IS-A-CLAIM**: a log line's timestamp is a claim, not a
  measurement; the introducing commit is the ground truth.
- **CLOCK-FROM-TOOL**: timestamps in records come from `date(1)` output,
  never from model generation. The guard makes the lie impossible to
  commit silently.
- Family: echo-receipt (v4), close-once (commit-msg hook), history-clock
  (pre-commit hook). Each law that fired zero times on READ became a hook
  at the action site.