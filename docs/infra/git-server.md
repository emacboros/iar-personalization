# Git Server (bare repos, sophon + rammstein mirror)

## Topology

Primary: sophon `/home/git/repos/*.git` (20 bare repos). Mirror: rammstein
`/home/git/repos/*.git`. Pushes to sophon auto-mirror to rammstein via
post-receive hook. Cycle containers push as root via file-path
(`root@10.66.0.5:/home/git/repos/X.git`); humans push as git user.

## Post-receive hook (all 20 repos, identical)

Root branch: heal ownership (`find . -user root -exec chown git:git {} +`),
then `exec runuser -u git -- git push ... git@10.66.0.1:... --all`.
Non-root branch: mirror push as git user (all + tags), `|| true` (silent).

## Known issues (verified, fixes queued for Nacho -- interactive)

1. **Root-push pollution**: receive-pack housekeeping (quarantine pack
   promotion, multi-pack-index, info/refs) lands root-owned AFTER the
   hook's heal runs. Reactive: each root push sweeps the previous push's
   leftovers; never zero while root pushes continue. Damage: breaks
   git-user operations on the bare repo. Mechanism + fix proposals
   (durable git-as-nacho push identity; delayed-heal sweep in hook):
   knowledge/iar/bare-repo-root-push-heal.md. Escalation trigger: a
   NON-git-user operation failing on sophon bare.
2. **Dangling HEAD**: 19/20 sophon repos have HEAD->master but only
   `main` (bare `git log` / `ls-remote HEAD` return EMPTY). Fix one-liner
   in bare-repo-root-push-heal.md. rammstein inverse patchwork:
   iar-prod.git HEAD->master stale (for-nacho 296).
3. **Mirror push silent failure**: hook mirrors with `|| true`; a failed
   mirror (e.g. git@10.66.0.1 preauth) leaves no trace. Container
   `git fetch origin` to git@10.66.0.1 = publickey denied (mirror health
   must be checked server-side).

## Health checks (read-only)

```bash
# pollution count (expect 0 between pushes)
ssh root@10.66.0.5 'find /home/git/repos -user root | wc -l'
# dangling HEAD census (expect empty)
ssh root@10.66.0.5 'cd /home/git/repos && for r in *.git; do
  if [ -e "$r/refs/heads/main" ] && [ ! -e "$r/refs/heads/master" ]; then
    echo "DANGLING: $r"; fi; done'
# mirror sync (sophon vs rammstein rev)
ssh root@10.66.0.5 'git -C /home/git/repos/iar-personalization.git rev-parse main'
ssh root@10.66.0.1 'git -C /home/git/repos/iar-personalization.git rev-parse main'
```

## Repo inventory (sophon, 2026-09-03)

20 repos: concepts, cv, finance, fluidattacks_writeup, gptel, i.ar,
iar-infrastructure, iar-personalization, iar-prod (+ others). HEAD state:
i.ar/iar-infrastructure/iar-personalization dangling (master->main only);
iar-prod HEAD->main correct; gptel HEAD->master correct.
## Addendum (continuo c28, 2026-09-03 ~22:05 UTC)

**iar-prod master divergence RESOLVED.** Aria c44 forensics verified:
sophon `refs/heads/master` = cd05e63 (orphan root commit, "mirror test",
t <t@t>, landed inside continuo c19's differential-git testing window),
not an ancestor of main (1c73f86). rammstein master = 1c73f86 (real
history). Next root push would have mirror-pushed sophon's master
non-FF -> rejected -> swallowed by `|| true` -> permanent silent
divergence. Executed under Nacho's standing direction (with-nacho 238,
same class as the c27 HEAD one-liner: reversible ref-only, no data
touched):

- Deleted `refs/heads/master` on BOTH sides (as git user via
  `runuser -u git -- git update-ref -d`). Verified: both now `main`
  only. Root-owned residue 0/0.
- cd05e63 object PRESERVED on sophon (git prune does not collect it:
  it is reachable from nothing but still in a packfile -- quarantine
  promotion packs objects, not reachability). rammstein also has the
  object. Recovery: `git cat-file -t cd05e6375f37cc38df0f152330e8950eda709dfb`.
- rammstein post-receive verified: pushes BACK to sophon (`--all`),
  no `|| true` on the exec path... actually `|| true` present, silent
  both directions. Mirror-loop hypothesis from aria c44 (rammstein
  pushing back) is REAL: sophon hook pushes to rammstein, rammstein
  hook pushes back to sophon. Harmless when refs agree (no-op push),
  but it is a loop by construction; worth one line in the delayed-heal
  proposal.
- Ref-only deletion means the mirror-push non-FF hazard is gone: both
  sides now have identical ref sets (main only).

Status: known-issue 2 (dangling HEAD) fully CLOSED both servers.
Known-issue 3 (silent mirror failure) remains queued; the cd05e63
incident is its concrete near-miss.
## Inventory correction (aria c45, 2026-09-03 ~22:15 UTC)

Cycle 44's commit message claims "git-server.md inventory corrected"
but the commit contains NO docs/ change (55a8cd9 touched only
audit/* and tasks/iar/aria/ROADMAP.org) -- the edit was lost in the
cap-crash of c44's landing. The c45 pull-before-write check caught
it: commit message vs commit content disagree. Corrected inventory:

20 repos (sophon, verified c44): 4 live main repos
(iar-personalization, i.ar, iar-infrastructure, iar-prod) + gptel
(live, master, sophon==rammstein 970da80) + notes (test repo,
master-only, sophon-only) + 14 EMPTY repos (zero refs, zero objects,
created Aug 3-4, never pushed; HEAD->master is normal init state for
an empty bare, NOT a fault). The "19/20 dangling HEAD" line above is
therefore WRONG as written: only 3 repos were ever truly dangling
(i.ar, iar-infrastructure, iar-personalization -- all fixed by
continuo c27, one-liner executed both sides). 14 are newborns.

Also correcting the c28 addendum's one self-contradiction: rammstein
post-receive DOES have `|| true` on its push-back path (the addendum
first says "no || true on the exec path" then corrects itself
mid-sentence). Net truth: mirror is silent in BOTH directions; the
loop (sophon->rammstein->sophon) is real but no-ops when refs agree.

Mirror-loop verification (c45, read-only): rammstein post-receive
pushes back to sophon -- confirmed by continuo c28 + consistent with
c44's inbound-connection timestamps. git-server.md's one-way model
was wrong; the loop is by construction, harmless while refs agree.