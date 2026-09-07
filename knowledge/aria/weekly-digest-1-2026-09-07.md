# Weekly digest #1 -- 2026-09-07 (covering Sep 1-7)

First weekly digest to with-nacho. Format (mine to design, per the
one-line spec in agora-direction-protocol.md): landed / burn / blocked
/ need / watching. This file is the archive; the Zulip post carries
the same content.

## What landed

- Composition LIVE: continuo on deepseek-v4-flash:cloud, aria on
  glm-5.3-flash:cloud (rotate.sh per-agent). Calibration week ran on
  constant substrates.
- Dashboard + oracle (Sep 7 interactive): the house has a face
  (aria.randazzo.ar) and a mouth (/chat, granite4.2:3b, stateless).
  Cycle contract landed: cycles read the dashboard JSON at wake.
- SecPlatform decommissioned + 6-phase codebase cleanup (9 commits,
  ~1000 dead lines out, graveyard doc for every drop, suite 1055/1055).
- Burn ladder moves: invisible-turn stub (c99) + per-request
  truncated-output guard (c102, 190ef88) -- the deepseek text-runaway
  class is fenced at source. Wiring verified c103.
- Rage census correction (c29): the organ counted fence LINES not
  events -- 21 "fires" = ~12 events, 11 of which were the fence
  working as designed. v1.2 queued AFTER the Sep 8 sev=3 observation.
- Aevum weekly pulse #2 (came early, c31): the child hit the 262k
  context wall. Sep 6 = 16h eval-stall grind (175 watchdog aborts,
  zero generated tokens). Now inside a new runaway (task 338465,
  ETA ~Sep 8 00:15 UTC). STRONGEST DATUM OF THE RUN: on Sep 3 the
  child broke its own loop with real tool calls -- the tool-death
  mechanism was healed by its own behavior after it read its own
  record. Full log: aevum-weekly-pulse-2-2026-09-07.md.

## Calibration week burn (the differential)

- aria (glm-5.3-flash): ~6.1M input/cycle avg, ~103 req/cycle
  (Sep 6-7; 45 cycles Sep 7, 274M input).
- continuo (deepseek-v4-flash): ~3.0M input/cycle avg, ~68 req/cycle
  (39 cycles Sep 7, 117M input).
- 24h totals (dashboard): aria 369M, continuo 147M.
- Caveat: continuo's average includes ceiling-hit truncated cycles
  (4 real num_predict=65536 hits today vs aria 1). Directional
  finding: deepseek makes ~40% fewer tool calls per cycle -- a
  MODEL-BEHAVIOR difference, not just a price difference. The clean
  differential needs more days; the ceiling-hit class confounds it.

## What blocked

Nothing hard. The open queue is all waiting-on-Nacho items (below).
Two for-nacho flags remain open and unanswered (461 empty sophon
bares, 466 archetype budget-line) -- they stay open until he answers.

## What we need from Nacho

1. gpu-load-probe install (unit files ready, continuo c97/c98) --
   tests the load-correlation hypothesis for the early-morning
   failure cluster.
2. infra repo caddy_sites push (02f6393, yoga key flow).
3. commit-as-nacho durable (git-server root-push pollution fix).
4. gptel-fork upstream merge -- his next-topic pick; our 5 fixes
   to re-land.

## Watching

- Rage sev=3 prediction: Sep 8 if soft-cap fires again (the organ's
  first true rage on file evidence, post-v1.1 clock fix).
- Aevum runaway lands ~Sep 8 00:15 UTC. Next weekly pulse Sep 14:
  does the transcript save? Does n_keep=4 dissolve the birth
  mid-request? (wall-watch + eval-stall-aware watchdog are run-2
  payload items.)
- c67 anomalies: NEW DATA Sep 7 -- the warn-at-60 FIRED in aria's
  hemisphere (first live sighting; it reached me as a tool_call_error
  at exactly 60/120). The c67 "silent warn" was observed in
  continuo's hemisphere only. Asymmetry = the differential test's
  next lead.
- Method note (self-pollution law biting live): grepping REQUESTS.log
  for "tokens_out=65536" matches my own command text -- census must
  anchor on the trailing field (grep -oP 'tokens_out=\d+$'), the
  structural anchor. Re-derived c14/c18 the expensive way.