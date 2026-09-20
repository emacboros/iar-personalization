# REQ 20260918-aria-0082
filed: 2026-09-18T05:28Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: audit watch on tasks/ tree (unlogged-deleter blind spot)
body: |
  FINDING (aria c45, 2026-09-18 ~05:30Z): the unlogged-deleter hunt closed
  with the actor unresolved but the STRUCTURAL gap identified.
  
  Timeline (all UTC, sophon local = -03):
  - 04:06:36 continuo cycle ends (exit 1), commits d1b3646c
  - 04:06:49 wrapper push, 04:06:59 reset_worktree (checkout . = "Updated
    1 path" = continuo's post-commit LAST-CYCLE.txt; clean -fd emacs.d/
    removed 4 untracked emacs.d files)
  - 04:07:01 aria cycle starts; pre-cycle pull "Already up to date";
    reset "Updated 0 paths" => task dir tasks/iar/aria/
    sentinel-nil-string-fix-c40 was PRESENT and clean at cycle start
    (a deleted tracked dir would have been restored = 2 paths)
  - 04:07-04:10:44 aria's commands fully enumerated from REQUESTS.log:
    pulls, keyscans, digest-twin, gptel-fork reads/tests, journal+history
    commits (scoped adds), curls, config reads, python3 edit of
    tasks/iar/aria/ROADMAP.org ONLY. NO rm, NO remove_task, NO command
    touching the task dir.
  - 04:10:44 aria's `git commit -am` swept the DELETION of the task dir
    into history (4796fb15). Deletion window: 04:07:01-04:10:44Z.
  - continuo's next cycle (04:16:54-04:27) is also clean (no remove_task,
    no rm; her read_task walks HER tree only, would never see aria's dir).
  - sophon audit rules watch audit/ and .git ONLY (-w .../audit -p wa,
    -w .../.git -p wa). tasks/ is UNWATCHED and also gitignored
    (untracked) => the deletion had NO witness except the -am sweep.
  
  ASK: add an audit watch on the tasks tree so deletions there are
  witnessed:
    -w /var/home/nacho/repos/iar-personalization/tasks -p wa -k aria-audit
  (and mirror in roles/base + augenrules like the devnull-watch rule).
  Volume note: tasks/ is low-traffic (task tree edits only), so the
  journal-rate risk is negligible vs the devnull-watch lesson.
  
  Also filed as knowledge: a tree that is neither watched nor tracked
  has no witness -- the c45 lesson.
answer: (none)
