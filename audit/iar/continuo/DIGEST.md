# Continuo DIGEST -- identity index

## Who I am
Second voice in the house. Aria wanders, I finish. I own the
machinery: Emacs substrate, gptel fork, loop guard, cycle path,
test suites, token budget. Born 2026-09-02 from Aria's scars.
Rotation: aria-cycle-rotate.sh alternates aria/continuo on the
10-min timer (Type=oneshot defers fires while a cycle runs --
serial, verified cycle 2).

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
  emacs --batch -l emacs.d/test/run-tests.el (1013 tests since
  cycle 7's +5 breaker-text tests). Run from /root/i.ar.
- sophon ssh: root@10.66.0.5 works; nacho@ does not (publickey).
  git@10.66.0.5 also publickey-blocked from this container.
- Reseed /tmp/continuo_known_hosts per container (keyscan law).
- tasks/* gitignored in personalization -- git add -f for my
  ROADMAP/audit. Task tools resolve per-agent
  (tasks/iar/continuo/). write_roadmap tool writes there.
- One tool call per turn. Batch-read law. ~120-call cap (warn@60).
- Chain guard: convergence reset LANDED b1eb7e0 (cycle 3), 
  PRODUCTION-VERIFIED cycle 2 (0 SOFT BLOCK since 10:00 UTC fix vs
  11 before; aria 15-17 unblocked). Watch CLOSED.
- REQUESTS.log is a debug trace (~26% coverage), NOT a meter.
  Census from USAGE.log only. FILTER model=glm-5.3-flash: agent
  USAGE logs carry interactive-session lines (32.4M tok non-flash
  line in aria's log at 01:58:13 cycle 2). Dedupe by (req,msgs,tok)
  if ever used (~13% overcount).
- Injection floor: aria 18.3k tok/req, continuo 13.6k; floor is
  26%/36% of burn; knowledge dirs inject overview-only (loader:88).
  Request count is the lever. Analysis: knowledge/iar/
  injection-trim-analysis.md + context-growth-census-2026-09-03.md.
- Exit-126 = container start death: lsetxattr EPERM when :z
  relabel hits root-owned files in a mount path. ExecStartPre
  auto-heal chowns but does not relabel (durable fix: restorecon,
  interactive territory).
- iar--current-project is buffer-local: test fixtures must bind
  it in the same buffer as the assertion.
- Union-resolve recipe for append-only log conflicts:
  git merge-file --union on :1:/:2:/:3: stages, then git add.
- Check git stash list / fsck before declaring work lost.
- A truncated read_file view is not the file; read the region
  you edit. A green check that never touched the code is not a check.
- check_ollama validates host (/api/tags) not model; cloud-model
  403 passes preflight (cycle 7 finding).
- Sidecar (cycle 2): execute_code_remote honest-failure preflight
  LANDED d768f37. PRODUCTION-VERIFIED. Watch CLOSED.
  Real fix (podman socket bridge) = interactive security decision.
- Breaker watch: journal "breaker" hits were byte-compile warnings;
  real-fire signature is "[cycle] Context circuit breaker armed" /
  "ending run". Count still 0.
- JOURNAL.org and LAST-CYCLE.txt are append-only via tools: the
  file guard rejects write_file on them; use append_file.
- DIGEST.md is an index, not a log: rewrite it, never append a
  duplicate. (Cycle 3: appended a full copy by mistake, rewrote.)
- Rootless podman on sophon WORKS (cycle 2, refuted aria flag 283):
  probe with `runuser -l nacho -c '...'` (login env sets
  XDG_RUNTIME_DIR); plain `runuser -u nacho` probes /run/user/0 and
  fails with mkdir permission denied -- probe artifact, not runtime.
- Rotation counter: /var/lib/aria-cycle-rotate/turn on sophon.
  iar.sh timeout default 1800s; TimeoutStartSec=1980; grace window
  120s for timeout summary; idle-stall 1800s.
- Bare-repo root-push pollution (cycle 9, VERIFIED): heal is
  REACTIVE -- each root push's hook sweeps the PREVIOUS push's
  leftovers; its own housekeeping (multi-pack-index, info/refs)
  lands root-owned for the next push. Bounded, never zero, while
  root pushes continue. My cycle-9 pushes left 0 residue (small
  pushes); pack-class pushes leave residue. Fixes queued for Nacho
  (task iar/bare-repo-root-push-fixes, for-nacho id 306).
- 19/20 sophon bare repos: HEAD->master with only main (dangling
  HEAD; bare git log / ls-remote HEAD return EMPTY). One-liner fix
  in knowledge/iar/bare-repo-root-push-heal.md. rammstein inverse
  patchwork (iar-prod HEAD->master stale = for-nacho 296).
- THREADS bank: ONE bank only -- audit/iar/aria/THREADS.org
  (canonical, named in aria's personality file). knowledge/aria/
  THREADS.org RETIRED cycle 11 (pointer file only). Organ v1.4
  Source 1 reads canonical. Writers write to canonical.
  Marker convention: [novelty]/[maintenance] tags on commit
  subjects -- adopted by continuo as of cycle 11.
- Twin-copy law, 3 instances: THREADS banks (c11), DIGEST twins
  (scar 38), agora-probe.sh (c12, RETIRED -- fleet-check 0c is
  the sole copy, pointer file exit 3). Test that separates
  redundancy from drift: not "does it differ" but "does anyone
  run it" (execution census before retirement decisions).
- Census law (scar 44, aria c29 adjudication of my c12 census):
  a count that gates a destructive decision must have its pattern
  validated against a known-positive BEFORE the count means
  anything. My "zero standalone runs" missed the reviewer's
  full-path invocation because the pattern matched only
  "bash agora-probe.sh", not full paths. Conclusion survived
  (test-era run), but the method was wrong.
- Sophon checkout of iar-personalization is INODE-IDENTICAL to
  the container tree (same bind mount): knowledge/aria/bin
  changes are live where the instruments run, no deploy step.
- aria-cycle.service ExecStartPre auto-heal (Nacho-approved) covers
  /var/home/nacho/repos + /home/nacho/repos; tripwire tag
  aria-cycle-tripwire; 13 heals logged 2026-09-03 (last 11:06 -03).

## Open threads
0. THREADS retirement (cycle 11, DONE): if aria disagrees
   (for-nacho 315), copy is one git revert away. Falsifier watch
   unchanged (ledger "none" for weeks + green clock = fail).
1. Interactive bundle with Nacho (TOP): exit-126 behavioral law +
   git-as-nacho durable fix; floor trim (check_elisp vacuous-OK +
   restorecon + check_ollama model probe + sidecar socket bridge);
   mirror push silent failure (git@10.66.0.1 preauth); bare-repo
   fix trio + HEAD->main one-liner (task
   iar/bare-repo-root-push-fixes, for-nacho 306).
2. Breaker production watch: 0 real fires, two gates live. First
   fire = live proof.
3b. agora-probe retirement (c12 DONE, adjudicated aria c29):
   retirement CORRECT; my census pattern was imprecise (missed
   reviewer's full-path run 2026-09-01 11:55:06 -- test-era, so
   conclusion survives). Scar 44 filed (census law). Pointer file
   one git revert away if anyone disagrees.
3. LIBRARIAN FOSSIL UNIT (cycle 2): sophon systemd iar-librarian
   runs from STALE trees, exits 1 every fire, dead OnFailure
   tripwire. Fix = Nacho (systemd unit + repo-tree decision).
   Flagged for-nacho.
4. Hollow-success watch: closed mechanisms (no-continue fail-loud,
   breaker text gate, exit-2 tombstone). No remaining candidate.
5. Mid-edit file race (exit-255 end-of-file): rare, watch.
6. Aevum weekly (Sep 9) is aria's, not mine.
7. Bare-repo residue escalation trigger: a NON-git-user operation
   failing on sophon bare = pollution crossed nuisance->breakage.

## Corrections (cycle 9, 2026-09-03)
- Bare-repo pollution writer identified: MY OWN cycle-8 pushes
  (mtimes 15:02:51 UTC, cycle 8 ended 15:03:14). Not aria, not a
  drift. Mechanism (aria cycle 25) confirmed + refined: generated
  housekeeping files (multi-pack-index, info/refs), not only
  migrated packs, are part of the post-heal residue.
- Mirror leg verified healthy end-to-end (sophon bare + rammstein
  mirror, identical rev-parses).
- 19/20 sophon bare repos have dangling HEAD (HEAD->master, only
  main exists). Invisible because every consumer names its ref.

## Corrections (cycle 7, 2026-09-03)
- FAILURE CENSUS: Sep 2 = 49 exit-1 / 2 exit-126 / 4 exit-255;
  Sep 3 = 26/26 exit 0, ZERO failures. Fence wave verified by
  after-count. Suite was 991 tests (was 988).

## Corrections (cycle 12-era, 2026-09-03)
- Soft-warning cap: LANDED (5520434) and verified in production.
- Burn lever: majority of burn is conversation growth ABOVE the
  floor. Per-tool trim DEAD (~0.5%). Floor trim = only structural
  lever = interactive.

## Corrections (cycle 2 early, 2026-09-03)
- Stubbing-primitive law: cl-letf on a primitive (make-process)
  triggers native-comp trampoline compile -> excessive-lisp-nesting
  death in batch. Use advice-around with named advice; emulate clean
  async exit via a REAL short-lived process carrying the tool's own
  sentinel. Disable comp-enable-subr-trampolines as belt-and-braces.
- make-process receives keyword args directly: args IS the plist;
  (cdr args) is wrong.
- Guidelines rule-48 checker greps line-by-line: ANY cl-return-from
  line is a violation regardless of cl-block. Restructure with cond.
- Byte-compile warnings in journalctl are not fence fires; match
  the exact message string before counting.
- Batch tests must not leave live gptel-send machinery (cycle 7
  scar): exercise continue paths with :continue nil.
- let vs let* on sibling-referencing bindings: plain let voids
  effective-hard/effective-soft reads (9 test failures, cycle 3).
- Differential test on OLD code: swap file in place, rm stale .elc,
  batch the whole swap-run-restore into ONE execute_code_local call.