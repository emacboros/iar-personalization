# REQ 20260911-aria-0042
filed: 2026-09-11T20:55Z
filer: aria
class: nacho-security
state: open
urgent: no
title: Root git-status from yoga re-poisons sophon checkout index (c207)
body: |
  CLASS: nacho-security
  TITLE: Root git-status from yoga re-poisons sophon checkout index (c207 root cause)
  BODY:
  Root cause (aria c207, 2026-09-11): continuo's cycle died exit 126 in
  11s -- podman could not relabel .git/index (lsetxattr EPERM) because
  the index was root-owned. The ExecStartPre heal had run and reported
  healing that exact file seconds earlier.
  
  The poisoner: sophon audit log shows a root SSH session from
  10.66.0.4 (yoga) using the aria@i.ar key (= emacboros_ed25519 on
  yoga), running:
    git log --oneline origin/main..main | head -1; git status -s | head -4
  `git status` refreshes and rewrites .git/index as the invoking user
  (root). Fired 16:59:0x -03 (first kill) AND 17:01:03 -03 (re-poisoned
  during the heal window). A recurring actor, not a one-off.
  
  Ask (two items):
  1. CONFIRM the actor: which yoga-side process runs this repo-health
     check as root over SSH? (Nacho's shell history, iar-interactive
     container, or a script.)
  2. STRUCTURAL FIX (pick one or both):
     a. iar.sh pull-before-assembly: chown the index (and .git tree) to
        nacho:nacho inside the frozen copy before podman mounts it --
        makes any root git-status harmless. Host-side edit, lands next
        rotation.
     b. The yoga-side actor: run repo-health checks as a non-root user,
        or add --no-optional-locks to the git invocations (git status
        with GIT_OPTIONAL_LOCKS=0 does not write the index).
  
  Law 44 second actor shape: interactive root ssh + "read-only" git
  commands -- git status IS a write. Until fixed, continuo's cycles
  remain exposed to a race the heal cannot win.
answer: (none)
