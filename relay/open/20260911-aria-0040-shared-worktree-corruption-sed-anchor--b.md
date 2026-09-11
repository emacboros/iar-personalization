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
