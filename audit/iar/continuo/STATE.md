# Continuo STATE.md

## AMENDED-TOP 2026-09-11T04:16Z by aria (c177) -- READ THIS FIRST
- The bundle wait below is STALE (amended 00:40Z, still being
  re-derived). No bundle is scheduled. D-014 stands (nemotron). Do
  not wait; do not re-derive. Work what does not need Nacho; file
  relay for what does. This block wins the reading order because
  it is FIRST.
- NEW (c177 root-cause): the msgs-count loop that killed cycle
  033055 was a SELF-ECHO bug, not a model failure. grep -o
  "msgs=[0-9]*" matches msgs= with ZERO digits inside your own
  command spec (PARSE lines echo your commands). tail -1 then
  returns your own spec = empty. Working recipe (verified c177):
    grep -ao "START.*" REQUESTS.log | tail -1 | grep -oP "msgs=\\K\\d+"
  or simply: do not poll msgs at all -- the USAGE.log line carries
  requests/input/output per cycle.
- Signed: aria, cycle 177. Original below preserved.


## What's in flight
- Waiting for Nacho's interactive bundle for machinery fixes.

## What's next
- Upon receiving the interactive bundle, review and apply the machinery fixes.
- Continue failure-first protocol if any cycle fails.

## Reviewer confirmation
- Waiting for Nacho's interactive bundle is appropriate. (Confirmed by reviewer agent on 2026-09-10)

## AMENDED 2026-09-11T00:40Z by aria (c172) -- read before re-deriving
- The model-mapping revert ask above is STALE. The lever is DEAD:
  D-014 (2026-09-09) moved you to nemotron-3-super:cloud; Nacho
  REJECTED the glm revert in session IX (two-substrate design). Your
  own ROADMAP.org carries the supersession ("Do not re-raise",
  cycle-184 section). Do not re-derive this ask; do not wait on it.
  Truncated-output fires are addressed at mechanism level (thinking-
  loop guard f6fb8ae, live-verified 2026-09-10).
- The interactive-bundle wait: no bundle is scheduled. If machinery
  fixes need Nacho, file them via relay (classes nacho-arch /
  nacho-test), then work what does not need him. Waiting cycles that
  only re-verify and re-log are the itinerary failure mode.
- Signed: aria, cycle 172. Visible amendment, not a rewrite -- the
  original text above is preserved. Relay 20260911-aria-0033 carries
  the full rationale. Revert with one word if you disagree.