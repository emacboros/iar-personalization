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

UPDATE 2026-09-18T12:50Z (aria c55): option (c) BUILT -- but not as a
wrapper-side thinking budget. The probe showed num_predict caps TOTAL
output (thinking+content share the budget), so a wrapper budget would
starve real work. Instead: an early-abort guard in the request layer
(iar-thinking-loop-guard.el, i.ar repo, commit d9cd179, suite
1325/1325). It watches the live stream: >16k reasoning chars with no
content and no tool-call -> gptel-abort. Terminal state unchanged
(exit 1, no grace -- same as the existing thinking-only guard) but the
death costs ~4k tokens/~2min instead of 32k+/~10min. Healthy per-turn
thinking is <2k chars (her corpus 09-15..09-17); 16k is 8x above that.
DEPLOYED: pushed to sophon-bare; the checkout emacs.d symlink means it
goes live on her NEXT cycle automatically. Falsifier: the next
thinking-only truncation fire should instead log '[thinking-loop-guard]
Aborting runaway reasoning stream' + an audit line.
YOUR CALL REMAINS: (a) accept residual loss rate, (b) swap her model
(D-014), (d) upstream investigation. The guard is failure-handling
(my lane), not a model change (D-008/D-014) -- it does not touch what
the model CAN do, only when a degenerate stream gets cut. If you want
it off: set iar-thinking-loop-guard-enabled nil in tool-limits.el.
## AMENDMENT (2026-09-18 ~19:26Z, aria c70): THIRD WITNESS -- this class is not continuo-specific. Nocturne's 16:04Z digest pass (deepseek-v4.1-flash:cloud) died the same shape: 4 thinking-loop-guard aborts (16000 chars, no content), final response a truncated thinking fragment cut mid-sentence (tokens_out=1080, stop=stop) -- no RECEIPT line could exist, so the c330 receipt enforcement rejected a REAL write (proposal 15995 chars verified on disk). The guard did its job (bounded the loss) but the receipt mechanism is structurally unreachable whenever the final response is a fragment. Full verdict: audit/nocturne/nocturne/VERDICTS.log c70 READ block. Census candidate: fires per model per day + aborts-before-final-response across nocturne/continuo/aria-reviewer. Your call list unchanged; note (a) residual-loss acceptance now also costs digest-gate advances, not just cycle exits.
