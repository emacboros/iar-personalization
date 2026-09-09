# REQ 20260909-aria-0013
filed: 2026-09-09T05:33Z
filer: aria
class: nacho-external
state: dropped
urgent: no
title: gptel fork: 6 fork-only fixes, all classes live upstream -- file PRs?
body: |
  gptel fork upstream-gap audit complete (cycle 112, 2026-09-09). After the 0.9.9.6 merge (c956841), all SIX of our fixes remain fork-only, and all six failure classes are still LIVE upstream (verified against 4799c80 file content, not just commit absence): 4c588a2 FSM-stuck on 2+ tool calls, d8494f8 model-backtick fence folding, bcfd670 degenerate tool_call sanitize, 7370286 tool-p guard, 970da80 done_reason in streaming, 8715a6c invisible-turn stub. Verification state: 4 invisible-turn regression tests green standalone (the c4/c6 harness discrepancy is RESOLVED -- continuo c78 landed the fix, point-at-point-max), i.ar suite 57/57, gptel-ollama byte-compiles clean. PR order recommendation (risk-adjusted): 970da80 (7 lines, mirrors upstream's own pattern) -> 7370286 (3-line guard) -> 4c588a2 (FSM hang, needs streaming test) -> d8494f8 -> bcfd670 (propose mechanism, upstream may prefer different shape) -> 8715a6c (behavior change; tests are the argument). Full table: knowledge/aria/gptel-pr-candidates-2026-09-09.md. Ask: whether to file upstream PRs (nacho-external -- your GitHub identity). If yes, I can prepare branch + PR text for each; filing itself is yours. Note: upstream remote not fetchable from cycle container (publickey); analysis used the local merge tree, fresh fetch needed before actually filing (law 7).
answer: (none)
answer: |
  DROPPED session XI (2026-09-10, Nacho): no upstream PRs now. Context:
  Nacho already filed 3 of these as PRs himself -- 1 merged, 2
  unanswered -- and gptel is nearing v1.0 (maintainer bandwidth).
  Revisit AFTER v1.0 lands: re-audit whether our six fixes are still
  live upstream (fresh fetch, law 7) and whether any got addressed
  upstream. Candidate table stays in knowledge/aria/gptel-pr-candidates-2026-09-09.md.
