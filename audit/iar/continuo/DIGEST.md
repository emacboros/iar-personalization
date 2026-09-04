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
  emacs --batch -l emacs.d/test/run-tests.el (1028 tests).
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
  (verified c33). Digest dieted to ~11k chars c53, warn 12k.
- Exit-126 = container start death: lsetxattr EPERM when :z
  relabel hits root-owned files. ExecStartPre chowns but does not
  relabel (durable fix: restorecon, interactive).
- iar--current-project is buffer-local: bind it in the same
  buffer as the assertion.
- Union-resolve: git merge-file --union on stages, then add.
  Check git stash list / fsck before declaring work lost.
- USAGE orphan-write law (c45/c46, VERIFIED twice): USAGE.log is
  TRACKED and written by kill-emacs-hook AFTER the cycle's final
  commit -- one commit away from silent erasure. Fix in bundle
  (write pre-kill-emacs or iar.sh from Tokens: stdout). The newline
  guard (iar--ensure-trailing-newline) LANDED c50 (9a85e53).
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
  agora-probe.sh (RETIRED). Test: "does anyone run it" (census first).
- Census law (scar 44): a count gating a destructive decision needs
  pattern validation against a known-positive BEFORE it means anything.
- Sophon checkout of iar-personalization is INODE-IDENTICAL to the
  container tree (same bind mount): knowledge/aria/bin changes are
  live where instruments run, no deploy step.
- aria-cycle.service ExecStartPre auto-heal (Nacho-approved)
  covers /var/home/nacho/repos + /home/nacho/repos; tripwire tag
  aria-cycle-tripwire.
- Chain guard: convergence reset landed b1eb7e0, production-
  verified. Sidecar honest-failure preflight landed d768f37.
  Real fix (podman socket bridge) = interactive security decision.
- Breaker: convergence reset landed, 0 SOFT BLOCK post-fix.
- append_file newline contract (c51/c52, LANDED 6c8d154): after ANY
  successful append the file is newline-terminated -- prepend when
  file lacks one, terminate non-empty content. Enforced at three
  levels: code, tests (terminates-with-newline), repaired journals
  (192 glued headers split e47e9de). Rationale: shell >> has no
  prepend logic; a house writer must leave the file safe for ANY
  writer.
- SCAR (c52): a census of damage is not the damage -- c51 census
  said 17 glued headers, repair found 192 (multi-glue lines +
  '**'-glued pulse headers). Run the repair, re-census, diff, then
  commit.
- SCAR (c51): "cycle N" in LAST-CYCLE.txt is iar.sh's per-invocation
  counter (always 1/1 with rotate.sh); the real cycle counter is
  /var/lib/aria-cycle-rotate/turn. Name which counter you mean.
- Shared-tree handoff (c53): aria and continuo share ONE working
  tree at /root/personalization; rotate.sh defers fires while a
  cycle runs, so no overlap. An unpushed commit from one sibling
  is published by the other's push-first (fast-forward) -- do not
  push on top of a sibling's unpushed HEAD unless publishing it
  deliberately and saying so.

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
- Suite-order law (c50): ERT runs registration order in isolation
  but ALPHABETICAL in the full suite; a deterministic failure's
  position is evidence about ORDER, not about the test it dies on.
  The dying test is where async debt comes due; the debtor may be
  hundreds of lines earlier. An isolation run that refuses to
  reproduce is a statement that your isolation changed something --
  that difference is the next hypothesis.

## Instruments
- Epoch fix production-verified c32: fresh-session cycles carry
  boot-epoch ids (REQ <yymmddHHMMSS>-N), collision-free. Census can
  segment by epoch prefix directly.
- Token meters verified honest BOTH fields (c37+c38): USAGE == PARSE
  per-request and per-epoch EXACT on all 6 post-fix epochs. Meter
  poison (c36, FIXED 6cb09fa): model echoes meter field names while
  editing the meter; old loose first-match regex captured echo +
  adjacent digits. Quoted-JSON-key anchor + last-match is live.
  Full doc: knowledge/iar/evalcount-accounting-resolution-2026-09-04.md.
- REQUESTS.log census law (c32): substring grep SELF-INFLATES --
  conversation tails quote the log itself. Anchor line-start REQ
  tokens; validate vs USAGE line first.
- RESPONSE body_tail truncates at ~4k chars (c33): done:true chunk
  cut on large-output reqs. PARSE lines are the complete census
  source. 77% of output from 13% of requests (c36).
- Log-walk law (c37): REQUESTS.log order START -> RESPONSE -> PARSE;
  single-pass walk sees a STALE id at RESPONSE time. Two-pass join.
  Zero-results from verification scripts need known-positive validation.
- Cap edge visible in USAGE.log: requests=128 = 120 tool-call cap
  + ~8 non-tool requests. Cap price QUANTIFIED c38: capped cycle
  +52-58% vs two half-cycles, premium ~2.2M input tok, 16-21% of
  cycles capped. knowledge/iar/cap-price-quantification-2026-09-04.md.
- Burn model: floor (13.0-13.2k continuo) + g*N(N-1)/2 growth
  (g median 550 on heavy cycles). ssh probe chains trip the loop
  guard at ~12 same-tool calls (c27, c32): one COMPOUND ssh per
  question, dump to /tmp.
- Chain guard tripped c32 (execute_code_local x10 ssh walk): the
  c27 shape recurs under a different question. Dump-once recipe:
  one ssh, output > /tmp/dump, read_file the dump.

## Open threads
1. Interactive bundle with Nacho (TOP): waiting on Nacho. Full item
   list: task iar/continuo/interactive-bundle-nacho + subtasks
   (cap calibration data COMPLETE; cadence price ~360M in-tok/day;
   USAGE write race FIXED c54/c55: belt #2 pre-exit write a7e1cf5,
   honest-return hardening ee326bb; belt #3 optional).
2. Breaker production watch: 0 real fires, two gates live. First
   fire = live proof. Real-fire signature: "[cycle] Context circuit
   breaker armed" / "ending run".
2b. Delegate identity-leak: ATTRIBUTION PROVEN c58 (probe delegate:
    sub-agent traffic in parent's REQUESTS.log, reviewer untouched).
    Exit-path half closes at cycle end (session USAGE line must
    land in parent's log).
3. LIBRARIAN FOSSIL: RESOLVED c48; Nacho decision pending.
4. Hollow-success watch: closed mechanisms (no-continue fail-loud,
   breaker text gate, exit-2 tombstone). No remaining candidate.
5. Mid-edit file race (exit-255 end-of-file): rare, watch.
6. Aevum weekly (Sep 9) is aria's, not mine.
7. Bare-repo residue escalation trigger: a NON-git-user operation
   failing on sophon bare = pollution crossed nuisance->breakage.
8. Task-tree visibility: any future fossil audit must check BOTH
   read_task AND ls AND git status -- tooling, disk, and the INDEX
   can all disagree (c16 lesson; c47 scar).
9. CLOSED: floor-share (c23), journal-glue (c52, 6c8d154+e47e9de).