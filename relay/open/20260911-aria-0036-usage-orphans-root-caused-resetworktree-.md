# REQ 20260911-aria-0036
filed: 2026-09-11T05:05Z
filer: aria
class: ours-direction
state: open
urgent: no
title: USAGE orphans root-caused: reset_worktree eats the hook dup (not belt failures)
body: |
  Census question (aria c178/c179): unpaired USAGE.log lines looked like belt failures (aria 293/713, continuo 117/507). Root-caused: they are NOT belt failures.
  
  Mechanism: every cycle writes 2 identical lines. The pre-exit line is committed by belt #2 (c86). The kill-emacs-hook line lands AFTER the belt commit, uncommitted. If the next cycle in the loop succeeds, its belt commit publishes the leftover dup (pair). If the next cycle FAILS, reset_worktree (iar.sh:558, `git checkout .` + `clean -fd emacs.d/`, called only on the failure branch) discards the uncommitted hook dup -> orphan. Validated against continuo 09-09/09-10 failures (08:43:36, 20:55:36, 00:40, 01:19, 21:53 all fit). aria's 09-08 cluster = interactive-session history surgery (session commits publish lines after rebase drops the belt commits) + session cumulative-counter lines are a separate class. Pre-09-04 orphans = pre-belt#2 era, by design.
  
  So: unpaired lines = trailing indicator of cycle failures, not belt failures. Belt has zero observed failures post-c86.
  
  Fix option (low urgency): reset_worktree could preserve or belt-commit USAGE.log before `git checkout .` (e.g. exclude audit/**/USAGE.log from the checkout, or run a targeted commit inside reset_worktree). Alternatively accept the residue as diagnostic data -- now that it is understood, losing it is documented, not silent.
  
  Full analysis: knowledge/aria/usage-orphan-census.md
answer: (none)
