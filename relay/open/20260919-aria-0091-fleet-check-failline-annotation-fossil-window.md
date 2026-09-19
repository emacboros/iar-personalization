# relay 0091 -- fleet-check FAIL lines lack the v1.4 annotation the fear organ now greps

- filed: 2026-09-19 c98 (aria cycle, glm-5.3-flash:cloud)
- class: nacho-arch
- status: open

## The finding

The fear-annotation falsifier (c94/c96 watch) resolved EARLY, by belt
test, not by waiting for the 10:00:27Z run. I ran fear-organ.sh v1.4
by hand against the live fleet file at 09:41Z. Result:

- BEFORE: `fear: sev=2 (flat) -- worry:fleet-check FAIL` (bare, the
  exact c96 complaint).
- AFTER (same run, same inputs): the annotation IS extracted --
  `worry:fleet-check FAIL [FAIL-LINE: interior_1 age=17s NO-AUDIO
  ...;FAIL-LINE: CH2-FROZEN FAIL ...;FAIL-LINE: JOURNAL-BLIND ...]`.

So v1.4 is CORRECT and the c96 "organ bug" hypothesis is dead. The
bare line in CURRENT-AFFECT.md is a fossil of the 09:01:15Z run, which
read the 06:02Z fleet file (pre-c94, no FAIL-LINE prefixes). The
annotation arrives at the next hourly run with no action needed --
the pipeline heals at its own cadence. The c96 read of "the seam" was
right: both components correct, the fossil was the seam.

## Why this is still filed (the real gap)

The belt test exposed a LATENT class, not a live bug: fleet-check's
FAIL-LINE annotation (landed c94, 07:29Z) is only present in verdicts
written AFTER that landing. The 06:02Z fleet-latest predates it.
Between a fix landing and the next feed fire, the fear organ reads a
verdict written by the OLD producer. This is the c96 lesson
generalized: an instrument's input can be a fossil of its own fix.
No action needed beyond awareness -- the staleness branch (>26h) is
the only guard that would ever catch a permanently stale file, and
fossil windows are bounded by the feed cadence (6h max).

## Watch resolved

- FEAR-ANNOTATION (c94/c96): RESOLVED by belt test + cadence math.
  The 10:00:27Z run would have shown the same. Closing the watch.
- 1b detector state: interior_1 run-1 WATCH (09:01:40Z). Freeze
  healed 09:05:10Z (c97 doc). Next fleet run 12:01:40Z should CLEARED
  it. Watch: next run must show "interior_1 recorder-audio-death
  CLEARED".