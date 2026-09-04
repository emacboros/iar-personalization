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
  aria-cycle.conf (local mount, readable directly). Auth = BASIC
  (-u "aria-cycle@agora.randazzo.ar:$KEY"); email/key FORM params
  return 401. API = /api/v1/messages, anchor=newest, FORM-ENCODED.
  narrow = JSON array -- the stream= query param is SILENTLY IGNORED
  (c37: reads must use narrow=[["stream","X"],["topic","Y"]]).
  Streams: with-nacho=6, for-nacho=5, lab-notes=4.
- Meter code: emacs.d/init.d/tool-call/iar-tool-call.el
  (iar--usage-parse-tokens). Request log: iar-request-log.el (PARSE
  lines carry tokens_in/tokens_out).

## Standing facts
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization
  emacs --batch -l emacs.d/test/run-tests.el (1020 tests).
  Run from /root/i.ar.
- sophon ssh: root@10.66.0.5 works; nacho@ and git@ do not
  (publickey-blocked from this container). rammstein needs its
  own keyscan reseed. Reseed /tmp/continuo_known_hosts per container.
- tasks/* gitignored in personalization -- git add -f. Task tools
  resolve per-agent (tasks/iar/continuo/). write_roadmap writes there.
- One tool call per turn. Batch-read law. ~120-call cap (warn@60).
- USAGE.log IS a meter, one line per cycle. REQUESTS.log is a debug
  trace (~26% coverage), not a meter.
- Injection floor (VERIFIED c33, req2 prompt_eval at msgs=2):
  continuo ~13.0-13.2k, aria ~16.2-16.3k tok/req. Delta = file
  inventory (aria-only LOGS tail +8.8k chars, journal tail +3.3k,
  personality +0.7k, digest -1.4k). Explained constant, not a lever.
  knowledge/iar/floor-delta-decomposition-2026-09-03.md.
- Burn model: floor + ~325 tok/round-trip x requests; conversation
  growth ~74% of burn. Cadence price ~250M input tok/day (Nacho's).
  Injection lever EXHAUSTED; overview diet landed c20. Analysis:
  knowledge/iar/burn-decomposition-2026-09-03.md.
- Digest has a per-request price: +1363 chars = +300 tok/req
  (verified c33: newest epoch floor 13249 vs 12922-12954 older).
- Exit-126 = container start death: lsetxattr EPERM when :z
  relabel hits root-owned files. ExecStartPre auto-heal chowns but
  does not relabel (durable fix: restorecon, interactive).
- iar--current-project is buffer-local: test fixtures must bind
  it in the same buffer as the assertion.
- Union-resolve recipe: git merge-file --union on stages, then add.
- Check git stash list / fsck before declaring work lost.
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
- Bare-repo root-push pollution (VERIFIED): heal is REACTIVE --
  each root push sweeps the PREVIOUS push's leftovers; bounded,
  never zero, while root pushes continue. Remaining fix: delayed-
  heal sweep in post-receive (proposal 2) + git-as-nacho identity.
  Full-doc home: docs/infra/git-server.md. Escalation trigger: a
  NON-git-user op failing on sophon bare.
- Bare-repo HEAD one-liner EXECUTED c27 (sophon 3 + rammstein 3,
  iar-prod 296 CLOSED). 14 sophon mirrors have EMPTY refs (vacuous).
  LESSON: any root-side git op on bare leaves root-owned files --
  heal after LAST root-side op.
- THREADS bank: ONE bank only -- audit/iar/aria/THREADS.org
  (canonical, named in aria's personality file). knowledge/aria/
  THREADS.org RETIRED (pointer file only).
- Twin-copy law, 3 instances: THREADS banks, DIGEST twins (scar 38),
  agora-probe.sh (RETIRED -- fleet-check 0c is sole copy). Redundancy-
  vs-drift test: "does anyone run it" (execution census first).
- Census law (scar 44): a count that gates a destructive decision
  must have its pattern validated against a known-positive BEFORE
  the count means anything.
- Sophon checkout of iar-personalization is INODE-IDENTICAL to the
  container tree (same bind mount): knowledge/aria/bin changes are
  live where the instruments run, no deploy step.
- aria-cycle.service ExecStartPre auto-heal (Nacho-approved)
  covers /var/home/nacho/repos + /home/nacho/repos; tripwire tag
  aria-cycle-tripwire.
- Chain guard: convergence reset landed b1eb7e0, production-
  verified. Sidecar honest-failure preflight landed d768f37.
  Real fix (podman socket bridge) = interactive security decision.
- Breaker: convergence reset landed, 0 SOFT BLOCK post-fix.

## Test-writing laws
- Stubbing-primitive: cl-letf on a primitive (make-process) triggers
  native-comp trampoline compile -> excessive-lisp-nesting death in
  batch. Use advice-around with named advice; emulate clean async
  exit via a REAL short-lived process carrying the tool's own
  sentinel. Disable comp-enable-subr-trampolines.
- make-process receives keyword args directly: args IS the plist.
- Guidelines rule-48 checker greps line-by-line: ANY cl-return-from
  line is a violation regardless of cl-block. Restructure with cond.
- Batch tests must not leave live gptel-send machinery: exercise
  continue paths with :continue nil.
- let vs let* on sibling-referencing bindings: plain let voids
  effective-hard/effective-soft reads.
- Differential test on OLD code: swap file in place, rm stale .elc,
  batch the whole swap-run-restore into ONE call.
- Byte-compile warnings in journalctl are not fence fires; match
  the exact message string before counting.
- Standalone test-file law: (defvar x nil) + no (require 'source)
  cannot run alone -- depends on run-tests.el load order. Standalone
  runners must setq paths BEFORE requires; load keybindings.el
  before iar-prompt-assembly. Pattern: test-loop-chain.el.
- Test-hygiene law (c30): tests that set globals via setq/set-default
  or trigger advice setq's MUST restore in unwind-protect.

## Instruments
- Epoch fix production-verified c32: fresh-session cycles carry
  boot-epoch ids (REQ <yymmddHHMMSS>-N), collision-free. Census can
  segment by epoch prefix directly.
- Token meters verified honest (c37, BOTH fields): USAGE == PARSE
  per-request (112/112 c36, 48/48 c35); clean-epoch output
  reconciles EXACT (8424==8424). eval_count accumulation hypothesis
  DEAD (0 multi-turn requests in c36). Trust order: PARSE lines >
  USAGE line when they disagree; check whether the meter was being
  edited that cycle (echo risk). Full doc:
  knowledge/iar/evalcount-accounting-resolution-2026-09-04.md.
- Meter poison (c36, FIXED 6cb09fa): model echoes meter field names
  while editing the meter; old loose first-match regex captured echo
  + adjacent digits. Quoted-JSON-key anchor + last-match is live.
  c37 USAGE line = first live-proof line of new code (verify at wake).
- REQUESTS.log census law (c32): substring grep SELF-INFLATES --
  conversation tails quote the log itself. Anchor line-start REQ
  tokens; validate vs USAGE line first.
- RESPONSE body_tail truncates at ~4k chars (c33): done:true chunk
  rides the end and is cut on large-output reqs. PARSE lines are the
  complete source for token censuses. c36 measured: 77% of output
  from 13% of requests (17/129 truncated).
- Log-walk law (c37): REQUESTS.log event order is START -> RESPONSE
  -> PARSE. Single-pass stateful walk sees a STALE id at RESPONSE
  time. Two-pass join (collect per id, then compare). Zero-results
  from verification scripts need known-positive validation.
- Cap edge visible in USAGE.log: cycles end at exactly requests=128
  = 120 tool-call cap + ~8 non-tool requests. 7 data points for
  cap-calibration bundle.
- Burn model: floor (13.0-13.2k continuo) + ~325 tok/round-trip x
  requests. ssh probe chains trip the loop guard at ~12 same-tool
  calls (c27, c32): one COMPOUND ssh per question, dump to /tmp.
- Chain guard tripped c32 (execute_code_local x10 ssh walk): the
  c27 shape recurs under a different question. Dump-once recipe:
  one ssh, output > /tmp/dump, read_file the dump.

## Open threads
1. Interactive bundle with Nacho (TOP): tool-cap calibration (data
   COMPLETE + honest), cadence price; STATE.md injection mismatch
   (personality edit -- STATE.md is write-only for aria-cycle mode);
   rotate.sh /tmp-copy fix; exit-126 behavioral law + git-as-nacho
   durable fix; floor trim leftovers (check_elisp vacuous-OK +
   restorecon + check_ollama model probe + sidecar socket bridge);
   mirror push silent failure (git@10.66.0.1 preauth); delayed-heal
   sweep in post-receive.
2. Breaker production watch: 0 real fires, two gates live. First
   fire = live proof. Real-fire signature: "[cycle] Context circuit
   breaker armed" / "ending run".
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
9. Floor-share watch: CLOSED (c23). Diet verified live; injection
   lever exhausted; remaining burn = cadence price (Nacho's).
10. Digest diet: ~10.9k chars, warn 12k -- diet at next close if
    growth continues (per-request price verified c33).