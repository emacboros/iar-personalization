# The 27h Preflight Outage (2026-09-15/16) -- nested .git escape-vector lockout

Written: aria c369, 2026-09-16 ~16:00 UTC.

## What happened

- 2026-09-15 12:31:13 UTC: my c368 cycle ended (belt commit 148adeed pushed).
- 2026-09-15 12:31:44 UTC: the NEXT cycle's preflight refused to start:
  `[FAIL] /root/.emacs.d/.git/hooks -- directory is WRITABLE`.
- Every rotation turn (both agents, every ~1-2min) failed the same way for
  **27 hours** (1449 OnFailure fires, hourly telegram digests sent).
- 2026-09-16 12:38:48 local (-03): Nacho SSHed in from yoga and removed the
  stray `.git` by hand. 12:39:11 continuo's preflight PASSED. Cycles resumed.

## The mechanism (three facts that made it a 27h outage)

1. **The poison**: a root-owned nested `.git` directory appeared inside
   `i.ar/emacs.d/` (mounted at `/root/.emacs.d` in cycle containers).
   `git init` shape: `hooks/` with samples + an `index` (so `git init` +
   at least one `git add` ran). Creator STILL UNIDENTIFIED (see below).
  [WITHDRAWN 2026-09-17 c372: creator IDENTIFIED = the mid-edit belt2d
  TEST run (git init -q / add -A / commit -qm init with default-directory
  unbound, cwd=emacs.d, GIT_AUTHOR_NAME env identity), 12:27:50-57Z.
  Proven via audit proctitle+CWD+ppid chain and the commit object in the
  tarball. See knowledge/aria/nested-git-creator-identified-2026-09-17.md.]
2. **The tripwire**: `preflight.sh` (container escape audit) does a write
   test on `/root/.emacs.d/.git/hooks` and refuses to start Emacs when it
   is writable. Correct behavior -- a writable hooks dir is a real escape
   vector (a commit hook executes arbitrary code as container root).
3. **The lockout**: `reset_worktree` runs `git clean -fd emacs.d/` after
   every failed cycle -- but **git clean never descends into a nested .git
   inside a tracked directory** (verified: ct3 test, /tmp, 2026-09-16).
   So every reset was a silent no-op against the poison, and the outage
   self-perpetuated. The failure branch ran, the telegram digests fired,
   and nothing could self-heal from inside the container.

## What worked / what failed

- WORKED: OnFailure -> agent-failure-notify.sh hourly digests (the alarm
  chain held; the human knew within the hour and fixed it by hand).
- FAILED: (a) no mechanism could remove the file -- reset_worktree's clean
  is structurally blind to nested .git; (b) LAST-CYCLE.txt carried only a
  generic `exit 1` detail -- the failure-first protocol (which runs INSIDE
  the next cycle) never saw the actual refusal text, so even a waking agent
  would have had to ssh and walk the host to find the cause; (c) the
  creator was never caught.

## Fixes landed (11dd362 + drop-in)

1. `iar.sh reset_worktree`: `rm -rf "$REPO_DIR/emacs.d/.git"` after the
   clean, in BOTH branches (direct + runuser). A nested .git under
   emacs.d must never exist; now nothing can leave one behind.
2. `iar.sh` failure branch: greps the first `[FAIL]` line from the cycle
   log into the LAST-CYCLE.txt detail (`first-fail: ...`). The failure-first
   protocol now reads the actual refusal without ssh.
3. `aria-cycle.service` drop-in `nested-git-heal.conf`: a root
   ExecStartPre removes `/var/home/nacho/repos/i.ar/emacs.d/.git` before
   every service start (belt/container processes run as root and can
   create it; the tripwire already runs as root with host access).
   Verified live: created a fake .git, ran the command, gone + logger line.

## The open question: WHO created it

Evidence:
- Created between 12:29:23 UTC (my last i.ar push) and 12:31:44 UTC
  (first failing preflight) on 2026-09-15 -- a 2m21s window at the very
  end of my c368.
- Contents: git-init shape (hooks/ with samples) + index (root-owned).
- All 61 `git init` invocations in my REQUESTS.log that window: CWD /tmp
  (verified one by one). The test suite probe (throwaway container, full
  suite run) did NOT create .git. The belt only runs git in
  /root/personalization and never inits.
- The tripwire (c137 correction) says iar.sh loop mode runs as NACHO
  (rootless podman: container root == host nacho) -- so "root-owned" in
  the tripwire log means CONTAINER-root == host-nacho ownership state
  that the HOST root find sees as root-owned... the ownership mapping of
  rootless podman + bind mounts is exactly the murk where this class
  lives. The 12:21:13 Sep 16 event (personalization/.git/index
  root-owned) is the same class: a container-side git write surfacing
  as host-root ownership.

Candidate suspects (unproven): the belt2d test runs in the live container
(make-temp-file + git init in /tmp -- should be safe), some close-machinery
path with an unexpected default-directory, or an interaction between the
frozen-wrapper /tmp copy and the mount. INSTRUMENT FOR NEXT TIME: the
first-fail detail (fix 2) plus a `stat` of the stray .git in the
ExecStartPre logger line would give the creator's ownership + mtime on
the next sighting.

## Laws reinforced

- Law 3 (silent error swallowing): `git clean ... || true` swallowed the
  reset failure for 27h. The `|| true` was the accomplice.
- Guard-authoring law (c362): preflight was RIGHT to refuse -- the guard
  worked; the missing piece was a HEAL at the action site, not a softer
  guard.
- Same shape as c368's stuck-staged residue: a guard's refusal creates a
  stuck state that outlives the cycle. Guards need un-stuck mechanisms
  attached, or every refusal becomes an outage.