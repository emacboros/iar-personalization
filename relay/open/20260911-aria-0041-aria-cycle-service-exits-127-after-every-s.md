# REQ 20260911-aria-0041
filed: 2026-09-11T13:32Z
filer: aria
class: nacho-test
state: open
urgent: no
title: aria-cycle.service exit-127 ROOT-CAUSED: iar.sh self-edit race (amendment 1)

body: |
  # relay 0041 -- AMENDMENT 1 (2026-09-11 ~14:20 UTC, aria c194)

  ## ROOT CAUSE FOUND (and it is not a missing binary)

  The 10:09:37 exit-127 is the KNOWN iar.sh self-edit race
  (knowledge/iar/iarsh-self-edit-race.md, Sep 3 12:03 event), firing
  again -- and this time the editor was ME, inside my own cycle.

  Timeline (all sophon journal + git reflog, primary evidence):

  1. 09:46:31 -- rotation turn 690 (aria) starts. The running
     iar.sh (PID 3855075) parses from the pre-2e9d542 file.
  2. 09:57 -- MY CYCLE commits 2e9d542 (relay 0040 ask 1:
     reset_worktree before every cycle, +488 bytes at offset ~43461)
     -- editing the script that was running me, in place.
  3. 10:09:36 -- run_cycle returns; "Cycle 1 succeeded in 1384s
     (exit 0)" logs from PID 3855075.
  4. 10:09:37 -- the parent bash resumes reading iar.sh at its
     stored byte offset (~46000), which in the NEW file lands
     mid-line inside the failure-branch error() line. Quote-imbalance
     cascade -> bare "Stopping" executed as a command ->
     "line 1179: Stopping: command not found" -> exit 127 ->
     systemd "Failed with result 'exit-code'" -> OnFailure fired.

  Mechanism verified by reproduction today: bash reads scripts
  incrementally; a mid-run in-place edit shifts every byte after the
  insertion point; the running shell's next read chunk garbles
  (simulated in /tmp: line2 became a different string mid-run;
  fragment cascade reproduces "command not found" from quote
  imbalance).

  The reported line number (1179) is bash's own offset accounting
  after the shift -- off-by-N from the real file, same as the Sep 3
  event (line 1151). Line 1179 in the current file is "fi"; the
  error text is the garble, not a real code path.

  ## Today's full failure census (5 'Failed with result')

  - 01:02:58 -- real failure (continuo, exit 1)
  - 06:35:01 -- real failure (continuo thinking-loop truncation, exit 1)
  - 08:35:35 -- real failure (exit 255, mid-edit .el class)
  - 09:18:01 -- real failure (continuo, exit 1)
  - 10:09:37 -- THE RACE (exit 127, this amendment)

  Only ONE 127 today. The "after EVERY successful rotation" framing
  in the original filing was WRONG -- c193's census conflated the
  shift-bug with the four real failures. The pattern was one event,
  not a systematic post-chain break. There is no missing binary.

  ## The fix stands as documented (option 1, the durable one)

  rotate.sh copies iar.sh to a versioned /tmp path and execs THE
  COPY: running processes keep their inode; edits to the repo file
  never touch the running copy. One line in rotate.sh
  (/usr/local/bin/aria-cycle-rotate.sh, line 12 -- the exec line).
  Interactive-session territory (infra file, not cycle-editable).

  ## Self-correction note (the record keeping itself honest)

  c193 filed this as "after every successful rotation" + "missing
  binary in post-chain" -- both wrong. The amendment replaces the
  mechanism, the frequency claim, and the ask. The original body is
  preserved below for the audit trail.

  ---

  # ORIGINAL FILING (c193, 13:32 UTC) -- SUPERSEDED by the above

  Every successful aria-cycle rotation ends with the unit reporting
  failure:

  ```
  Sep 11 10:09:36 ... Cycle 1 succeeded in 1384s (exit 0)
  Sep 11 10:09:37 systemd[1]: aria-cycle.service: Main process exited, code=exited, status=127/n/a
  Sep 11 10:09:37 systemd[1]: aria-cycle.service: Failed with result 'exit-code'.
  ```

  iar.sh itself exits 0 (the "Cycle 1 succeeded" line). The 127
  appears between the script's success log and the unit teardown.
  127 = command not found -- something in the ExecStart chain
  (aria-cycle-rotate.sh exec's iar.sh; the unit may also have
  ExecStopPost/ExecStartPost referencing a missing binary) exits 127
  AFTER the main work.

  Impact: cosmetic today (rotations continue fine) but it poisons
  semantics: every rotation looks failed to OnFailure hooks,
  monitoring, and `systemctl is-failed`. If you ever add
  OnFailure=notify, it will fire on every success.

  Ask: one look at the unit + rotate script tail: find what exits
  127 (likely a missing binary in a post-chain), fix or silence.
PROPOSED (aria, session XV -- NOT A NACHO RULING; pending, 2026-09-11 ~14:35 UTC, interactive w/ Nacho):
RATIFIED per amendment 1 (c194): root cause = iar.sh self-edit race
(2e9d542 shifted byte offsets mid-run; one event, not systematic).
Fix = rotate.sh execs a versioned /tmp COPY of iar.sh (running
processes keep their inode). Nacho applies the one-line change with
the 0034 pull-before-assembly line in the same touch.
