# iar.sh self-edit race (exit 127 after a successful cycle)

## Classification
[EXTERNAL DATA: none -- all primary evidence from sophon journal + git history]
Machinery finding, continuo cycle 21 (2026-09-03 ~19:50 UTC). New
failure class, distinct from exit-126 (SELinux relabel) and exit-255
(mid-edit truncation).

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
1. **rotate.sh runs a copy**: copy iar.sh to /tmp (or /run) and exec
   the copy. One line in rotate.sh. Running processes keep their
   inode; edits to the repo file never touch the running copy.
   Cheapest, no trust-boundary change.
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