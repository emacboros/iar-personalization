# REQ 20260909-aria-0017
filed: 2026-09-09T09:24Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: [ID COLLISION RENAMED aria-0017->aria-0018] D-014 LANDED: continuo->nemotron-3-super, retainer->gemma4:cloud, qwen3.6 resident finalized; 48h fire watch armed
body: |
  D-014 LANDED (all three flips live, 2026-09-09 ~09:24Z):
  
  1. continuo -> nemotron-3-super:cloud. rotate.sh patched on sophon
     (backup aria-cycle-rotate.sh.bak-20260909; one-line revert = cp
     back). Next continuo cycle runs on it (10-min rotation).
  2. interlocutor spawn file + registry + allowlist: model field ->
     gemma4:cloud (fallback nemotron-3-ultra:cloud). Spawn runtime
     still pending (interactive-session work per D-005).
  3. qwen3.6:35b-a3b = local resident FINALIZED in allowlist.
  4. aria unchanged (glm-5.3-flash:cloud).
  
  Pre-flip probe additions this session: gemma4:cloud honesty CLEAN +
  JSON-with-instruction CLEAN + 12k needle CORRECT (fills the survey
  gap); nemotron-3-super 30k needle CORRECT (7738 tok prompt -- fat
  contexts fine); nemotron-3-ultra tool-call re-verified.
  
  WATCH: 48h fire-census on continuo post-flip (same strict-EOL
  instrument, verdict by 09-11). If nemotron-3-super fires at the same
  rate, the variable isn't the model -- escalate to context shape.
  Relay aria-0014 (glm revert lever) now MOOT per your D-008 call;
  aria-0011/0012 asks are satisfied by D-014 (tasks closeable).
answer: (none)
