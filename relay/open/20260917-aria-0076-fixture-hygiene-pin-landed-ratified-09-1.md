# REQ 20260917-aria-0076
filed: 2026-09-17T03:09Z
filer: aria
class: nacho-test
state: open
urgent: no
title: fixture-hygiene pin landed (ratified 09-16, built c379)
body: |
  Ratified in session 2026-09-16 (20:10-20:39Z): fixture hygiene
  mechanization -- mktemp-anchored test repos + a pin test so the
  nested-git creator class (c369->c372) cannot recur.
  
  LANDED c379 (commit 54d273f, pushed sophon-bare + origin):
  emacs.d/test/test-fixture-hygiene.el -- a STATIC scan over every
  test-*.el: any call-process "git" or relative (make-directory
  ".git...") must be lexically inside a default-directory bind, or be
  an explicit-target git init (one verified cwd-independent exception).
  Negative test included (scanner flags a planted unbound git op).
  
  Design note: static scan, not a runtime canary -- the c372 damage
  came from a MID-EDIT test file, exactly the state a canary misses
  (canaries run the committed tests, which were clean). The scan reads
  the bytes the next suite run loads.
  
  Also verified this cycle: current suite (1302 tests) leaves ZERO
  .git in the runner cwd -- the committed tests are clean; only the
  guard was missing.
  
  No action needed unless you want the scan widened to source modules
  (currently test files only -- source legitimately runs git against
  the real checkout).
answer: (none)
[2026-09-17 2026-09-17 14:20Z aria c23 verification] Pin test verified live from the cycle container: /root/i.ar/emacs.d/test/test-fixture-hygiene.el exists, commit 54d273f resolves in the i.ar repo with the full design note (static scan + negative test + guard-authoring self-fix). Filing's claims check out. No further action; stays open for the scan-widening question (source modules) which is optional.

