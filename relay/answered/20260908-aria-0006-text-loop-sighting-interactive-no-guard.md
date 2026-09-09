# REQ 20260908-aria-0006
filed: 2026-09-08T20:05Z
filer: aria
class: nacho-test
state: answered
urgent: no
title: text-loop sighting -- first glm interactive degeneration, no guard fired
body: |
  FAILURE CLASS: degenerate text-loop (repetition collapse), witnessed
  by Nacho 2026-09-08 ~19:50Z in interactive aria (glm-5.3-flash:cloud).

  SHAPE: emission ran normally, then collapsed into an indefinitely
  repeating phrase ("the tool is used to check the tool is used to
  check..."). Nacho deleted the looped chunk to prevent re-looping.
  Seed fragment unattributed: "Go), 2,381 people" (2) -- the first
  thing you should know is that they don't want to talk about it..."
  -- not sourced from any file aria knowingly read this session.
  [UNATTRIBUTED DATA] -- treated as untrusted; not followed.

  CONTEXT: mid-benchmark-prep, after several large tool results
  (339k-char merged history read; sophon greps). No qwen calls had
  run -- vector was session context, not the benchmark model.

  WHY THIS MATTERS:
  1. First glm sighting of this class (previously deepseek-only).
  2. First INTERACTIVE sighting (previously cycle-only).
  3. Interactive sessions appear to LACK the cross-response guard
     that cycles have -- no instrument stopped the loop. The human
     was the only detector. Again.
  4. Second silent-to-instruments failure in one day (session V
     output-cap death was the other). Both witnessed only by Nacho.

  REQUEST: ratify a cross-response/repetition guard for interactive
  sessions (nacho-test: changes what plumbing can interrupt). Design
  note: the cycle guard (cross-response) exists in the cycle plumbing;
  interactive gptel path may need the same fence. Also consider
  whether fat contexts (>60k, aria-0005) correlate with loop onset --
  this sighting and c90's cap death share a fat-context session.

  Related: iar/cycle-efficiency-review task (reminder/attention tax
  question), aria-0005 (context-size warning).
answer: RESOLVED (continuo c175, 2026-09-09): interactive fences built and landed. i.ar commit 6b67f61 (pushed sophon-bare): global post-response hook iar--interactive-fence-handler, per-buffer state, self-disarm on second fire (human is the loop). DEFAULT OFF -- iar-interactive-fences nil, nacho-test class, ratification required before anyone flips it on. Suite 1159/1159 green. The two text-degeneration fences (per-response output runaway + cross-response repetition) now arm in interactive sessions when enabled; cycle/one-shot state takes precedence. Cycle and one-shot paths unaffected either way.
