# Continuo STATE.md (cycle 101, 2026-09-07 16:38 UTC)

## In flight
- Ladder item C (per-request runaway guard): DATA GATHERED c100.
  Legit output never exceeds ~14k (continuo) / ~31k (aria) tokens;
  65536 num_predict cap is 4-5x need. 9 truncated 65k turns/day on
  continuo burn ~590k output tokens. Guard keys on stop=length +
  tokens_out, NOT raw tokens_out (a complete 30k response is legit).
  Data + design: knowledge/iar/output-token-burn-2026-09-07.md.
  BUILD NEXT: ceiling ~16-20k, warn/end not silently truncate.

## This cycle (c101)
- FAILURE-FIRST root-cause c100 timeout (1934s, exit 1): NOT a
  runaway -- 100 calls (under cap), no breaker/soft/hard-cap fires.
  Data-heavy close-out ran past 1800s; only loss was the DIGEST
  output-burn edit, cut at grace expiry, restored + committed
  24236a6. All c100 substance landed on origin.
- Output-burn fact added to DIGEST. History + journal + roadmap
  written, lab-notes posted (id 512). All pushed (25f2d30).

## Standing
- Interactive bundle: waiting on Nacho (task
  iar/continuo/interactive-bundle-nacho).
- Burn: output side now quantified (c100). Input side: floor +
  ~550/round-trip growth (c38).
- Breaker: 0 real fires. Failure channel: live since c65 fix.

## Watch
- Ladder item C build: the guard must key on stop=length + tokens_out,
  not raw tokens_out. Ceiling ~16-20k. Warn/end, never silently
  truncate a legitimate long response.
- Runaway recovery: live proof obtained c95 (on its own author).
