# REQ 20260918-aria-0085
filed: 2026-09-18T12:18Z
filer: aria
class: nacho-identity
state: open
urgent: no
title: continuo thinking-truncation rate climb: 0%->54% in 4 days (D-014 lever)
body: |
  # 2026-09-18 c54 -- continuo thinking-truncation rate CLIMB (4-day trend)
  
  Filed by aria (cycle c54). Follow-up to the c47 note in 0083 ("if it
  holds tomorrow, a model-mapping lever filing follows"). It held.
  
  ## The census (journald aria-cycle.service, sophon)
  
  | day | truncation fires | continuo cycle starts | rate |
  |---|---|---|---|
  | 09-10..09-14 | 0 | n/a | 0% |
  | 09-15 | 0 | 130 | 0% |
  | 09-16 | 2 | 397 (polluted by guard-fight re-runs) | ~0.5% |
  | 09-17 | 4 | 37 | ~11% |
  | 09-18 (to 12:07Z) | 7 | 13 | ~54% |
  
  Monotonic climb over 4 days. Her 12:07Z cycle died on it (63
  requests, 1.9M tokens, truncation at msgs=126).
  
  ## Correlated signal: her context per request is climbing
  
  avg input tokens/request (USAGE.log): 09-15 = 30.4k, 09-17 = 36.3k,
  09-18 = 49.7k. Bigger context -> longer thinking -> more likely a
  single response runs to the 32768 cap thinking-only. The two signals
  are consistent: the disease is context growth feeding runaway
  thinking.
  
  ## What it costs
  
  Each fire = a whole cycle lost (no grace, exit 1) + the burned
  requests before the truncation. Today that is ~7 cycles of
  continuo's 13. Her throughput is collapsing; my cycles are unaffected
  (glm-5.3-flash: 0 fires ever).
  
  ## The ask (yours: D-014 model mapping; D-008 bars cycles from
  changing models)
  
  Options, your call:
  (a) accept the loss rate (she still lands ~46% of cycles today);
  (b) swap her model (D-014 lever);
  (c) a wrapper-side thinking budget (cap thinking tokens below the
      32768 hard stop so the guard demotes instead of killing -- I can
      build this if you rule it in-bounds for me);
  (d) investigate nemotron's thinking-length sensitivity to context
      size upstream before deciding.
  
  My lean: (c) is cheap and reversible, and (d)'s data would tell us
  whether (b) is necessary. But the mapping is yours.
  
  Class: nacho-identity (model mapping = D-014, your decision right).
answer: (none)
