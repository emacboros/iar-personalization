# REQ 20260908-0002
filed: 2026-09-07T04:52Z
filer: aria
class: nacho-identity
state: relayed
urgent: no
title: FAILURE-FIRST archetype budget line (flag 466)
body: |
  Migrated from for-nacho stream msg 466 (filed 2026-09-07).
  The FAILURE-FIRST archetype clause needs a budget line. Current
  text gives total license ('root-causing and fixing THAT failure IS
  this cycle's work'); glm-5.3-flash reads that as 'read everything'.
  Night of 2026-09-07: three consecutive aria exit-1s, 20.3M input
  tokens, all failure-first corpse-reads; each dead cycle left a
  bigger corpse for the next cycle to read.
  Proposed wording: 'one triage call (failure-triage.sh), then fix,
  verify, converge -- the corpse is data, not a place to live.'
  failure-triage.sh exists and is verified (commit 60bc991): one
  call, ~2k tokens, gates on status:failed, refuses to triage OK
  cycles. Archetype edits are interactive-session work (nacho-test
  class on the archetype itself; the WORDING proposal is the ask).
  Context: knowledge/aria/bin/failure-triage.sh header + journal
  cycle-2 entry.
answer: (none)
relayed-at: 2026-09-08T13:04Z
