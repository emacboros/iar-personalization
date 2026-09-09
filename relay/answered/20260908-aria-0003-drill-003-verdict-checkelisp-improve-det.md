# REQ 20260908-aria-0003
filed: 2026-09-08T16:05Z
corrected: 2026-09-08T16:24Z
filer: aria
class: nacho-test
state: answered
urgent: no
title: drill-003 verdict: check_elisp IMPROVE -- FIX LANDED (67ab1a1)
body: |
  REQ: drill-003 verdict -- check_elisp IMPROVE (detection sound, verdict-line noise)
  
  Drill #003 ran (c82, aria): 7-probe defect matrix against check_elisp,
  ground truth = raw `emacs --batch` byte-compile run in the same cycle.
  
  FINDING: detection is SOUND. Parens errors, unterminated strings,
  undefined functions, free variables, unused lexical variables -- all
  caught, matching raw byte-compile exactly. The one miss (unused
  dynamic-binding let-vars) is silent in raw byte-compile too -- a
  bytecomp behavior, not a tool bug. Self-check passes. Control (valid
  file) reports clean.
  
  The "performs-poorly" reputation traces to OUTPUT SHAPE, not
  detection: the verdict line says "ISSUES FOUND" for warning-level
  noise (a missing lexical-binding directive reads the same as an
  unbalanced paren). An instrument's failure class can be its verdict
  line.
  
  VERDICT: IMPROVE (not scrap, not replace).
  ACTION (aria-reversible, no nacho-test needed): add severity to the
  verdict line -- OK / WARNINGS / ERRORS. The text already distinguishes
  them; the verdict line does not. I will make this change in a future
  cycle with the test suite green (init.d/tools/code/check_elisp.el is
  .el code, self-modification class, not prompt/identity).
  Scope note for AGORA v2 build item 6 (immune system): check_elisp is
  single-file; the promotion gate will need a changed-file-set loop
  around it.

  ## CORRECTION (2026-09-08 16:24Z, same cycle -- fix landed early)

  The fix landed THIS cycle, not "a future cycle": 67ab1a1 on i.ar main.
  - iar--check-elisp-severity classifies :errors / :warnings / clean.
    Anchors on bytecomp log line structure (`file:line:col: Error:` /
    `Warning:`) plus the tool's own error prefixes. Unknown diagnostic
    shapes classify as :warnings (conservative -- never claim OK when
    something was found).
  - Verdict lines: "OK: ..." / "WARNINGS in <file>" / "ERRORS in <file>".
  - 5 new tests; suite 1130 tests, 1129 pass, 1 expected-fail fixed
    (test-check-unbalanced-parens now expects the ERRORS verdict).
  - Live-fire evidence (tool_result lines, not plan): w1/w2/w3/e1 ->
    "WARNINGS in w1.el:" etc.; e4/e5 -> "ERRORS in ..."; clean control
    -> "OK: No issues found in check_elisp.el."
  - Pushed to sophon-bare (origin push failed: no key for
    git@10.66.0.1 from this container -- known, sophon-bare is the
    working remote; mirror to rammstein happens server-side).
  - One process note: the first live-fire run FAILED with "ERRORS in
    w1.el" for warning-only files because the stub harness lacked
    iar--non-blank-p (byte-compile-check returned an error string for
    every file). The stub was wrong, not the tool. Second run with the
    helper stubbed correctly shows the true behavior. Cited both runs
    here because a correction filing that hides its own failed run
    would repeat the drill-002 disease.
answer: VERIFIED c103: fix 67ab1a1 confirmed in i.ar main; verdict-line severity classes (OK/WARNINGS/ERRORS) match the filing's live-fire evidence. No further cycle action pending; candidate for answered-archive at debrief.
