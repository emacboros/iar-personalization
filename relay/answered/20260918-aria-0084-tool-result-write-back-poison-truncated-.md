# REQ 20260918-aria-0084
filed: 2026-09-18T08:26Z
filer: aria
class: nacho-arch
state: answered (c50 recurrence census appended; guard build awaits ratification)
urgent: no
title: tool-result write-back poison: truncated reads written back as whole files
body: |
  CLASS CONFIRMED c49 (aria, 2026-09-18). iar--truncate-tool-result
  middle-truncates any tool result >10000 chars. When a model then
  writes a file back from that truncated view (write_file or heredoc),
  the notice line becomes file content and the middle of the file is
  silently deleted. Witness: test-loop-chain.el poisoned 09-17 22:26
  local, ~60 failed fix attempts across 3+ cycles, the poisoned file
  was COMMITTED (5df65f4) and the suite "passed" because the deleted
  tests were never counted. Restored 9730190 (16/16 green, pushed).
  
  PROPOSED GUARD: refuse any file write whose content contains the
  truncation-notice format string. It touches the shared tool layer
  (iar-tool-call.el write path), so it needs your ratification. Zero
  plausible false positives -- that string is never legitimate content.
  
  Also worth your eyes: continuo burned ~60 tool calls over 3 cycles
  on this because her context kept holding the truncated view. The
  guard would have caught the FIRST write. Doc:
  knowledge/iar/tool-result-writeback-poison-2026-09-18.md
answer: (none)
Recurrence census (c50, 2026-09-18 ~09:15Z): NEGATIVE post-heal.
- continuo REQUESTS.log 05-08Z (post 9730190 restore): ZERO truncation
  notices in 3698 tool results; her write_file bodies to
  test-loop-chain.el contain no notice strings (checked raw).
- All 67 notices today are 03-04Z = tail of the poison fight itself
  (reads of the still-broken file + .bak). Confirms c49 hypothesis:
  the overnight 6/8 spike was the fight, not a standing rate.
- Exposure remains LIVE: test-loop-chain.el is 13106 chars (every
  read of it truncates); 8 files >10k sit in continuo's read set
  (JOURNAL.org 100k, cycle-2026-09-18.log 140k, HISTORY.log 78k...).
  Write-path guard does not exist yet (grepped tool-call layer).
- Suite verified independently: 1309/1309, all 16 chain tests pass.
  Her "16/16" claim was true. The count (not the pass) is the
  amputation falsifier.
Guard prototype remains one string-match in the write path; awaiting
ratification (nacho-arch class, shared tool layer).
