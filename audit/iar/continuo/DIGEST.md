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
- Suite: emacs --batch -l emacs.d/test/run-tests.el (981 tests).
- sophon ssh: root@10.66.0.5 works; nacho@ does not (publickey).
- Reseed /tmp/continuo_known_hosts per container (keyscan law).
- tasks/* gitignored in personalization -- git add -f for my
  ROADMAP/audit. Task tools resolve per-agent
  (tasks/<project>/<personality>/) since 390689a.
- One tool call per turn. Batch-read law. ~400 msg soft cap.
- Chain guard fires at 10 same-tool calls. Measurement cycles
  need ssh: batch commands into ONE ssh call (cmd1; cmd2; ...).
- REQUESTS.log double-logs cycles (rotation artifact): dedupe by
  (req,msgs,tok) signature before any census (~13% overcount).
- Injection floor: aria 18.3k tok/req, continuo 13.6k; floor is
  ~42% of burn; knowledge dirs inject overview-only (loader:88).
  Request count is the lever. Analysis: knowledge/iar/
  injection-trim-analysis.md.
- Exit-126 = container start death: lsetxattr EPERM when :z
  relabel hits root-owned files in a mount path. Not a code bug.
  Tripwire auto-heal chowns but does not relabel (durable fix
  filed: restorecon in ExecStartPre, interactive territory).
- iar--current-project is buffer-local: test fixtures must bind
  it in the same buffer as the assertion.
- Union-resolve recipe for append-only log conflicts:
  git merge-file --union on :1:/:2:/:3: stages, then git add.
- Check git stash list / fsck before declaring work lost.
- A truncated read_file view is not the file; read the region
  you edit. A green check that never touched the code is not a
  check.

## Open threads
1. Soft-warning cap (census option c): warn 60 / hard 120, in-cycle
   message. Core .el -- file for interactive session.
2. Chain-guard blindness watch (buffer-local history reach).
3. Watch cap-window cycles: does 120 end the tool-cap-exit class?
4. check_elisp vacuous-OK (aborts at gptel require, reports OK):
   file for interactive session.
## Corrections (cycle 12, 2026-09-03)
- Suite is now 986 tests (981 stale in this index).
- REQUESTS.log dedupe law SUPERSEDED: REQUESTS.log is a debug trace
  (~26% of requests), not a meter. Census from USAGE.log only
  (per-request-written, aggregated at kill-emacs, no dup artifact).
  Corrected Sep2-3: aria 347.3M/4,843 reqs/53 cycles; continuo
  73.4M/1,937/31. Floor share 26%/36% (not 42%/40%). See
  knowledge/iar/usage-census-2026-09-03.md.
- Soft-warning cap: LANDED (5520434) and verified in production
  (warn text in aria cycle.log, clean exit). Thread closed.
- Cap-window watch: CLOSED. 61-req truncation signature dead; cycles
  now 67-128 reqs. Warn reaches live models.
- Burn lever moved: majority of burn is now conversation growth
  ABOVE the floor (aria ~72k/req vs 18.3k floor). Next structural
  question: context growth per tool per cycle. Measure first.
## Corrections (cycle 5, 2026-09-03)
- Context-growth census DONE (knowledge/iar/context-growth-census-2026-09-03.md):
  per-tool trim DEAD (~0.5% headroom). Burn = (floor+context) x request
  count. Growth/req ~0.5k, front-loaded then flat (no compounding).
  Sep 2 runaway (253.9k tok final prompt, ~169M, 70% of aria sample)
  predates all fences; zero msgs>400 since. Breaker landed but NEVER
  fired in production (unexercised, not unverified -- watch for first
  fire in cycle.log tails). 80k token-cap NOT justified (healthy
  final prompts 30-58k). Floor trim = only structural lever = interactive.
- invisible-cycle-fences task CLOSED (A+B+C+D all landed). Next:
  tool-cap-overcorrection reconcile (warn@60+soft@120 now live; task
  predates them) -- it is also the failure-reduction line Nacho set.