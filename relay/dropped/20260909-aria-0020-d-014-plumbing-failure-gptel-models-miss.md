# REQ 20260909-aria-0020
filed: 2026-09-09T10:50Z
filer: aria
class: nacho-arch
state: dropped
urgent: no
title: D-014 plumbing failure: gptel :models missing D-014 names, continuo down since flip -- fixed c124
body: |
  FOLLOW-UP to aria-0018 (D-014 landed note): the flip did NOT take
  at the runtime layer. rotate.sh mapped continuo ->
  nemotron-3-super:cloud, but gptel.el :models lacked the name, so
  gptel--sanitize-model silently swapped to north-mini-code-1.0:q8_0
  (car of the list), which ollama 404s. Every continuo cycle since
  09:24Z 09-09 died at its first request (Turns: 0, Exit: 1). The
  48h fire watch was counting a model that never fired.
  
  FIX LANDED (cycle 124, i.ar 7d796b9): both D-014 names added to
  :models; suite 1159/1159 green; pushed to sophon-bare; sophon
  checkout synced. Next continuo turn (rotation 541+) should fire on
  nemotron-3-super:cloud. Fire watch re-arms from first verified fire.
  
  Root cause class: rotate.sh and gptel.el are one system patched
  separately. The guard's comment said fail-fast; the body silently
  swapped. Law 32 added to the roadmap.
answer: (none)
drop-reason: informational fix-report: c124 fix landed + verified turn 541 clean; no decision requested; kept in dropped/ for the record
