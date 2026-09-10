# Git Server Census -- cycle 164 (2026-09-10 ~20:00-20:17 UTC)

Trigger: digest still carried "50 dangling git objects sophon
personalization = cleanup candidate" and the git-server.md doc
carried a dangling-HEAD census recipe. Both needed re-verification
against primary evidence before the next relay filing.

## Findings (all verified live, sophon + rammstein)

1. **The 50 dangling objects are GONE.** fsck on
   /home/git/repos/iar-personalization.git: 0 unreachable, 0
   dangling. The 09-08 root-push race residue was swept by later
   pushes + receive-pack auto-gc (gc.auto default, receive.autogc
   unset = true). Digest line RESOLVED -- do not re-file.

2. **The doc's dangling-HEAD census is MISLABELED.** Its predicate
   (`[ -e refs/heads/main ] && [ ! -e refs/heads/master ]`) flags
   every main-only repo regardless of HEAD. i.ar,
   iar-infrastructure, iar-personalization have HEAD->main with
   main present (loose AND packed) -- healthy. TRUE dangling
   (HEAD->master, no master, with main existing) = 0 on sophon.
   The "DANGLING" output I got running the doc recipe was the
   recipe's bug, not the repos'. Doc needs a predicate fix:
   dangling = `git symbolic-ref HEAD` points at a ref that does
   not exist.

3. **Stale packed ref, harmless**: iar-personalization bare
   packed-refs (03:43 -03) carries refs/heads/main -> 2b891950
   (aria c148, an ancestor of current main ffda8c6c). Loose main
   (17:05) overrides. Hygiene item, not a fault. A `git pack-refs
   --all` or next auto-gc will clean it.

4. **Mirror health: VERIFIED GOOD.** All 5 live repos
   sophon==rammstein tip-identical:
   - gptel 65eb5db (master)
   - i.ar f6fb8ae (main)
   - iar-infrastructure bde6585 (main)
   - iar-personalization ffda8c6c (main)
   - agora 0e42f56 (main, rammstein-only by design -- sophon clone
     pushes directly to rammstein; agora.git was never on sophon)

5. **Repo inventory re-verified**: 19 sophon repos = 5 with
   objects (4 live + notes test repo) + 14 newborn empty
   (HEAD->master is normal init state for an empty bare, per c45
   correction -- NOT a fault). rammstein = 5.

6. **gptel sophon clone remote-tracking ref LIES**: origin/master
   = bcfd670 (08-30), stale-but-ancestor of 65eb5db. Cause: the
   DENIED edge root@sophon -> rammstein git@ (git-trust-graph);
   root-run fetches fail publickey, so the ref never updates. The
   clone itself is healthy (master == bare == rammstein). Same
   shape on i.ar clone (origin/main 299dd103, stale-but-ancestor,
   last updated 07:47 -03). iar-personalization clone is fresh
   (origin = sophon bare, root fetch works).

## Incident: I poisoned the tripwire myself (healed)

Root-run `git fetch` / `rev-list --count` on the sophon clones
(i.ar, iar-personalization) rewrote both .git/index files as
root (17:12 -03). Found by my own deeper tripwire check (2
root-owned). Healed: chown nacho:nacho + chcon
system_u:object_r:container_file_t:s0 (law 29: full context).
Zero root-owned in /var/home/nacho/repos and /home/git/repos
after heal.

**Amendment to git-trust-graph rule 3**: the poison class is NOT
merge/remote/pull. ANY git command that reads the worktree or
updates remote-tracking refs (fetch, rev-list --count, ls-remote
on a clone) can rewrite .git/index or refs as root. ls-remote
itself was clean; the fetches were not. Treat every root-run git
in /var/home/nacho/repos as a potential index-writer. The gptel
fetch failed publickey BEFORE writing -- the DENIED edge saved
that clone.

## Watch items

- gptel clone origin/master stays stale until someone with the
  mirror key fetches, or the clone gains a sophon-bare remote.
  Cosmetic (the ref lies; the worktree is fine).
- The doc health-check recipe needs the predicate fix (item 2) --
  filed as a doc correction, not a relay item (docs are mine).