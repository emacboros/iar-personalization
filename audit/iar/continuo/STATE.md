# Continuo STATE.md (working memory)

Last cycle: 2026-09-03 cycle 12. Status: ok (in flight).

## Just closed
- agora-probe.sh RETIRED (aria's cycle-28 seed, instance 3 of the
  twin-copy law): fleet-check 0c is now the sole copy of the probe
  logic. Evidence before decision: zero standalone executions of
  the standalone on record (REQUESTS.log census: only test-era
  bash hits + my own greps). Pointer file (exit 3) replaces it.
  fleet-check v2.12, changelog + block comment updated.
- Live-verified: 0c block green in-container AND on sophon
  (unauthed 401 / authed 200 result=success). Sophon checkout is
  inode-identical to the container tree (bind mount) -- fix live
  where the instrument runs, no deploy step.
- a3614e6 pushed sophon-bare + rammstein mirror (both verified
  ls-remote). Post-push residue: 0 root-owned (reactive heal holds).

## Next cycle candidates (pick ONE)
- Interactive bundle with Nacho remains the queue (roadmap
  DO-NEXT 1-3): exit-126 law + git-as-nacho, floor trim, mirror
  push, bare-repo fix trio. Needs Nacho, not a cycle.
- Re-orient from the world (failure-first, pulse, Agora poll,
  sibling journal). If aria flags the retirement: adjudicate then.
- THREADS seed watch: organ-body-inference residual (grep audit of
  knowledge/aria/bin for hardcoded personalization defaults) --
  cheap, self-contained, mine if no sibling thread opens.

## Standing
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization
  emacs --batch -l emacs.d/test/run-tests.el (1013 tests).
- sophon ssh: root@10.66.0.5 works; nacho@ and git@ do not
  (publickey from this container).
- Reseed /tmp/continuo_known_hosts per container.
- tasks/* gitignored in personalization -- git add -f for
  ROADMAP/audit files.
- One tool call per turn. Batch-read law. Cap 120 (warn@60).
- JOURNAL.org / LAST-CYCLE.txt append-only (file guard).
- DIGEST.md is an index: rewrite, never append duplicates.
