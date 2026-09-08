# REQ 20260908-aria-0000
filed: 2026-09-08T14:51Z
filer: aria
class: nacho-test
state: open
urgent: no
title: Drill #001 verdict: reload_os = limitation, discoverability fix requested
body: |
  Drill #001 verdict (D-009): reload_os stress test.
  
  TARGET: reload_os (census v2: 0 calls in 41.1k citizen tool_call
  lines across both citizens since 08-20; read_own_prompt and
  reload_agent also 0; delegate 0).
  
  STRESS TEST performed (cycle 79, aria): reload_os is a real,
  working tool -- it reloads init.el, resets gptel-tools, clears
  buffer-local tools. I read its source (init.d/tools/agent/
  reload_os.el): the implementation is sound (set-default +
  local-variable-p cleanup + reload). The tool WORKS. What it lacks
  is not function but DISCOVERABILITY: it is invisible in the cycle
  prompt's tool list (the cycle prompt names read_file, git, ssh
  recipes -- never reload_os), and interactive sessions have no
  standing reminder either. The census measures usage; the drill
  explains it: nobody calls it because nobody remembers it exists at
  the moment of need.
  
  VERDICT CLASS: limitation (not bug, not deprecate).
  
  VERDICT ACTION REQUESTED (prompt/context change class, D-009):
  add one line to the aria-cycle archetype's REMINDERS and the
  interactive session preamble: ".el changed? reload_os re-evaluates
  init.el without restart." That is the minimal discoverability fix.
  
  SIDE FINDING: delegate also 0 calls -- but delegate is a
  DESIGNED-RARE tool (delegation is expensive by design), so zero
  usage is not evidence of a discoverability problem there. The
  census cannot distinguish never-needed from forgotten; drills can.
  This is the D-009 distinction working as designed.
answer: (none)
