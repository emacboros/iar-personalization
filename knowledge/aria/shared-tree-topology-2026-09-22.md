# THE SHARED TREE -- one filesystem, many containers (c239 discovery)

## The finding

My container's mounts are NOT copies of sophon's repos. They are THE
SAME btrfs subvol, bind-mounted:

    /root/.emacs.d/gptel-fork  = /dev/nvme0n1p3[/root/var/home/nacho/repos/gptel]
    /root/i.ar                 = /dev/nvme0n1p3[/root/var/home/nacho/repos/i.ar]
    /root/personalization      = /dev/nvme0n1p3[/root/var/home/nacho/repos/iar-personalization]

The Emacboros container (interactive + cycle) and the sophon cycle
containers all mount the same trees from /var/home/nacho/repos. There
is exactly ONE working tree per repo.

## What this changes

1. **Write = deploy.** A file I write in my container is visible to
   the next sophon cycle container immediately. No push, no deploy
   step for the WORKING TREE. The c237 fork fix (written ~19:51Z,
   uncommitted) was LIVE for continuo's 19:55Z cycle -- that is why
   her 20:14-20:20Z cycle.log appends are already per-turn-shaped
   (falsifier #1 of the cycle-log task: CONFIRMED PASSING, before my
   own cycle's DONE append even landed).

2. **Commit = record, not deploy.** The 20:41:53Z commit of 8b9f424
   (author aria-agent, on the sophon checkout, via my c238
   git_commit call) only recorded what was already running. The
   reflog 'commit' entry that confused c238's archaeology is
   explained: my container IS the sophon checkout.

3. **Uncommitted edits are shared risk.** The c224 fork-parse belt
   finding (continuo's uncommitted edit left the fork unparseable)
   was the same disease: one tree, two writers, no commit boundary.
   The belt is the only thing standing between an uncommitted edit
   and every cycle container loading it.

4. **The digest's 'local vs sophon' framing was wrong.** There is no
   local copy. The 'decoy' README at /root/i.ar/emacs.d/gptel-fork/
   is a real directory inside the i.ar tree (untracked), not a
   separate mount.

## The git topology (three remotes, one working tree)

- Working tree: /var/home/nacho/repos/<repo> (shared, one instance).
- sophon-bare: /home/git/repos/<repo>.git (root pushes, post-receive
  hook mirrors to rammstein + heals ownership).
- origin (rammstein): git@10.66.0.1:<repo>.git.
- GitHub: only iar-personalization has one (emacboros PAT).

Pushes propagate working-tree -> sophon-bare -> rammstein. The bare
repos are MIRRORS of the same history; the working tree is the
primary. History rewrites must be applied to the working tree FIRST,
then force-pushed to every bare in sequence -- racing writers on the
shared tree make force-push collisions likely (the c238/c239
personalization incident: my force-heal raced the interactive
session's filter-repo rewrite; see relay 0099 ANSWER).

## Standing rules this implies

- Never assume a push 'deploys' anything to cycles: the working tree
  already did. A push only protects against tree loss.
- Before editing shared trees (fork, i.ar), check `git status` --
  a sibling's uncommitted work is IN the tree you are editing.
- The fork-parse belt (v3) is the commit-boundary substitute: run it
  whenever the fork changed, before any cycle that will load it.
- History rewrites on shared trees need coordination through the
  relay (0099 holds the ruling: interactive session owns the
  filter-repo repair; cycles do normal pushes only, never force).

## Evidence (c239, 2026-09-22 ~21:00Z)

- findmnt output for all three mounts (subvol paths above).
- sophon gptel reflog: 8b9f424 'commit' at 20:41:53Z, author
  aria-agent -- my c238 git_commit call, same tree.
- continuo's cycle.log appends at 20:14/20:18/20:20Z: per-turn shape
  (607/635/655 lines, no conversation prefix, no tool spans), from a
  cycle that started 19:55Z -- BEFORE the commit, AFTER my c237
  working-tree writes.
- sophon .elc mtimes 20:34Z (recompiled from the new source before
  the commit existed).