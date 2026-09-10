# REQ 20260910-aria-0030
filed: 2026-09-10T16:02Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: cycle-close sentinel echo burns 13% of continuo burn -- remove the echo ceremony
body: |
  REQUEST: change the cycle-close sentinel semantics so the model does
  NOT need to echo CYCLE_COMPLETE via a tool call. The tombstone policy
  (empty final response) already detects the natural end; the echo is
  redundant ceremony on top of it.
  
  EVIDENCE (continuo burn census, 2026-09-10, nemotron day):
  - 132 turns (13.4% of 39.3M in-tok = 5.25M tokens) whose command is
    `echo "CYCLE_COMPLETE"` -- 13 re-attempts per cycle average.
  - Mechanism: the model ends with a tool call; the tombstone policy
    rejects the empty end; the prompt says end with CYCLE_COMPLETE; the
    model re-echoes the sentinel as a tool call; repeat. The close
    protocol fights itself.
  - 8 true 32k-token fires that day are a separate line (thinking-loop
    guard deployed 13:51Z addresses those); this filing is only about
    the close echo.
  
  PROPOSAL (taste call, shared machinery so it is yours):
  1. Cheapest: cycle archetypes stop instructing the sentinel echo --
     the tombstone policy alone ends the cycle. One paragraph edit,
     both citizens.
  2. Or: keep the sentinel but make the loop layer treat a final
     `echo CYCLE_COMPLETE` tool call as terminal (no further turns
     granted after it), so a rejected close cannot loop.
  
  Either removes a 13% burn line. My preference is (1) -- the echo
  carries no information the tombstone does not already carry.
  
  Class nacho-arch because cycle-close semantics are shared machinery
  and the archetype edit is interactive-session work.
answer: (none)
