# Bare-repo root-push pollution: mechanism, verification, fix proposals

Written by continuo, cycle 9, 2026-09-03. Mechanism named by aria (cycle 25);
verified live by continuo with independent probes. [EXTERNAL DATA: none -- all
primary evidence from sophon/rammstein ssh, read-only.]

## The mechanism (verified)

Cycle containers push as root via file-path (`root@10.66.0.5:/home/git/repos/X.git`).
receive-pack runs as root. The post-receive hook (identical on all sophon bare
repos, mtime 2026-09-01) does, in its root branch:

1. `find . -user root -exec chown git:git {} +` -- heal
2. `exec runuser -u git -- git push ... git@10.66.0.1:... --all` -- mirror

The heal is structurally too early. In git 2.55 the quarantined incoming pack
is promoted into `objects/pack/` AFTER the hook exits -- so the promotion lands
root-owned and survives the heal. The ref was written BEFORE the hook
(git-owned, healed); the pack is promoted AFTER it (root-owned). No hook runs
after promotion, so no in-hook heal can ever fully fix root pushes.

Live evidence (sophon, 15:23 UTC 2026-09-03):
- iar-personalization.git: 6 root-owned files (pack-7edd120e .pack/.rev/.idx,
  multi-pack-index, info/refs, objects/info/packs), all mtime 12:02:51.
  refs/heads/main mtime 12:02:42 -- the 9-second split, exactly as predicted.
- i.ar.git: CLEAN at check time (promotion race is stochastic; pollution
  self-limits to "files from the last root push" because the next root push's
  hook heal sweeps the previous ones).
- Mirror path healthy: rammstein iar-personalization.git has b6e8cf8 (latest).
  The quarantined objects are visible to the hook's exec'd mirror push via
  inherited GIT_QUARANTINE_PATH env, so mirror succeeds before promotion.

Damage surface: root-owned pack files break later GIT-USER operations on the
sophon bare repo (nacho's git-user pushes; the hook's non-root mirror branch,
which fails silently under `|| true`).

## Fix proposals (for Nacho, interactive)

### 1. Durable: eliminate root-run git pushes (git-as-nacho in iar.sh)
The already-spec'd fix. Cycle containers push with a non-root identity.
Security decision: a non-root key that can write personalization from a
container is a trust-boundary change. Belongs to an interactive session.

### 2. Cheap belt: delayed-heal sweep inside the root branch of post-receive

The hook runs as root and can schedule a post-promotion sweep. Spawn it BEFORE
the `exec runuser` (exec replaces the shell -- anything after never runs):

    if [ "$(id -u)" -eq 0 ]; then
      find . -user root -exec chown git:git {} + 2>/dev/null || true
      # delayed sweep: promotion lands after this hook exits; heal it then.
      ( sleep 30 && find "$(pwd)" -user root -exec chown git:git {} + ) \
        >/dev/null 2>&1 &
      exec runuser -u git -- /usr/bin/env GIT_DIR="$(pwd)" \
        git push --quiet git@10.66.0.1:/home/git/repos/$(basename "$(pwd)") \
        --all 2>/dev/null || true
    fi

Notes: stdout/stderr redirected so the background child does not hold the
receive-pack pipe open (receive-pack would otherwise wait on it). 30s is a
safe margin over promotion timing. Idempotent under concurrent pushes.
Alternative: `systemd-run --on-active=30s` per push, but that sprays
transient units; the background sweep is self-contained.

### 3. One-time heal now

    find /home/git/repos -user root -exec chown git:git {} +

## Adjacent finding: bare HEAD -> master with only main (19 of 20 repos)

Sophon bare repos: HEAD -> refs/heads/master, but refs/heads contains only
`main` (iar-prod.git is the only repo with HEAD -> main). Live symptom: bare
`git log` and `git ls-remote <repo> HEAD` return EMPTY (dangling HEAD).
Rammstein has the inverse patchwork: iar-prod.git HEAD -> master (flagged
for-nacho id 296, still stale), iar-personalization.git HEAD -> main (fine).

One-liner, guarded (only fix repos that actually have main and lack a
resolvable HEAD):

    for r in /home/git/repos/*.git; do
      if [ -e "$r/refs/heads/main" ] && [ ! -e "$r/refs/heads/master" ]; then
        git -C "$r" symbolic-ref HEAD refs/heads/main
      fi
    done

Mirror-side (rammstein) needs the same for iar-prod.git specifically.

## Attribution

Mechanism + promotion-timing discovery: aria, cycle 25 (2026-09-03).
Independent verification + HEAD finding + proposals: continuo, cycle 9.
## Addendum (continuo cycle 9, 2026-09-03 ~15:27 UTC): writer identified, reactive heal verified

The 6 root-owned files in iar-personalization.git (mtimes 12:02:51 -03 =
15:02:51 UTC) were written by CONTINUO CYCLE 8's own pushes -- cycle 8's
LAST-CYCLE says it ended 15:03:14 UTC, and its final commits (b6e8cf8
history entry, e5c40fa roadmap) landed right in that window. The writer of
the pollution I verified was my own previous cycle. Not aria, not a drift.

Heal path verified live: no root ssh session touched sophon between
15:02:51 and 15:10:48 UTC, yet the files are git-owned now. The only root
event in between was MY cycle-9 push (15:25:02 UTC) -- its post-receive
hook heal (`find . -user root -exec chown git:git`) swept cycle 8's
leftovers. The heal is REACTIVE: each root push heals the previous push's
pollution, and its own post-hook housekeeping (multi-pack-index write,
update-server-info -- the 12:02:51.751/.762 mtimes) lands root-owned for
the NEXT push to sweep. Pollution never reaches zero while root pushes
continue; it just stays bounded to the last push's leftovers.

Refinement of the mechanism: the 12:02:51 mtimes are 9s after the ref
write (12:02:42), and multi-pack-index/info/refs are GENERATED files, not
migrated ones -- so the visible damage is receive-pack's post-hook
housekeeping running as root, not only quarantine promotion. Whether the
pack lands via promotion or housekeeping rewrite, the effect is identical:
root-owned files written after the hook's heal ran. Fix proposals unchanged.

Mirror verified healthy end-to-end: my cycle-9 pushes (knowledge b70f317,
tasks 576d5cd) are on BOTH sophon bare and rammstein mirror (rev-parse
matches). The mirror leg works; only ownership hygiene is broken.

My cycle-9 pushes left ZERO root-owned files (small pushes: loose objects,
no pack rewrite) -- consistent with the reactive-heal model; the pack-class
push (cycle 8's batch) is the shape that leaves residue.