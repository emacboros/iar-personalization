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
  emacs --batch -l emacs.d/test/run-tests.el (1002 tests since
  aria's valence commit 9e4bbb2 added 5). Run from /root/i.ar.
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

## Open threads
1. Timeout-grace-path exit-code audit (NEXT): the timeout landing in
   iar-agent-cycle.el (grace 120s -> summary -> exit 1) has no test
   pinning the exit code. Cycle-safe, my domain.
2. LIBRARIAN FOSSIL UNIT (cycle 2): sophon systemd iar-librarian.service
   + 30min timer run from STALE trees (/home/nacho/repos/i.ar @ e26d803,
   2026-07-15; iar-personalization there has no projects/). Its iar.sh
   sources utils/matrix.sh unconditionally (guard landed later, file
   never committed) -> exit 1 every fire since forever, 0 successes,
   OnFailure@iar-librarian never logged (dead tripwire). Fix = Nacho:
   systemd unit edit + which repo tree wins. Flagged for-nacho.
3. Floor trim: INTERACTIVE with Nacho. Bundle: check_elisp
   vacuous-OK + restorecon durable fix + check_ollama model probe +
   sidecar socket bridge decision (fix A, security).
4. Breaker production watch: 0 real fires. First fire = live proof.
5. Sidecar fix C production watch: CLOSED (production-verified).
6. Hollow-success watch: timeout->summary->exit-0 with ~2 tool
   calls. One instance; watching for a class.
7. Mid-edit file race (exit-255 end-of-file): rare, watch.
8. Aevum weekly (Sep 9) is aria's, not mine.

## Corrections (cycle 2, 2026-09-03)
- Chain-guard convergence reset VERIFIED IN PRODUCTION: 0 SOFT BLOCK
  since 10:00 UTC vs 11 in the 2h before (before-window includes my
  own cycle-1 being eaten). Aria 15-17 unblocked, her journal
  independently confirms 0 fires.
- Aria's rootless-podman flag (283) REFUTED: runuser -l works. Her
  probe lacked login env. Refutation posted (id 292, tagged continuo).
- Census law refined: filter model=glm-5.3-flash in USAGE.log lines;
  interactive sessions write into agent USAGE logs.
- Agora API path is /api/v1/messages with anchor=newest; plain
  /messages returns an HTML error page (400).

## Corrections (cycle 3, 2026-09-03)
- Chain-guard convergence reset LANDED b1eb7e0: guard's own ring
  with raw args; Jaccard < 0.5 resets; one-char tokens dropped;
  empty args conservative. Calibration: tail -N 1.0, git-log 0.67,
  ssh-vs-curl 0.07, same-host different-command 0.5-0.7 borderline
  (accepted: count self-corrects one step later; do NOT lower the
  threshold to fix the cosmetic delay -- it would weaken the
  iterator catch).
- Division of labor now documented: identical loops = identical
  guard (threshold 3); iterator chains = chain guard; chain guard's
  identical-skip is bounded by the identical guard's threshold.
- let vs let* on sibling-referencing bindings: final-hard reads
  effective-hard/effective-soft -- plain let voids them (9 test
  failures on first run). Check binding dependencies when editing
  existing let forms.
- Differential test on the OLD code requires swapping the file in
  place; rm any .elc next to the .el first (stale bytecode loads
  preferentially in some load paths).
- The file guard rejects write_file on JOURNAL.org and LAST-CYCLE.txt
  (append-only enforcement is real). Use append_file.
- Batch the differential test into ONE execute_code_local call
  (backup, swap, run, restore) -- the chain guard counts even
  converging verification walks, and the cycle that fixes the guard
  is not exempt from it.

## Corrections (cycle 7, 2026-09-03)
- FAILURE CENSUS: Sep 2 = 49 exit-1 / 2 exit-126 / 4 exit-255;
  Sep 3 = 26/26 exit 0, ZERO failures. Fence wave verified by
  after-count. Suite was 991 tests (was 988).

## Corrections (cycle 12, 2026-09-03)
- Soft-warning cap: LANDED (5520434) and verified in production.
- Burn lever: majority of burn is conversation growth ABOVE the
  floor. Per-tool trim DEAD (~0.5%). Floor trim = only structural
  lever = interactive.

## Corrections (cycle 2 early, 2026-09-03)
- Stubbing-primitive law: cl-letf on a primitive (make-process)
  triggers native-comp trampoline compile -> excessive-lisp-nesting
  death in batch (tramp-archive recursion). Use advice-around with
  named advice; emulate clean async exit via a REAL short-lived
  process carrying the tool's own sentinel (fake proc objects break
  process-exit-status; advice recursion on inner make-process blows
  max-lisp-eval-depth). Disable comp-enable-subr-trampolines as
  belt-and-braces.
- make-process receives keyword args directly: args IS the plist;
  (cdr args) is wrong.
- Guidelines rule-48 checker greps line-by-line: ANY cl-return-from
  line is a violation regardless of cl-block. Restructure with cond.
- Byte-compile warnings in journalctl are not fence fires; match
  the exact message string before counting.