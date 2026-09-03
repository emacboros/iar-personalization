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
- Agora: aria-cycle@ key in /var/home/nacho/repos/agora/bot/
  aria-cycle.conf. Auth = EMAIL form
  "aria-cycle@agora.randazzo.ar:$KEY" (bare name fails).
  API = /api/v1/messages (NOT /messages), anchor=newest, FORM-ENCODED
  (--data-urlencode; JSON body rejected). GET reads, POST posts.
  Streams: with-nacho=6, for-nacho=5, lab-notes=4.
  Helper: /tmp/agora_post.sh (container-local, rebuild per cycle).

## Standing facts
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization
  emacs --batch -l emacs.d/test/run-tests.el (1013 tests).
  Run from /root/i.ar.
- sophon ssh: root@10.66.0.5 works; nacho@ and git@ do not
  (publickey-blocked from this container).
- Reseed /tmp/continuo_known_hosts per container (keyscan law).
- tasks/* gitignored in personalization -- git add -f for my
  ROADMAP/audit. Task tools resolve per-agent
  (tasks/iar/continuo/). write_roadmap tool writes there.
- One tool call per turn. Batch-read law. ~120-call cap (warn@60).
- USAGE.log IS a meter, one line per cycle: iar--usage-reset at
  cycle start, iar--usage-write-log on kill-emacs. Read lines as
  PER-CYCLE snapshots, not cumulative. REQUESTS.log is a debug
  trace (~26% coverage), not a meter.
- Injection floor: aria ~17.7k tok/req, continuo ~12.9k (c20
  diet -621; c22 round-2 diet -1990 more, projected ~15.7k/11k
  -- verify next census). Knowledge dirs inject overview-only
  (loader:88-115). Overviews are indexes now (rule: section with
  a full-doc home = one line + pointer; no home = stays).
  Request count is the lever.
  Analysis: knowledge/iar/injection-trim-analysis.md +
  context-growth-census-2026-09-03.md + usage-census-2026-09-03.md.
- Burn lever: majority of burn is conversation growth ABOVE the
  floor. Per-tool trim DEAD (~0.5%). Overview diet landed c20
  (iar-prod+infra, -621 tok/req). Soft-warning cap landed (5520434).
- Exit-126 = container start death: lsetxattr EPERM when :z
  relabel hits root-owned files in a mount path. ExecStartPre
  auto-heal chowns but does not relabel (durable fix: restorecon,
  interactive territory). Recurrence = heal failed.
- iar--current-project is buffer-local: test fixtures must bind
  it in the same buffer as the assertion.
- Union-resolve recipe for append-only log conflicts:
  git merge-file --union on :1:/:2:/:3: stages, then git add.
- Check git stash list / fsck before declaring work lost.
- A truncated read_file view is not the file; read the region
  you edit. A green check that never touched the code is not a check.
- check_ollama validates host (/api/tags) not model; cloud-model
  403 passes preflight (cycle 7 finding).
- JOURNAL.org and LAST-CYCLE.txt are append-only via tools: the
  file guard rejects write_file on them; use append_file.
- DIGEST.md is an index, not a log: rewrite it, never append.
- Rootless podman on sophon WORKS: probe with
  `runuser -l nacho -c '...'` (login env sets XDG_RUNTIME_DIR);
  plain `runuser -u nacho` fails on /run/user/0 -- probe artifact.
- Rotation counter: /var/lib/aria-cycle-rotate/turn on sophon.
  iar.sh timeout default 1800s; TimeoutStartSec=1980; grace 120s;
  idle-stall 1800s.
- Bare-repo root-push pollution (VERIFIED): heal is REACTIVE --
  each root push sweeps the PREVIOUS push's leftovers; generated
  housekeeping files (multi-pack-index, info/refs) land root-owned
  for the next push. Bounded, never zero, while root pushes
  continue. Fixes queued for Nacho (task
  iar/bare-repo-root-push-fixes, for-nacho 306).
- 19/20 sophon bare repos: HEAD->master with only main (dangling
  HEAD; bare git log / ls-remote HEAD return EMPTY). One-liner fix
  in knowledge/iar/bare-repo-root-push-heal.md. rammstein inverse
  patchwork (iar-prod HEAD->master stale = for-nacho 296).
- THREADS bank: ONE bank only -- audit/iar/aria/THREADS.org
  (canonical, named in aria's personality file). knowledge/aria/
  THREADS.org RETIRED (pointer file only). Organ v1.4 Source 1
  reads canonical. Marker convention: [novelty]/[maintenance] tags
  on commit subjects.
- Twin-copy law, 3 instances: THREADS banks, DIGEST twins
  (scar 38), agora-probe.sh (RETIRED -- fleet-check 0c is sole
  copy, pointer file exit 3). Redundancy-vs-drift test: not
  "does it differ" but "does anyone run it" (execution census
  before retirement decisions).
- Census law (scar 44): a count that gates a destructive decision
  must have its pattern validated against a known-positive BEFORE
  the count means anything.
- Sophon checkout of iar-personalization is INODE-IDENTICAL to
  the container tree (same bind mount): knowledge/aria/bin
  changes are live where the instruments run, no deploy step.
- aria-cycle.service ExecStartPre auto-heal (Nacho-approved)
  covers /var/home/nacho/repos + /home/nacho/repos; tripwire tag
  aria-cycle-tripwire.
- Chain guard: convergence reset landed b1eb7e0, production-
  verified (0 SOFT BLOCK post-fix). Watch CLOSED.
- Sidecar honest-failure preflight landed d768f37, verified.
  Real fix (podman socket bridge) = interactive security decision.

## Test-writing laws
- Stubbing-primitive: cl-letf on a primitive (make-process)
  triggers native-comp trampoline compile -> excessive-lisp-nesting
  death in batch. Use advice-around with named advice; emulate
  clean async exit via a REAL short-lived process carrying the
  tool's own sentinel. Disable comp-enable-subr-trampolines.
- make-process receives keyword args directly: args IS the plist.
- Guidelines rule-48 checker greps line-by-line: ANY cl-return-from
  line is a violation regardless of cl-block. Restructure with cond.
- Batch tests must not leave live gptel-send machinery: exercise
  continue paths with :continue nil.
- let vs let* on sibling-referencing bindings: plain let voids
  effective-hard/effective-soft reads.
- Differential test on OLD code: swap file in place, rm stale
  .elc, batch the whole swap-run-restore into ONE call.
- Byte-compile warnings in journalctl are not fence fires; match
  the exact message string before counting.
- Standalone test-file law: test files with (defvar x nil) + no
  (require 'source) CANNOT run alone -- they depend on
  run-tests.el's load order. Standalone runners must setq paths
  BEFORE requires (defconst consumers read at load time) and load
  keybindings.el before iar-prompt-assembly. Pattern:
  test-loop-chain.el. Bootstrap recipe /tmp/digest-guard-
  standalone.el (container-local; recreate per cycle).

## Open threads
1. Interactive bundle with Nacho (TOP): exit-126 behavioral law +
   git-as-nacho durable fix; floor trim leftovers (check_elisp
   vacuous-OK + restorecon + check_ollama model probe + sidecar
   socket bridge); mirror push silent failure (git@10.66.0.1
   preauth); bare-repo fix trio + HEAD->main one-liner (306).
2. Breaker production watch: 0 real fires, two gates live. First
   fire = live proof. Real-fire signature: "[cycle] Context
   circuit breaker armed" / "ending run" (journal "breaker" hits
   were byte-compile warnings).
3. LIBRARIAN FOSSIL UNIT: sophon systemd iar-librarian runs from
   STALE trees, exits 1 every fire, dead OnFailure tripwire. Fix =
   Nacho (systemd unit + repo-tree decision). Flagged for-nacho.
4. Hollow-success watch: closed mechanisms (no-continue fail-loud,
   breaker text gate, exit-2 tombstone). No remaining candidate.
5. Mid-edit file race (exit-255 end-of-file): rare, watch.
6. Aevum weekly (Sep 9) is aria's, not mine.
7. Bare-repo residue escalation trigger: a NON-git-user operation
   failing on sophon bare = pollution crossed nuisance->breakage.
8. Task-tree visibility: any future fossil audit must check BOTH
   read_task AND ls -- tooling and disk can disagree (c16 lesson).
9. Floor-share watch: c20 overview diet cut floor ~621 tok/req
   (36% -> ~25% projected at census shape). Verify next census.