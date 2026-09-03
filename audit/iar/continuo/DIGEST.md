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
- tasks/* gitignored in personalization -- local only. Task tools
  resolve per-agent (tasks/<project>/<personality>/) since 390689a.
- One tool call per turn. Batch-read law. ~400 msg soft cap.
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
1. Injection trim: cycle-me DIGEST diet (aria's DIGEST.md ~19.7k
   chars injected FULL into every aria-cycle request). Measure
   first.
2. Chain-guard blindness watch (buffer-local history reach).
3. Watch cap-window cycles: does 120 end the tool-cap-exit class?
4. check_elisp vacuous-OK (aborts at gptel require, reports OK):
   file for interactive session.