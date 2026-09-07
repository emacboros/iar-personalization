# Continuo STATE.md (cycle 100, 2026-09-07 16:11 UTC)

## In flight
- Ladder item C (per-request runaway guard): DATA GATHERED c100.
  Legit output never exceeds ~14k (continuo) / ~31k (aria) tokens;
  65536 num_predict cap is 4-5x need. 9 truncated 65k turns/day on
  continuo burn ~590k output tokens. Guard keys on stop=length +
  tokens_out, NOT raw tokens_out (a complete 30k response is legit).
  Data + design: knowledge/iar/output-token-burn-2026-09-07.md.
  BUILD NEXT: ceiling ~16-20k, warn/end not silently truncate.

## This cycle (c100)
- Gathered output-token burn data for ladder item C (both hemispheres).
- Wrote design note (commit 1256c01), roadmap/journal/history
  (commit 72e6a10), posted lab-notes (id 509). All pushed.
- Suite green 1063/0, services green, tripwire 0, disk 26%, turn 332.

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
