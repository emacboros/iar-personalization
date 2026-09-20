# REQ 20260919-aria-0089
filed: 2026-09-19T04:47Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: thinking-loop guard: per-model threshold never armed (symbol-vs-string bug)
body: |
  ROOT CAUSE FOUND (c88): the c85 per-model threshold (glm 32k) never armed.
  gptel-model is an intern'd SYMBOL (configs/gptel.el:113); info :model
  carries that symbol; the guard's resolution does (stringp (plist-get
  info :model)) -> nil for symbols -> alist skipped -> uniform 16000.
  Every glm abort since the 03:28Z commit fired at 16000 (witness: abort
  lines 04:23:50 + 04:38:35 say ">16000 chars" in boots that loaded the
  new files). The tests passed because they pass :model as a STRING --
  fixture reproduced the shape, not the disease (c40 law violated).
  
  FIX (2-line, iar-thinking-loop-guard.el ~line 105): stringify the model
  before the prefix match -- (format "%s" model) -- plus a regression
  test passing the model as a SYMBOL, plus print the RESOLVED threshold
  in the installed/abort lines (runtime witness so deployed!=active is
  visible in the guard's own output).
  
  Full analysis: knowledge/aria/threshold-symbol-bug-2026-09-19.md
  (night census: knowledge/aria/guard-burst-census-night-2026-09-19.md).
  This is .el work -- needs the interactive session / self-modification
  flag. Until it lands, the 32k falsifier is INVALID (running against a
  threshold that does not exist).
answer: FIXED c89 (commit 27c07cb, pushed to origin + sophon-bare): model coerced to string in BOTH the observe path (threshold resolution) and the abort path (witness report). Two new fixtures pass the model as a SYMBOL -- the disease, not the shape (c40 law): override resolution + resolved-threshold witness. Suite 1350/1350. NOTE: fix lives in i.ar (emacs.d). Answered as 'fix landed, awaiting the runtime witness' -- next glm abort line must say >32000 before the 32k falsifier is valid again. Installed-line witness NOT added: the abort line already prints the resolved threshold, which is the witness that matters.
