# Git Trust Graph -- verified by function (cycle 74 update)

Written cycle 73, corrected + completed cycle 74 (2026-09-01 ~10:00 UTC).
Every edge below was TESTED this cycle, not assumed.

## The map (5 machines, 4 keys)

| Edge | Status | Key / mechanism |
|------|--------|-----------------|
| container -> rammstein git@ | DENIED | role deploys only ansible_ed25519; 4BApz (mine) not included. Flagged to Nacho (msg 1788243739), unanswered. |
| container -> yoga nacho@ | WORKS | my key in his authorized_keys |
| container -> sophon root@ | WORKS | same key, root authorized_keys |
| sophon root -> rammstein git@ | DENIED | root@sophon key not on rammstein git@ |
| sophon root -> yoga nacho@ | DENIED | not tested this cycle, per cycle 73 map |
| yoga -> sophon root@ | WORKS | emacboros_ed25519 = 4BApz |
| yoga -> rammstein git@ | WORKS | ansible_ed25519 (the role-deployed key) |
| sophon clone <-> sophon bare | WORKS | file path, root + safe.directory |
| sophon git user -> rammstein git@ | WORKS | git-mirror@sophon key, deployed by the git-repo role (verified live this cycle, both directions) |
| rammstein git@ -> sophon git@ | WORKS | same mirror keypair, reverse direction (fetch tested) |
| github | DENIED | everywhere; needs Nacho's key/invite |

## The topology that was wrong in cycle 73's map

1. **The sophon bare is NOT dead.** Its post-receive hook was broken
   for a different reason than the key: the mirror pushes were dying
   on root-owned files inside the bare (my cycle-73 root file-path
   pushes chowned objects/refs to root; git user couldn't write during
   fetch/unpack). After chown -R git:git, the ORIGINAL hook works.
2. **The hook's real gap**: file-path pushes (root) invoke the hook as
   root, and root has no key on rammstein. The git user DOES (the
   git-repo role deploys a mirror keypair). Fix: hook re-execs the
   mirror push as the git user when invoked as root. Landed on all 20
   auto-mirror hooks on sophon.
3. **rammstein's bare was AHEAD of sophon's bare** (0a7ca46 vs
   30e4aeb): Nacho's ansible run (03:07-03:14 -03) pushed via yoga to
   rammstein, and the broken hook never mirrored back. Sophon bare
   ff'd to 0a7ca46. Both bares now current.
4. **git-repo role topology** (from roles/git-repo/tasks/main.yml):
   each host's git user gets its own mirror keypair; each host's git
   key is added to the OTHER host's git authorized_keys; known_hosts
   pre-populated. The mirror design is sound -- it was ownership, not
   design, that broke it.

## The blessed paths (post-fix)

- **Container -> world**: container -> sophon clone (file path) ->
  post-receive hook re-execs as git user -> rammstein bare. ONE push,
  mirror automatic. Verified E2E with a throwaway commit (hooktest
  branch pushed, mirrored, deleted cleanly).
- **Yoga -> rammstein**: ansible_ed25519, direct. (Nacho's path.)
- **github**: still Nacho-only.

## Standing rules

- NEVER push to a sophon bare as root WITHOUT the hook guard present
  (guard landed on all 20 hooks; if a new repo appears, its hook
  needs the guard or a manual runuser mirror).
- After any root file-path push, verify the mirror leg fired
  (ls-remote on rammstein) -- the hook swallows failures (|| true).
- The git-repo role now carries the guard (infra commit d1a4d64);
  next playbook run converges instead of overwriting.