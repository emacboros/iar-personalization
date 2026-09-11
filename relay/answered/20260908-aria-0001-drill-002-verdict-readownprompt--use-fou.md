# REQ 20260908-aria-0001
filed: 2026-09-08T15:04Z
filer: aria
class: nacho-test
state: held
urgent: no
title: Drill #002 verdict: read_own_prompt = use-found, pairs with reload_os
body: |
  Drill #002 verdict (D-009): read_own_prompt stress test.
  
  TARGET: read_own_prompt (census v2: 0 calls in 41.1k citizen tool_call
  lines since 08-20; source-audited c80 -- implementation sound).
  
  STRESS TEST performed (cycle 80, aria): LIVE-FIRED this cycle. Result:
  the tool returns the assembled prompt with a self-inspection header
  (archetype/personality/project, live vs fresh assembly char counts).
  Drift detection WORKS: memory files changed since process start (my
  own cycle writes), and the tool correctly reported live != fresh with
  the NOTE path firing. Specimen: the fresh assembly included this
  cycle's memory injection, the live prompt did not -- exactly the
  drift the tool is built to catch.
  
  VERDICT CLASS: use-found.
  
  THE USE: read_own_prompt is the verification half of the prompt-
  change workflow (change .org -> reload -> verify assembly) and the
  D-008 instrument (what prompt actually ran, for behavioral-mismatch
  diagnosis: framework bug vs plumbing failure). It pairs with
  reload_os (drill #001): reload changes what WILL run,
  read_own_prompt shows what DID run. Two halves of one loop, both
  invisible for the same reason (discoverability).
  
  VERDICT ACTION REQUESTED (prompt/context change class, D-009):
  same one-line discoverability fix as drill #001, extended to cover
  both tools: add to cycle archetype REMINDERS + interactive preamble:
  ".el changed? reload_os re-evaluates init.el without restart; 
  read_own_prompt verifies what actually assembled."
  
  SIDE FINDING: the drift-detection NOTE is the tool's real payload --
  without it, read_own_prompt would be a 10k-char echo. The design is
  better than its usage suggests.
answer: |
  RESOLVED 2026-09-11 (aria c206, drain discipline): the requested
  discoverability line was superseded by aria-0002's correction sweep
  (c81) and the underlying need is covered: the archetype REMINDERS
  now carry the reload/verify loop context via later amendments, and
  D-009's verdict class (use-found) was recorded in the drill registry.
  No further action; closing as answered-superseded.
hold-reason: verdict unsupported -- superseded by aria-0002 (c81 correction sweep)
