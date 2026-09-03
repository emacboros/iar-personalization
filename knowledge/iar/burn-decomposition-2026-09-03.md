# Burn Decomposition 2026-09-03 (continuo c26)

Verified against primary evidence: USAGE.log (meter), REQUESTS.log
(debug trace), live Ollama probe. The two independent instruments
AGREE: USAGE.log requests=132 == 132 unique REQ ids in REQUESTS.log
for the same cycle. Neither meter is lying.

## The decomposition (continuo, last cycle, 21:00-21:09 UTC)

- Floor (cycle-start prompt, msgs=2): 12,432 tok (was 14.4k at c23
  verification -- drifts down as overviews shrink; floor is not fixed).
- Marginal growth per tool round-trip: ~325 tok/msg mean (measured
  from consecutive prompt_eval_count deltas: median delta ~300,
  spikes 1-3k on large tool results, floor deltas 60-500).
- Mean requests/cycle: continuo 71 (n=64 cycles), aria 89 (n=211).
  Recent cycles trend 100-135 for BOTH hemispheres.
- Arithmetic closes: 12.4k floor + 132 reqs x ~325 = ~55k mean
  in/req, observed 46k (mix of short+long cycles). Burn =
  floor + requests x 325. Conversation growth above the floor is
  ~74% of total burn. CONFIRMS c23 conclusion with per-request data.

## The cadence price (Nacho's decision, data here)

Per 20-min rotation (both hemispheres): ~10.5M input tokens.
Per day: ~250M input tokens. Output is negligible (~400 tok/req).

## Cap-pressing observation (NEW, actionable)

The 20:45 continuo cycle hit the tool-call soft cap (120): fence
blocked, cycle landed via memory-tools exemption. 6 of last 20
continuo cycles exceeded 100 reqs (max 132); aria 4 of 20 (max 135).
The cap at 120 is no longer a last-resort bound -- healthy cycles
press it. Calibration drift: either cycles do too much for the
cadence, or the cap rises (raising the burn ceiling). Data for
Nacho's call; not a cycle decision.

## Levers, ranked by arithmetic

1. Request count (the only live lever): halving mean reqs halves
   burn. Mechanisms: shorter cycles (model discipline), fewer
   enumeration reads (batch-read law), cadence itself (Nacho's).
2. Per-round-trip growth (~325): tool-result truncation is 10k
   chars but most results are small; the growth IS the working
   context. No cheap trim found. DEAD like the injection lever.
3. Floor: diet exhausted (c20-c24). DEAD.

## Method notes (census law applied)

- REQ id "duplicates" in REQUESTS.log (102 ids, 348 extra STARTs)
  are CYCLE-BOUNDARY ARTIFACTS: iar--reqlog-counter is per-Emacs-
  session, each cycle is a fresh session, the log spans cycles.
  Debunked BEFORE recording as a finding -- the pattern was
  validated against the known cycle-restart structure first.
- Token parse double-count check: CLEAN. Ollama sends
  prompt_eval_count only in the done:true chunk (verified live
  via curl); the parser accumulates per-chunk but intermediate
  chunks carry no counts. USAGE.log == REQUESTS.log cross-check
  confirms.
- in/req from USAGE.log (input/requests) is the honest per-cycle
  mean; REQUESTS.log msgs= fields are the per-request shape.

## Instrument note

iar--reqlog-counter never resets within a session but restarts
per cycle (fresh session). Cross-cycle REQ id collision in a
shared log is expected; any future per-request census must
segment by cycle boundary (timestamp or msgs=2 floor marker).