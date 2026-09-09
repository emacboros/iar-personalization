# REQ 20260909-aria-0015
filed: 2026-09-09T09:16Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: continuo replacement survey: nemotron-3-super STRONG candidate (~7x cheaper, probes clean); minimax honesty FAIL; cost math landed
body: |
  Continuo model replacement SURVEY (interactive, Nacho-directed). Constraint
  from Nacho: do NOT revert continuo to glm-5.3-flash (same model as aria
  defeats the two-substrate design); find an alternative cloud model in
  budget. Urgency: fires are ongoing (20 in window, 655k wasted output tok,
  6.5% of continuo output burn), model-side, load falsified.
  
  Probed live from sophon ollama (tool-call / multi-turn / JSON / honesty /
  needle / routing probes, same battery shape as the nemotron survey):
  
  1. nemotron-3-super:cloud -- STRONG CANDIDATE. $0.015/$0.015/$0.60 per M
     (in/cached/out) = ~$90/mo at continuo's burn, ~7x cheaper than
     deepseek-v4-flash ($616/mo uncached). Probes: single tool call CLEAN,
     multi-turn integration CLEAN, JSON clean WITH system instruction
     (schema-only fails -- 3-model pattern now 4), honesty probe CLEAN
     (refuses to confabulate on empty context), 12k needle CORRECT
     (2138 tok prompt), routing CLEAN (read_file over run_cmd).
  2. minimax-m2.7 -- tools clean, multi-turn clean, but HONESTY FAIL:
     answers "what runs on my server" with generic how-to instead of
     "I cannot see that". $865/mo. Out on the anti-drill-002 virtue.
  3. gemma4:cloud -- tools clean, multi-turn clean. $390/mo. Not yet
     honesty/needle-probed. Mid-priced fallback.
  4. nemotron-3-nano:cloud -- SILENT FAILURE: tool call request returns
     empty content AND empty tool_calls. Disqualified at $173/mo.
  5. gpt-oss:120b -- tools clean (think default), honesty clean, but
     LOCAL (load_duration 25s = it loads on sophon GPU), not cloud; also
     $433/mo. Not a continuo fit (evicts the eye's card).
  
  COST MATH: knowledge/aria/continuo-model-cost-math-2026-09-09.md.
  BIGGEST UNKNOWN: ollama cloud prefix caching -- if cached-input pricing
  applies automatically to the re-sent base prompt, deepseek's real cost
  drops ~16x on input and the calculus changes. Needs an account-usage
  check (your ollama dashboard) or a billing-cycle datapoint.
  
  ASK (nacho-arch + nacho-money): ratify nemotron-3-super:cloud as
  continuo's mapping (one line in rotate.sh, same lever as aria-0014) OR
  direct a different pick. My recommendation: nemotron-3-super, with a
  48h fire-census watch after the flip (same instrument, verdict by 09-11).
answer: D-014 ratified (09-09 session IX): nemotron-3-super:cloud = continuo mapping. Landed in rotate.sh 09:24Z with backup. 48h fire watch armed, verdict by 09-11. Caching question stays open for Nacho dashboard check.
