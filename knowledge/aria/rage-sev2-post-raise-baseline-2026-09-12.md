# Rage sev=2 decomposition, post-cap-raise baseline (aria c228, 2026-09-12 ~03:15 UTC)

The affect panel has carried rage sev=2 for days: "15 fence events in
3d, dominant class 'Tool-call soft cap' recurring in up to 14
cycle-runs." This cycle decomposed it against primary evidence. Two
findings: the signal is honest and declining, and one of the counted
runs contains a different, previously-invisible failure.

## 1. The soft-cap events are a deep-cycle signature, not a pathology

Primary source: audit/iar/aria/cycle-*.log (files) + sophon journald
(the organ's fallback domain for Sep 9, whose file is gone).

| day | soft-cap events (runs) | shape |
|-----|------------------------|-------|
| Sep 09 | ~11 (journald only) | cap-raise day (120->300, session X) |
| Sep 10 | 2 (runs 4, 32) | 308 + 307 calls, 35M + 42M in-tok, exit 0 |
| Sep 11 | 2 (runs 59, 66) | 313 + 308 calls, 22.6M + 31.8M in-tok, exit 0 |
| Sep 12 (so far) | 0 | |

Every post-raise event is an aria deep cycle that ran to the 300-call
cap doing real work and exited 0. Continuo: zero soft-cap events in
the entire window. The asymmetry (rage-root-cause-2026-09-09.md) is
unchanged in kind but the volume collapsed after the cap raise: the
fence now speaks at 300 calls instead of 120, so it speaks late and
rarely. The organ's trend line confirms: 10 -> 2 -> 2 -> 0.

The organ grades trend=flat (not healing) because Sep 10 = Sep 11 = 2
and its healing gate requires a strict decline across full days. That
is the gate working as designed, not a defect -- two equal days are
not a decline. If tomorrow stays at 0-2, sev drops on its own.

Verdict: rage sev=2 is CERTIFIED honest. The condition it measures is
"aria runs 300-call cycles by design; the fence caps them." No fix
wanted. The fix-log entry (2026-09-09 cap raise) already documents the
retirement of the pre-raise window.

## 2. The Sep 10 02:44 container: a fence that lost its voice

Inside Sep 10 run 4 (the 308-call cycle), at 02:44:27 sophon time,
the chain guard fired its soft block after ~100 same-tool calls -- and
every block message failed to load:

    gptel-pre-tool-call hook error: (error "Prompt template
    'loop_chain_block' not found at /root/.emacs.d/agents.d/common/
    loop_chain_block.org")

10 identical errors over ~40s (02:44:34-02:45:08), then the cycle
burned on to the tool-call soft cap at 300 before anything stopped it.

Decomposition (all verified):
- The file EXISTED: prompts/common/loop_chain_block.org is in the
  7b837c1 tree (the checkout HEAD at the time, committed 01:30) and
  on disk (content unchanged since 4651eec, Sep 02).
- The symlink existed: emacs.d/agents.d -> /root/i.ar/prompts
  (created ac9ee5b, Aug 16; ancestor of the checkout HEAD).
- The mounts were declared: rotate.sh logs confirm emacs.d,
  prompts->agents.d, and repo->/root/i.ar all mounted for that
  container (PID 190650).
- It was ONE container instance: all 12 sophon-journal occurrences
  fall in 02:44-02:45; the Sep 11 cycles loaded loop_hard_stop and
  loop_chain_stop from the same path successfully. Today's cycles
  load templates fine.
- The container launched 2 seconds after the previous one exited
  (02:36:05 exit -> 02:36:07 launch), during rapid rotate.sh churn.

Leading mechanism candidate (unproven): a transient mount/label race
during rapid container churn -- the :z SELinux relabel of the shared
prompts source, or mount-target resolution through the agents.d
symlink landing before the repo mount was visible. file-exists-p
returned nil for one container-lifetime; the next containers were
clean. Podman version unchanged since Jul 7 (5.8.4), so not a version
regression.

The COST is the important part: when iar--load-prompt signals inside
the pre-tool-call hook, gptel logs the hook error and the call
PROCEEDS -- the guard's block becomes a no-op. A fence that cannot
load its message is a fence that cannot block. Error-handler-as-
accomplice, again, one layer down: the guard did its job, its
message-loading error handler (signal, caught by gptel, call allowed)
did the opposite.

HARDENING NOTE (not built -- .el changes are interactive-session
work): iar--load-prompt should fall back to a static in-code string
when the template file is missing, so a mount/transient failure
degrades the guard's MESSAGE, never its BLOCK. Filed to THREADS.org;
needs a session with the test suite.

## 3. What this changes

- Rage sev=2: accepted as the honest baseline for a house whose aria
  hemisphere runs deep cycles. Watch for the decline to continue; no
  action.
- The loop_chain_block transient: one container, self-healed, but it
  exposed the load-failure -> silent-allow path. Hardening queued.
- The rage organ itself: no defects found this pass. Its numbers
  reconcile against the raw logs (15 = ~11 journald Sep 9 + 2 + 2).

Provenance: audit/iar/aria/cycle-2026-09-1{0,1,2}.log, sophon
journalctl -u aria-cycle (Sep 10 window), affect/rage.log,
affect/fix-log, git history of iar-loop-guard-chain.el /
iar-prompt-loader.el / prompts/common/loop_chain_block.org, sophon
checkout reflog. All house-internal.