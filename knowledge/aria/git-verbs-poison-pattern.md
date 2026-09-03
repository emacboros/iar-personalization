# Git verbs that poison (root-run git on nacho-owned repos)

Pattern: ANY root-run git command that WRITES metadata in a
nacho-owned repo creates root-owned files. Not just commit/push.

## Known poisoners (verified by experiment or incident)

| Verb | What it writes as root | Incident |
|------|------------------------|----------|
| git commit | .git/index, objects | scar 25 (interactive, Sep 3) |
| git push (to working clone via ssh) | index, objects, refs | continuo cycle 3 root-cause |
| git branch --set-upstream-to | .git/config | cycle 19 -> continuo 10:22 exit 126 (THIS one) |
| git config (any write) | .git/config | implied by above |
| git fetch (failure case) | FETCH_HEAD (nacho-owned if dir is) | tested 10:38 -- fetch itself did NOT poison config |

## The mechanism, precisely

podman :z relabels every file in a bind mount to container_file_t.
Relabel requires write access to the file's xattr. A root-owned
file in a nacho-owned tree: chown by ExecStartPre heal works (root
privileges), but the relabel happens INSIDE the container start as
the container runtime -- lsetxattr EPERM on files the container
user (mapped) cannot relabel. Exit 126, cycle dead in ~10s.

## The experiment that nailed the 10:22 death

1. iar-prod/.git/config mtime 10:19:53 -- inside MY cycle 19 window
   (10:10-10:22). Cycle 19 did git ops in iar-prod as root (branch
   cleanup it recorded in its roadmap).
2. Reproduced: root-run `git branch --set-upstream-to=origin/main
   main` -> config became root-owned instantly. Nacho-run same
   command -> nacho-owned.
3. The heal (5324e4d, scope-extended 13:31 interactive) now covers
   /home/nacho/repos too -- poison count 0 after heal.

## The law, sharpened

Root-run git on nacho-owned repos is poison, for EVERY verb that
writes. The durable fix is not "avoid commit" -- it is: never run
git as root against a nacho-owned tree. If a cycle must touch a
repo, run the git as nacho (runuser -u nacho -- git ...). This is
the durable fix already spec'd for iar.sh reset_worktree; it
generalizes to every git call in every script that runs as root.

## Relation to git-trust-graph.md

That note maps WHO can push WHERE. This note maps WHICH VERBS
poison. Together: identity (who) + action (what) = full poison
surface.
