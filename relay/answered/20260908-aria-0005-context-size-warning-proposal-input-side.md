# REQ 20260908-aria-0005
filed: 2026-09-08T18:36Z
filer: aria
class: nacho-test
state: answered
urgent: no
title: context-size warning proposal (input-side visibility fence)
body: |
  Filing aria-0005: context-size warning proposal (nacho-test class)
  PROPOSAL: a context-size warning, fence class (nacho-test: changes
  what the cycle can see about itself; interactive ratification per
  D-005/D-006).
  
  CENSUS (knowledge/aria/input-burn-census-2026-09-08.md): today's
  aria REQUESTS.log -- 170 of ~1000 requests (16%) carry tokens_in
  >60k and hold 27.2% of ALL input burn. The fat-history tail is a
  quarter of the day's input. The model cannot see its own context
  size; the plumbing can (REQUESTS.log PARSE lines already carry
  tokens_in).
  
  REQUEST: add a context-size warning to the cycle plumbing -- either
  in the tool-result trailer ([t+MM:SS/WALL cNN/CAP] already exists)
  or as an injected system line -- firing when tokens_in > ~60k:
  "CONTEXT FAT: >60k tokens. Converge: close the thread, batch
  remaining work, write records before starting anything new."
  
  Why a fence and not advice: the same-tool warning (census, fires
  once at 40 calls) does not converge behavior -- proven twice (aria
  c57, continuo c151). The cap halving worked because it was
  structural. A per-request size signal is structural visibility the
  model currently lacks. Threshold ~60k chosen from the census shape
  (p90 = 63k; the >60k class is where burn concentrates).
  
  Sibling instruments: trailer (time/calls), cap halving (output),
  census-window.sh (failure window). This closes the input-side
  visibility gap. If ratified, implementation is iar core .el
  (iar-tool-result-budget.el or the request log layer) -- interactive
  session work, cycles never touch it.
answer: |
  RATIFIED 2026-09-08 session VI (Nacho), EXTENDED beyond the proposal:
  not just a warning -- a soft/hard cap architecture mirroring the
  tool-call fence. Soft warn at 128k tokens (block one call with
  converge notice, fires once); hard cap at 512k tokens (block all
  non-memory calls with landing instruction; 5 ignored blocks end the
  run). Nacho's caps from interactive-session observation (glm-5.2,
  non-linear growth); conceded to data if census disagrees later.
  LANDED: i.ar a0c5a71 -- iar-context-fence.el + reqlog tokens-in
  publish + config + 11 tests, suite 1136 green. Reload on sophon
  cycle containers picks it up at next container start (ExecStartPre
  pull); interactive sessions unfenced by design.
