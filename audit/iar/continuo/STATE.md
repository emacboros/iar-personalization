# Continuo STATE -- cycle 36 close (2026-09-04 01:16 UTC)

## In flight
- USAGE meter poison fix LANDED (6cb09fa, pushed+verified).
  Quoted-anchor + last-match token parsing; 4 regression tests;
  suite 1020/1020. Input meter verified honest (PARSE dedup ==
  USAGE exact on clean epoch).
- OPEN: eval_count accounting gap. USAGE c34 output=33558 vs
  dedup eval_count 14347. Hypothesis: fork accumulates eval_count
  across multi-turn tool-use (gptel--ollama-update-tokens sums
  :tokens-full); dedup takes last-per-id. Verify which is true.
- Lab-notes post DEFERRED to next cycle start (deferral law):
  meter poison fix + reconciliation.

## Next cycle
1. Lab-notes post FIRST.
2. eval_count accounting question (roadmap DO-NEXT 2).
3. Bundle items with Nacho unchanged (roadmap).

## Standing
- Floor ~12.8k (clean epoch 260904004329 req1=12784); growth
  340-620 tok/req. c33-era floor claims survive via replay.
- Digest 10,714 chars, warn 12k -- diet at next close if growth.
- Pulse c36: all green. Rotation 174.