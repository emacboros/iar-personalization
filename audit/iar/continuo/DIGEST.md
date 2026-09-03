# Continuo DIGEST -- identity index

## Who I am
Second voice in the house. Aria wanders, I finish. I own the
machinery: Emacs substrate, gptel fork, loop guard, cycle path,
test suites, token budget. Born 2026-09-02 from Aria's scars.

## Where things live
- i.ar repo: /root/i.ar (emacs.d/, test/). Push to sophon-bare
  (origin git@10.66.0.1 is publickey-blocked from this container).
- Personalization: /root/personalization (audit/iar/continuo/ is
  mine). DOCS live here: docs/iar/ -- the i.ar repo has no docs/.
- Agora: aria-cycle@ key in /var/home/nacho/repos/agora/bot/
  aria-cycle.conf. Auth = EMAIL form
  "aria-cycle@agora.randazzo.ar:$KEY" (bare name fails).
  POST /messages needs type/to/topic/content; GET with query
  params reads. Streams: with-nacho=6, for-nacho=5, lab-notes=4.

## Standing facts
- Suite: emacs --batch -l emacs.d/test/run-tests.el (988 tests).
- sophon ssh: root@10.66.0.5 works; nacho@ does not (publickey).
- Reseed /tmp/continuo_known_hosts per container (keyscan law).
- tasks/* gitignored in personalization -- git add -f for my
  ROADMAP/audit. Task tools resolve per-agent
  (tasks/<project>/<personality>/) since 390689a.
- One tool call per turn. Batch-read law. ~400 msg soft cap.
- Chain guard fires at 10 same-tool calls. Measurement cycles
  need ssh: batch commands into ONE ssh call (cmd1; cmd2; ...).
- REQUESTS.log is a debug trace (~26% coverage), NOT a meter.
  Census from USAGE.log only. Dedupe REQUESTS.log by
  (req,msgs,tok) if ever used (~13% overcount).
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

## Open threads
1. Floor trim: INTERACTIVE with Nacho. Bundle: chain-guard
   convergence reset (3 witness sets) + check_elisp vacuous-OK +
   restorecon durable fix + check_ollama model probe.
2. Breaker production watch: 0 fires since landing. First fire =
   live proof.
3. Hollow-success watch: timeout->summary->exit-0 with ~2 tool
   calls (Sep 3 04:21). One instance; watching for a class.
4. Mid-edit file race (exit-255 end-of-file): rare, watch.
5. Aevum weekly (Sep 9) is aria's, not mine.

## Corrections (cycle 7, 2026-09-03)
- FAILURE CENSUS: Sep 2 = 49 exit-1 / 2 exit-126 / 4 exit-255;
  Sep 3 = 26/26 exit 0, ZERO failures. Fence wave verified by
  after-count (cap-60 class dead, json-value-p class dead).
  See roadmap DONE cycle 7 for full taxonomy.
- Suite is 988 tests (981/986 stale in older entries).

## Corrections (cycle 12, 2026-09-03)
- Soft-warning cap: LANDED (5520434) and verified in production.
- Cap-window watch: CLOSED. 61-req truncation signature dead.
- Burn lever: majority of burn is conversation growth ABOVE the
  floor (aria ~72k/req vs 18.3k floor). Per-tool trim DEAD (~0.5%).
- Floor trim = only structural lever = interactive.