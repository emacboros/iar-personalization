# iar.sh self-edit race (exit 127 after a successful cycle)

## Classification
[EXTERNAL DATA: none -- all primary evidence from sophon journal + git history]
Machinery finding, continuo cycle 21 (2026-09-03 ~19:50 UTC). New
failure class, distinct from exit-126 (SELinux relabel) and exit-255
(mid-edit truncation).

**UPDATE c56 (2026-09-04): the bundle item that claimed "iar.sh
copies itself to /tmp before exec" was a misdiagnosis -- rotate.sh
execs iar.sh in place (verified, /usr/local/bin/aria-cycle-rotate.sh
line 12, no copy step). This document's mechanism stands as the
real one. The full correction is folded at the end of this document.**

<!-- Full correction (c56) folded below; pointer file merged 2026-09-07 -->

# iar.sh /tmp-copy race -- root-cause CLOSED (c56, 2026-09-04)

## Status: the "self-edit race" hypothesis is DEAD. The real mechanism is
## bash incremental-read + in-place commit, already documented.

The bundle item said: "iar.sh copies itself to /tmp before exec" --
FALSE. Verified against primary evidence:

- rotate.sh (/usr/local/bin/aria-cycle-rotate.sh line 12) execs
  iar.sh DIRECTLY from the repo path:
    exec /bin/bash /var/home/nacho/repos/i.ar/utils/iar.sh ...
  No copy step exists anywhere in the chain.
- The Sep 3 12:03:14 event (exit 127, "line 1151: Cooldown: 60s
  before next cycle: command not found") is the documented
  incremental-read race in knowledge/iar/iarsh-self-edit-race.md:
  the RUNNING iar.sh's buffered fd offset landed mid-line after
  commit 30c5385 inserted a line upstream of the read head. Bash
  executed the bare string tail as a command -> 127.
- iar.sh md5 today == sophon checkout == e8d9850+30c5385 blob
  (4e26d2fe). No stale or corrupted file. bash -n clean. The
  cooldown branch never executes on MAX_CYCLES=1 -- the error was
  the read-head garble, not a real code path.

## What remains true
- The race class is real: the loop runner is hot while any cycle
  runs; a commit to the running script races the reader.
- Worst case unchanged: garble before write_last_cycle/tg_send
  loses the tombstone. Rare (iar.sh committed ~2x/3d from cycles).
- The documented fix options stand. Option 1 (run from a copy) is
  still the durable fix, but the edit is to rotate.sh's exec line:
  copy iar.sh to a versioned /tmp path and exec THE COPY.

## Corrected bundle item text
OLD: "iar.sh copies itself to /tmp before exec. A cycle that edits
iar.sh while another cycle is mid-exec runs the OLD copy silently."
NEW: "rotate.sh execs iar.sh in place; a cycle committing iar.sh
races the running reader (Sep 3 12:03 exit-127, mechanism verified
by reproduction, knowledge/iar/iarsh-self-edit-race.md). Fix: rotate.sh
copies iar.sh to /tmp/iar-$HASH.sh and execs the copy."

## Recurrence watch
Zero recurrences since Sep 3 12:03. The URGENT-on-recurrence trigger
stays. With the mechanism understood, a recurrence is diagnosable in
one journal pull (look for mid-line garble text naming any line).

## Census note (Sep 3 -> Sep 4 journal window)
2 systemd-level failures in ~21h (exit-126 10:22, exit-127 12:03),
both root-caused and documented. Since Sep 3 12:03: zero service
failures. The failure-reduction ask (Nacho msg 248) is being met by
mechanism, not luck: newline contract, belt #2, breaker, honest
preflight, chain convergence reset all landed in that window.

## The event (12:03:14 UTC Sep 3)
aria-cycle.service: continuo cycle 1 succeeded (exit 0, 153s, 29 tool
calls), then the MAIN PROCESS died with status=127 one second later:

    /var/home/nacho/repos/i.ar/utils/iar.sh: line 1151:
    Cooldown: 60s before next cycle: command not found

systemd recorded a service FAILURE for a cycle that had actually
succeeded. OnFailure tripwire fired; a telegram digest went to Nacho
for a non-failure. One false failure, zero lost cycles.

## Root cause (mechanism verified by reproduction)
The running iar.sh process (started 12:00:41) was executing from the
file when continuo cycle 8 committed 30c5385 (12:01:38) -- which
INSERTED one line (the write_last_cycle exit-2 fix, +82 bytes) into
utils/iar.sh at old-line 1113, in place.

Bash reads scripts incrementally with buffered reads; the fd offset
advances with execution. The insertion shifted every byte after
old-line 1113 down by 82. When the running process needed its next
read chunk (after the cycle ended, 12:03:14), the byte offset landed
mid-line inside the cooldown `info` line -- the `info ` prefix was in
the previous buffer, so bash executed the bare string
`Cooldown: 60s before next cycle` as a command. Command not found ->
127 -> set -e killed the process -> systemd saw failure.

Reproduced in /tmp (race6.sh): insert a line into a running script
while it sleeps; the next read chunk garbles mid-line and with
`set -euo pipefail` the process exits 127. Exit code and error shape
match the production event.

## Why the error text names the cooldown line
The cooldown branch (CYCLE=1, MAX_CYCLES=1) never EXECUTES on a
1-cycle run -- but bash had already buffered that region during loop
parsing. The garbled re-read hit the info line's tail. The line
number bash reports (1151) is its own offset accounting after the
edit, off-by-N from the real file.

## Why this is rare but structural
- iar.sh is committed from cycles ~2x in 3 days (30c5385, e8d9850).
- The race window is the tail of any cycle that commits iar.sh
  AFTER the commit: the runner process is still executing the file.
- Same class as the mid-edit .el exit-255 (scar: truncated read),
  but for the LOOP RUNNER itself -- the process that owns the cycle.
- The 12:03 event was benign-looking because the cycle had already
  succeeded. Worst case: the garble hits BEFORE the cycle's
  write_last_cycle / tg_send -- a real failure loses its tombstone
  and its telegram.

## Fix options (ranked, all interactive-session territory)
1. **rotate.sh runs a copy**: rotate.sh copies iar.sh to a versioned
   /tmp path (e.g. /tmp/iar-$HASH.sh) and execs THE COPY. One line
   in rotate.sh. Running processes keep their inode; edits to the
   repo file never touch the running copy. Cheapest, no
   trust-boundary change. (c56 correction: the edit target is
   rotate.sh's exec line, not a self-copy inside iar.sh.)
2. **Atomic replace in the commit path**: agents commit iar.sh via
   write-temp + mv (inode swap). Requires changing how every agent
   writes the file -- harder to enforce.
3. **Behavioral law**: never commit utils/iar.sh from a cycle (the
   file is hot while any cycle runs). Enforceable by guideline
   checker; weakest guarantee (depends on the model obeying).
4. **Bash reads whole file at start**: not possible; bash is
   incremental by design.

Option 1 is the durable fix and belongs in the interactive bundle
with Nacho (rotate.sh is infra, not cycle-editable).

## Standing law candidate
"The loop runner is hot while any cycle runs: a commit to the
running script is a race with the reader. Land runner-file changes
between cycles or run from a copy."

## Cross-references
- 30c5385 (the commit that triggered it) was itself a good fix --
  the exit-2 LAST-CYCLE gap it closed is real and stays closed.
- iar/exit126-root-ssh-push task: different mechanism (SELinux),
  same family (file-state vs container-start races).
- knowledge/iar/bare-repo-root-push-heal.md: root-push pollution,
  third file-state race class in the house.

## RECURRENCE 2026-09-11 10:09:37 UTC (aria c194) -- CONFIRMED LIVE, and the editor was me

The race fired again, 8 days after Sep 3. This time the full timeline
is reconstructable from primary evidence, and it closes the loop on
the "who edits iar.sh" question:

1. 09:46:31 -- rotation turn 690 (aria) starts. The running iar.sh
   (PID 3855075) parses from the pre-2e9d542 file (fae011c blob).
2. 09:57 -- aria's OWN CYCLE (c192) commits 2e9d542 (relay 0040
   ask 1: reset_worktree before every cycle, +488 bytes at offset
   ~43461) -- editing the script that was running her, in place.
   Same shape as Sep 3: continuo cycle 8 committed 30c5385 while
   the runner was hot.
3. 10:09:36 -- run_cycle returns; "Cycle 1 succeeded in 1384s
   (exit 0)" logs from PID 3855075.
4. 10:09:37 -- the parent bash resumes reading at its stored byte
   offset (~46000), which in the NEW file lands mid-line inside the
   failure-branch error() line ("-- stopping loop\""). Quote-imbalance
   cascade -> bare "Stopping" executed as a command ->
   "line 1179: Stopping: command not found" -> exit 127 ->
   systemd "Failed with result 'exit-code'" -> OnFailure fired.

Re-verified today by reproduction (/tmp shifttest + fragment
cascade): bash reads scripts lazily by byte offset; a mid-run edit
shifts what the running shell executes; the resumed parse cascades
through quote imbalance and executes string fragments as commands.
The reported line number (1179) is bash's offset accounting after
the shift -- off-by-N from the real file (line 1179 in the current
file is "fi"), same as the Sep 3 event (1151).

### What this recurrence adds to the Sep 3 record

- The "who" is now certain: cycle agents edit iar.sh from inside
  cycles (30c5385 = continuo c8; 2e9d542 = aria c192). Both times
  the edit was a GOOD fix landing while the runner was hot. The
  race is not caused by bad edits -- it is caused by editing the
  runner AT ALL from inside a cycle.
- The 2x/3d frequency estimate held: two events in 8 days
  (Sep 3, Sep 11), both on iar.sh commits from cycles.
- The "URGENT-on-recurrence trigger" in the recurrence watch
  above: this is the recurrence. Not urgent in the
  blocks-all-progress sense (the cycle succeeded; only the unit
  status lied), but the fix (rotate.sh runs a copy) is now
  DEMONSTRATED to be needed, not merely recommended.
- Amendment to relay 0041 filed (c194): the original filing said
  "after EVERY successful rotation" + "missing binary" -- both
  wrong; c193's census conflated this one event with four real
  failures the same day. One 127, one mechanism, known since Sep 3.

### Law 45 (candidate, c194)

The runner is hot while any cycle runs. A commit to the running
script is a race with the reader -- regardless of who edits or why.
The fix is structural (run from a copy), not behavioral (edit
discipline), because both known events were careful, good edits
that raced anyway.
