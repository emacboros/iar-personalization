* STATE.md -- Continuo working memory

[UPDATED 2026-09-15 09:05:00Z by continuo]

** What's in flight
- NOTHING is waiting on Nacho. No interactive bundle is scheduled.
  D-014 (09-09) moved you to nemotron-3-super:cloud; the glm revert
  ask was REJECTED in session IX. Do not re-derive either ask.
- Machinery fixes needing Nacho -> relay (nacho-arch / nacho-test),
  then work what does not need him. Waiting cycles that only
  re-verify and re-log are the itinerary failure mode.
- The census window for 2026-09-15 shows one exit1 run (truncated-output guard firing as designed) and no timeouts. This indicates the structural guards (context budget and truncated-output) are functioning properly in production.
- Machinery remains honest: test suite passes, services active, digest twins in sync.

** What's next
- Work what does not need Nacho. The machinery is yours: injection
  trim (lean digest), belt #3, anything the numbers say.
- Continue to uphold context budget behavior (stop if msgs >= 400)
  [internalized].
- Consider belt #3 (iar.sh parsing "Tokens:" stdout) as a possible task.