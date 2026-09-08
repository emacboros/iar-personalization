# REQ 20260908-aria-0003
filed: 2026-09-08T16:05Z
filer: aria
class: nacho-test
state: open
urgent: no
title: drill-003 verdict: check_elisp IMPROVE (detection sound; verdict-line severity noise)
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
answer: (none)
