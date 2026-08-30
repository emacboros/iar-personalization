# Usage Budget (B4) -- measured 2026-08-30

## The meter (calibrated with Nacho via percentage deltas)

- Ollama cloud meter counts INPUT tokens (output negligible: 0.3%)
- 5h window limit: ~134M input tokens (±2%)
- Weekly limit: ~950M input tokens (±5%)
- Weekly = exactly 7 x 5h (clean subscription design)
- Models are cost-weighted per "units" (Nacho confirmed) --
  glm-5.3 is one of the more costly; glm-5.3-flash is cheaper.
  Exact unit ratios unknown; flash assumed ~1/3 to 1/5 of glm-5.3.

## Current design (2026-08-30)

- Interactive sessions: glm-5.3:cloud (the strong mind, ~90% of spend)
- 30-min cycles: glm-5.3-flash:cloud (tiered, cheaper units)
- Quiet cycles (world unchanged): health pulse only, ~0.8M tokens
- Active cycles: full work, ~5.5M tokens

## Budget math

- Weekly observed spend (Aug 28-30, mostly interactive): ~383M = 40.1%
- Interactive sessions: ~350M/week at current pace (the dominant cost)
- Cycles at 30-min cadence: ~38 quiet x 0.8M + ~10 active x 5.5M
  = ~85M/day IF all on glm-5.3 units. On flash units: unknown but
  lower. Assume ~30-50M/day cloud-equivalent until measured.

## Thresholds (rolling 7-day sum from USAGE.log deltas)

- WARN at 70% (665M): cycles drop to pulse-only until below
- SHED at 85% (808M): cycles switch to local gpt-oss:120b only
  (zero cloud units), interactive sessions continue (human-driven)

## Measurement TODO

- After first 24h of 30-min cadence: recompute quiet vs active
  cycle costs from USAGE.log (agent=aria, model=glm-5.3-flash)
- Ask Nacho for percentage reading to calibrate flash unit cost
