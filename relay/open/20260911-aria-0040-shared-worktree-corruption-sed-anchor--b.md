# REQ 20260911-aria-0040
filed: 2026-09-11T11:59Z
filer: aria
class: ours-direction
state: open
urgent: no
title: shared-worktree corruption: sed-anchor + backup-order + reset-before-cycle
body: |
  CONTEXT: continuo c190 (10:55 UTC cycle) attempted to implement the
  context-budget rule (msgs >= 400 stop) by sed-editing
  emacs.d/init.d/tool-call/iar-request-log.el and
  emacs.d/init.d/agent/iar-agent-cycle.el in the SHARED sophon
  checkout. Her sed anchored on '/defvar iar--reqlog-epoch/a' which
  matches line 82 -- the line that OPENS a multi-line defvar form
  (82-89). The append landed INSIDE the form: nested defvar, "Too many
  arguments" at load. My next cycle (aria, 11:35) died in 12s, exit
  255, at init load time. Reproduced all three sed variants in
  /tmp/sedtest; clean file loads fine.
  
  SECOND ORDER FAILURE: her .bak was taken AFTER the first corrupting
  sed, so both "restores" (11:33:04, 11:33:40) restored the corruption.
  Her grep verification showed the intended lines present (they were --
  nested), so she parked believing DONE. The file healed only because
  MY cycle failed and iar.sh's reset_worktree ran on the failure
  branch (git checkout . + clean -fd emacs.d/).
  
  ASK (machinery hardening, i.ar repo -- yours to ratify or hand back):
  1. reset_worktree BEFORE every cycle, not only after failures
     (iar.sh loop: call it at cycle start; the failure-branch call can
     stay). Two agents share one checkout; either agent's uncommitted
     edits are the other's floor.
  2. Consider a preflight check in run_cycle: if `git -C $REPO_DIR
     status --porcelain -- emacs.d/` is non-empty, reset before
     starting emacs (log it loudly).
  3. For continuo's machinery (I amended her STATE.md, signed): her
     request-log edits are NOT in the tree; redo with a load-verified
     method. The laws: anchor seds on form-CLOSING lines, backup
     BEFORE first edit, verify with load/byte-compile/bash -n -- never
     grep alone.
  
  Full anatomy: knowledge/aria/cross-agent-worktree-corruption-2026-09-11.md
answer: (none)
AMENDMENT 1 (2026-09-11 ~12:25Z, aria c191 -- the reset-before-cycle
ask is now URGENT-BY-EVIDENCE, and the pull-before-assembly ask
(0034) is the same patch site):

Continuo's 12:18Z cycle died exit 1 (thinking-loop truncation, 22
requests, 642k tokens, turn-1 death). The failure branch ran
reset_worktree AFTER her death -- the exact pattern this filing
proposes to fix. While she was dying, MY cycle (11:42-12:05) was
live in the same checkout; her reset at 09:18 -03 (12:18Z) landed
between my writes. No corruption this time (my writes were
committed before her reset), but the race window is structural:
two agents, one checkout, resets and writes interleaving on
failure boundaries only.

ALSO: my 12:18Z cycle found the digest twin DIVERGED -- c190's
pending-marker commit (3cbdfc2c) touched the TOP-LEVEL
DIGEST.md only, while the live reader (iar--read-memory-file-full)
reads the AUDIT copy. The twin was stale at the c186 state for one
full rotation. Fixed this cycle (3db8c157 + ccdff3d5, verifier
FAIL=0). Law: the top-level DIGEST.md is a SYNC TWIN, never the
write target; write audit, then copy.

AMENDMENT 2 (2026-09-11 ~13:01Z, aria c192 -- ASK 1 IMPLEMENTED):

Commit 2e9d542 (i.ar repo, pushed sophon-bare + rammstein):
reset_worktree now runs BEFORE every cycle (after
cleanup_container, before run_cycle), in addition to the
failure-branch call. Sophon checkout verified at 2e9d542, tree
clean, file owned by nacho, bash -n clean. The next two rotations
are the live-verification window (law 40: deploy -> watch the next
real cycle -> read the actor's REQUESTS.log/service log for the
"Resetting working tree to clean state" line at cycle start).

Note on ask 2: the preflight status check is now REDUNDANT --
reset-before-cycle subsumes it (the reset IS the preflight). If
you want the loud log line for a dirty tree at start, it lives in
reset_worktree's warn already. I did not add a second check.

Ask 3 (her edit method) unchanged -- her domain.
PROPOSED (aria, session XV -- NOT A NACHO RULING; pending, 2026-09-11 ~14:35 UTC, interactive w/ Nacho):
(1) reset-before-cycle (2e9d542): RATIFIED -- keep. Live-verification
window (next two rotations reading the reset line) continues.
(2) pull-before-assembly (0034's one-liner in rotate.sh): RATIFIED in
principle; Nacho applies with the rotate.sh iar.sh-copy fix (0041)
in the same touch.
(3) sed-anchor laws for continuo (form-closing anchors, backup
before first edit, load-verify not grep): ratified as her method
law. Ask 3 remains her domain.
