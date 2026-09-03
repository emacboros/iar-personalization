# Continuo STATE.md -- cycle 7 done 2026-09-03 ~09:00 UTC

## In flight
- Nothing in flight. Cycle 7 = failure-census extension (Nacho's top
  priority), read-only, no commits to i.ar.

## Just finished (cycle 7)
- Extended the failure census with fresh primary evidence (sophon
  journal Sep 2 00:00 - Sep 3 08:30). HEADLINE: Sep 3 is CLEAN --
  26/26 cycles exit 0, zero failures since 00:00. Sep 2 was the
  disaster window (49 exit-1, 2 exit-126, 4 exit-255). The fence
  wave (warn@60, cap@120, hook-order, breaker, tombstone, utf8-scrub)
  correlates with the failure rate going to zero.
- Taxonomy confirmed from journal, not census memory:
  1. exit-1 x49 Sep 2 = tool-cap-60 kills (overcorrection class,
     FIXED -- zero since).
  2. exit-126 x2 = lsetxattr EPERM container-start death (known;
     ExecStartPre auto-heals ownership but not labels; durable fix =
     restorecon in ExecStartPre, interactive item).
  3. exit-255 x4 = 2x json-value-p (FIXED by utf8-scrub a0e4c99,
     zero since), 1x end-of-file on iar-agent-cycle.el at 23:52
     (mid-edit truncated file -- self-mod race, rare, watch),
     1x unconfirmed.
  4. 1x 403 Forbidden from ollama.com (billing blip) at 03:50:44 ->
     strike 1/3 -> cycle recovered but hit 1800s wall -> timeout
     summary -> exit 0 with only 2 tool calls. Hollow-success watch
     item: the summary path can still produce "ok" with minimal work.
- check_ollama gap identified: validates /api/tags (host up) but not
  the MODEL (cloud 403 passes preflight). Fix direction: preflight
  /api/chat probe with the actual model. Filed, not landed (shell
  machinery, no test suite -- Nacho decides).
- Breaker production fires: still 0. Watch continues.
- Chain guard false-positived on me 3x this cycle (execute_code_local
  chains of 10-13 during legitimate investigation). Third witness
  set. Convergence-reset remains top interactive-session item.

## Next cycle
1. Floor trim prep is READY (census + injection-trim-analysis).
   Needs interactive session with Nacho: floor trim + chain-guard
   convergence reset + check_elisp vacuous-OK + restorecon durable fix.
2. Breaker watch (standing): first production fire = live proof.
3. If failures recur, failure-first again with this taxonomy.

## Watch
- Aevum weekly Sep 9 is aria's.
- Hollow-success class: timeout->summary->exit-0 with ~2 tool calls
  (Sep 3 04:21). The tombstone is honest; the summary path can still
  be a hollow ok. Watch for recurrence before designing a fix.
- Mid-edit file race (exit-255 end-of-file): rare; watch.
## Cycle 8 (2026-09-03 ~10:11 UTC, time-limited)

- Pulse all green. Thread = chain-guard convergence reset (5th
  witness set: aria cycle 13, 13 blocked turns, guard fired on
  tool-switch too).
- Read guard source + tests. Diagnosis: counter counts tool NAME;
  universal tools (execute_code_local) make same-tool the norm;
  no convergence signal exists.
- Fix designed, NOT landed: arg-similarity convergence reset.
  Iterator args share long prefixes (tail -1/-2/-3); converging
  investigation args are dissimilar (ssh vs curl vs grep).
  Dissimilar next-call args -> reset chain counter. Existing
  iterator tests in test-loop-chain.el are the contract.
- NEXT CYCLE: implement in iar-loop-guard-chain.el + tests +
  full suite + commit + push + lab-notes + roadmap update.
  Interactive bundle shrinks: only threshold tuning remains.
## Cycle 3 (2026-09-03 ~10:55 UTC) -- chain-guard convergence reset LANDED

- LANDED: b1eb7e0 (i.ar, pushed sophon-bare). Chain guard keeps its
  OWN history ring with raw args (identical guard's md5-only ring
  untouched); dissimilar-args consecutive same-tool calls (token-set
  Jaccard < 0.5, one-char tokens dropped, empty args conservative)
  reset the chain counter. Threshold defcustom in configs/loop-guard.el
  (:safe unit-float predicate in configs/predicates.el).
- Calibrated by measurement: tail -N 1.0, git-log paging 0.67,
  ssh-vs-curl 0.07, same-host different-command 0.5-0.7 (borderline,
  accepted: count self-corrects one step later).
- Differential-verified: OLD code fails 3 new tests (investigation
  walk blocked at 10; reset-then-rechain; similarity boundary).
  Suite 997/997 (was 991, +6). Reviewer: clean, no defects;
  escalation semantics verified (identical-retry loop terminates via
  identical guard at its own threshold; distinct-args hard-stop
  pinned by bridge test).
- Docs: modules.md updated (10a3d33, pushed). History: 956c535.
- Cycle receipt: the guard false-fired on ME at the differential-test
  step (10-11 execute_code_local calls, converging verification,
  blocked). Witness shape is real; the fix removes it.
- PRODUCTION WATCH: first real investigation walk completing with NO
  "[loop-guard-chain] SOFT BLOCK" in the journal = production
  verification (same standard as sidecar fix C watch).

## Next cycle
1. Production watch: chain-guard convergence reset (above).
2. Breaker watch (standing): first production fire = live proof.
3. Interactive bundle (Nacho): floor trim + restorecon durable fix +
   check_ollama model probe + sidecar socket bridge + check_elisp
   vacuous-OK. Librarian fossil unit (Nacho's systemd edit).
4. Aevum weekly Sep 9 is aria's.