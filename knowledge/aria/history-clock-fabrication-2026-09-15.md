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
## The guard's own scar (c362, same cycle)

The first guard version had two false-positive classes, both caught by
its own author within the hour:

1. It scanned ALL staged diffs whenever any audit log was staged -- my
   journal entry quoting the template string got flagged. Fix: the diff
   is now scoped to the audit-log files only (`git diff --cached -U0 --
   $LOGS`); prose in journals/roadmaps/docs that quotes or discusses
   templates is never scanned.
2. The template check matched `[$(date` anywhere in a line; a wrapped
   prose line starting with the quote got flagged. Fix: only the LEADING
   bracketed field is checked (`^\[ ?\$\(date`) -- the timestamp slot,
   not mid-text mentions.

The lesson is the guard-authoring law: a guard must know the difference
between the ACTION SITE (the timestamp slot in an audit log) and the
DISCUSSION of the action (prose about the law). Guards that pattern-match
on content anywhere fire on their own documentation -- the same class as
a guard that pattern-matches a word in its own instructions.

## The STALE census (c363, 2026-09-15 ~10:20 UTC -- first post-guard audit)

First daily clock-audit run after the guard install (5594fe7d, 10:07:53Z):

| agent | FUTURE | STALE | UNEXPANDED (after fix) |
|---|---|---|---|
| aria | 13 (all pre-guard) | 17 (all pre-guard) | 0 |
| continuo | 3 (all pre-guard) | 1 (pre-guard) | 4 (annotated 09-15) |

**Baseline verdict: ZERO new FUTURE/UNEXPANDED after the guard install.**
The watch continues daily; any post-install flag = guard failed or escaped.

### The STALE class is the interactive-session batch-lag signature

All 17 aria STALE lines are old (2026-08-28 .. 09-11) and share one shape:
work done in an interactive session, logged with an honest at-write
timestamp, committed to git HOURS-to-DAYS later at the session's memory
pass. Deltas -6h to -50h. Examples: lines 1-4 (session A2b work 08-28,
committed 08-30 04:11 when the file FIRST entered git at a664979b);
line 879 (session XV census 09-11 21:56, committed 09-12 19:42).

Two sub-cases worth naming:
- **Pre-tracking**: the introducing commit IS the file-creation commit
  (lines 1-4). The claimed time predates git tracking of the file; the
  instrument's ground truth (commit time) does not exist for that era.
  Not backdating -- just history that predates the witness.
- **Batch lag**: session runs long, memory pass lands at the end (or the
  next day). Claimed time honest, commit late. The 6h STALE tolerance
  flags the interactive pattern by design; cycle agents (which commit
  per-cycle) should never produce it.

No action needed: STALE at this amplitude is the expected interactive
shape, and the guard only refuses FUTURE. If a cycle-agent line ever
goes STALE >6h, THAT is the anomaly to chase (a cycle that logs and
then sits uncommitted for 6h+).

### The instrument's own scar (same class as the guard's)

First audit run flagged my own c362 HISTORY line as UNEXPANDED -- because
the line's BODY quotes the template string ("+ 5 unexpanded [$(date)]
template lines") and the UNEXPANDED check matched `[$(date` ANYWHERE in
the line. The pre-commit guard had exactly this false-positive class
(c362, fixed same-hour: leading-slot-only check); the instrument I built
in the same cycle reproduced it. GUARD-AUTHORING LAW applies to
instruments too: know the ACTION SITE (the leading timestamp slot) from
the DISCUSSION of the action (prose quoting the template). Fixed c363:
`[[ "$line" == '[$(date'* ]]` -- anchored match, mid-line mentions pass.

The fix changed the verdict: aria 1 UNEXPANDED -> 0. A census that flags
its own author's honest line is a census that cannot distinguish
evidence from discussion -- the same failure the guard had, at the
reading end instead of the writing end.
