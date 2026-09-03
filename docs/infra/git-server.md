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