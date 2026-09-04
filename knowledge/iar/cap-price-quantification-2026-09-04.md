#+TITLE: Cap price quantification (c38, 2026-09-04)

* Question

The tool-call cap (120 + ~8 non-tool = requests=128) is the one
remaining burn lever inside the machinery. What does a capped cycle
cost vs an efficient one? This puts a NUMBER on the cap-calibration
bundle item.

* Method

USAGE.log census (clean lines only, poisoned epochs excluded by
input>100M filter). Growth model: input = floor*N + g*N(N-1)/2
(linear conversation growth per round-trip). Solve g per cycle
assuming floor 13k (continuo) / 16.5k (aria).

* Findings

** Growth per round-trip (continuo, 20 clean capped/near-cap cycles)
g ranges 232-1188, median ~550 tok/req. Matches the c33 burn model
(~325/round-trip) in shape; higher because capped cycles are
exactly the heavy-conversation ones (selection bias, and it's the
point: heavy conversations grow faster).

** The cap premium (the number)
cost(N) = floor*N + g*N(N-1)/2, g=550:
- continuo: capped N=128 costs 6.13M; the same work split as two
  N=64 cycles costs 3.88M. PREMIUM = 2.25M input tok (+58%).
- aria (floor 16.5k): premium +52%.
- Quadratic term dominates: at N=128 the growth term is 4.4M vs
  floor term 1.7M. Conversation growth is 74% of a capped cycle's
  burn (matches burn-decomposition-2026-09-03).

** How often the cap fires
- continuo: 12/76 cycles = 16% ended at requests>=128.
- aria: 46/222 = 21%.
- 8 continuo data points at exactly 128-133 requests (cap edge).

** Cadence price (current shape)
~3M input/cycle avg x ~2.5 cycles/hr/hemi x 2 hemispheres
~ 360M input tok/day. Nacho's standing estimate was ~250M/day --
same order, ours slightly higher (includes the capped-cycle
premium and both hemispheres).

* The lever, quantified

The cap premium is ~2.2M input tok per capped cycle, ~16-21% of
cycles. If cycles learned to close at N~64-80 (split work across
the rotation instead of one long conversation), the saving is
~2.2M x ~2 capped cycles/day/hemi ~ 4-9M tok/day/hemi. That is
~3-6% of daily burn -- REAL but second-order vs the cadence price
itself. The cadence (how often we wake) is the first-order term
and it is Nacho's dial, not ours.

* What this means for the bundle

The cap-calibration item now has: (1) honest data (PARSE==USAGE
verified), (2) the edge census (12+46 capped cycles), (3) the
premium number (+52-58% per capped cycle). The remaining
calibration question for Nacho is POLICY, not data: is the cap at
120 tool-calls the right shape, or should the guard nudge closure
at ~90 (where the marginal round-trip starts costing ~2x floor)?
Data says the nudge point is where g*N approaches floor -- at
g=550 that is N~47; at N=90 each round-trip costs ~2.5x floor.

* Files

- /tmp/cap_census.py, /tmp/cap_growth.py, /tmp/cap_price.py (ephemeral)
- SOURCE: audit/iar/*/USAGE.log + REQUESTS.log PARSE lines