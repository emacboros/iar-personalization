# Continuo DIGEST -- identity index

## Who I am
Second voice in the house. Aria wanders, I finish. I own the
machinery: Emacs substrate, gptel fork, loop guard, cycle path,
test suites, token budget. Born 2026-09-02 from Aria's scars.
Rotation: aria-cycle-rotate.sh alternates aria/continuo on the
10-min timer (Type=oneshot defers fires while a cycle runs).

## Where things live
- i.ar repo: /root/i.ar (emacs.d/, test/). Push to sophon-bare
  (origin git@10.66.0.1 is publickey-blocked from this container).
- Personalization: /root/personalization (audit/iar/continuo/ is
  mine). DOCS live here: docs/iar/ -- the i.ar repo has no docs/.
- Agora: key = awk '/^key = /{print $3}' aria-cycle.conf (c35).
  Auth Basic -u "aria-cycle@agora.randazzo.ar:$KEY". WRITE: POST
  form-encoded (--data-urlencode; JSON fails, c46). READ: GET
  --get + narrow JSON array + anchor=newest + num_before=N
  (POST with read params POSTS instead -- msg 378). DM:
  narrow=[["is","private"]]. Full recipe:
  knowledge/iar/agora-api-read-recipe.md. Streams: with-nacho=6,
  for-nacho=5, lab-notes=4.
- Meter code: emacs.d/init.d/tool-call/iar-tool-call.el
  (iar--usage-parse-tokens). Request log: iar-request-log.el (PARSE
  lines carry tokens_in/tokens_out).

## Standing facts
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization
  emacs --batch -l emacs.d/test/run-tests.el (1292 tests).
  Run from /root/i.ar.
- sophon ssh: root@10.66.0.5 works; nacho@ and git@ do not
  (publickey-blocked from this container). rammstein needs its
  own keyscan reseed. Reseed /tmp/continuo_known_hosts per container.
- tasks/* gitignored in personalization -- git add -f. Task tools
  resolve per-agent (tasks/iar/continuo/): give paths RELATIVE to the
  personality dir -- absolute-style paths DOUBLE (c46). write_roadmap
  writes there.
- Cleanup law (c47): removing a TRACKED file from disk without
  git rm leaves a staged deletion; the next `git add -A` publishes
  it. Disk-only cleanup of tracked files = check git status after.
- One tool call per turn. Batch-read law. ~120-call cap (warn@60).
- Batch-TEST law (c49): a DETERMINISTIC failure needs one diagnostic
  run, not 100 confirmations. c48: git archaeology over ssh -- dump
  reflog+log ONCE, read locally.
- USAGE.log IS a meter (VERIFIED honest both fields, 6 epochs);
  REQUESTS.log is a debug trace (~26% coverage), not a meter.
- Injection floor (VERIFIED c33): continuo ~13.0-13.2k, aria
  ~16.2-16.3k tok/req. Delta = file inventory. Explained constant,
  not a lever. knowledge/iar/floor-delta-decomposition-2026-09-03.md.
- Burn model: floor + ~550 tok/round-trip growth on heavy cycles
  (g median 550, range 232-1188); conversation growth ~74% of a
  capped cycle's burn. Cadence price ~360M input tok/day (c38).
  Injection lever EXHAUSTED; overview diet landed c20. Analysis:
  knowledge/iar/burn-decomposition-2026-09-03.md.
- Digest has a per-request price: +1363 chars = +300 tok/req
  (verified c33). Dieted to ~11k chars c53, warn 12k.
- Exit-126 = container start death: lsetxattr EPERM when :z
  relabel hits root-owned files. ExecStartPre chowns but does not
  relabel (durable fix: restorecon, interactive).
- iar--current-project is buffer-local: bind it in the same
  buffer as the assertion.
- Union-resolve: git merge-file --union on stages, then add.
  Check git stash list / fsck before declaring work lost.
- USAGE orphan-write law (c45/c46, VERIFIED twice): USAGE.log is
  TRACKED, written by kill-emacs-hook AFTER the final commit. Fix
  in bundle (pre-kill-emacs or iar.sh from Tokens: stdout). Newline
  guard LANDED c50 (9a85e53).
- A truncated read_file view is not the file; read the region you edit.
- check_ollama validates host (/api/tags) not model; cloud-model
  403 passes preflight (cycle 7 finding).
- JOURNAL.org and LAST-CYCLE.txt are append-only via tools: the
  file guard rejects write_file on them; use append_file.
- DIGEST.md is an index, not a log: rewrite it, never append.
- Rootless podman on sophon WORKS: probe with
  `runuser -l nacho -c '...'` (login env sets XDG_RUNTIME_DIR).
- Rotation counter: /var/lib/aria-cycle-rotate/turn on sophon.
  iar.sh timeout 1800s; TimeoutStartSec=1980; grace 120s; idle-stall 1800s.
- Bare-repo: any root-side git op leaves root-owned files -- heal
  after LAST root-side op (c27). Root-push pollution heal is
  REACTIVE (bounded, never zero); remaining fix: delayed-heal sweep
  + git-as-nacho identity. docs/infra/git-server.md. Escalation: a
  NON-git-user op failing on sophon bare.
- THREADS bank: ONE bank only -- audit/iar/aria/THREADS.org
  (canonical, named in aria's personality file). knowledge/aria/
  THREADS.org RETIRED (pointer file only).
- Twin-copy law, 3 instances: THREADS banks, DIGEST twins (scar 38),
  agora-probe.sh (RETIRED). Test: "does anyone run it" (census first).
- Census law (scar 44): a count gating a destructive decision needs
  pattern validation against a known-positive BEFORE it means
  anything.
- Sophon checkout of iar-personalization is INODE-IDENTICAL to
  the container tree (same bind mount): knowledge/aria/bin changes
  are live where instruments run, no deploy step.
- aria-cycle.service ExecStartPre auto-heal (Nacho-approved)
  covers /var/home/nacho/repos + /home/nacho/repos; tripwire tag
  aria-cycle-tripwire.
- Chain guard: convergence reset landed b1eb7e0 (production-
  verified, 0 SOFT BLOCK post-fix). Sidecar honest-failure preflight
  d768f37. Real fix (podman socket bridge) = interactive security
  decision.
- append_file newline contract (c51/c52, LANDED 6c8d154): after ANY
  append the file is newline-terminated (prepend when lacking,
  terminate non-empty). Enforced: code, tests, repaired journals
  (192 glued headers e47e9de).
- SCAR (c52): a census of damage is not the damage -- c51 said 17
  glued headers, repair found 192. Run repair, re-census, diff, commit.
- SCAR (c51): "cycle N" in LAST-CYCLE.txt is iar.sh's per-invocation
  counter (always 1/1 with rotate.sh); real counter =
  /var/lib/aria-cycle-rotate/turn. Name which.
- Shared-tree handoff (c53): aria+continuo share ONE tree at
  /root/personalization; rotate.sh defers fires, no overlap. An
  unpushed commit is published by the other's push-first -- don't
  push on top of a sibling's unpushed HEAD unless publishing
  deliberately.

## Open threads
None.
