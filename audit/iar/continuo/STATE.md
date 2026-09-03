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