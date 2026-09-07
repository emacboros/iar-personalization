# Burn at the 10-min cadence (continuo c108, 2026-09-07)

Quantified the current burn from primary evidence (USAGE.log, deduped
by timestamp, interactive orphans excluded). The 09-03 decomposition
(~250M/day) was measured at the 20-min cadence; the timer is now
OnCalendar=*:0/10 (10-min), so the cadence price changed.

## Cycle-only burn by day (both agents, interactive orphans excluded)

- 2026-09-03: 411M (full day, 20-min cadence)
- 2026-09-04: 186M (partial -- timer stopped 06:39)
- 2026-09-06: 150M (partial -- timer restarted 13:44)
- 2026-09-07: 341M in 19.5h = ~420M/day (10-min cadence)

09-07 is running ~420M/day vs 09-03's 411M -- roughly FLAT despite
the cadence doubling. The 09-03 decomposition's ~250M/day was
measured on a lighter day; the cadence change did not double the
burn because per-cycle request counts fell (aria 78->87 mean_req is
up, but continuo 79->68 is down; the mix nets out).

## The driver is aria's request count

- aria mean_req: 78 (09-03) -> 87 (09-07); cap-edge (>=120) cycles:
  13 -> 17 today.
- aria per-request tokens_in in the 17:28 cycle: 113k-117k (conversation
  growth, the ~74% of burn the 09-03 decomposition named).
- aria 18:15:59 cycle hit the soft cap at 120; the model was mid-
  thinking about the fence when the response was captured.
- Composition differential holds: aria ~4.3-5.7M avg/cycle vs
  continuo ~2.8-3.4M. Aria is the burn hemisphere.

## Interactive orphans (NOT cycles) -- already resolved by aria c23

The 06:31:20 (597req/68M), 08:48:51 (251req/15.5M), 09:07:59
(31req/0.9M) lines are belt#2 kill-emacs writes from INTERACTIVE
sessions, orphan-published by the cleanup sweep. Not cycle burn.
See knowledge/iar/usage-artifact-resolution-2026-09-07.md.

## Levers (ranked, per the 09-03 decomposition)

1. Request count (the only live lever): aria's cap-edge cycles are
   the burn. 17 today. The cap at 120 is being pressed by healthy
   cycles -- calibration drift (Nacho's call, in the interactive
   bundle).
2. num_predict 65536 -> ~40k: aria c35 flagged it; blocked on the
   rage sev=3 observation (Sep 8). After it clears, cheapest
   per-event burn lever.
3. Cadence itself: Nacho's call. 10-min is ~420M/day.

## Method notes

- USAGE.log carries TWO burn classes (cycle belt#2 lines + interactive
  kill-emacs orphans). Segment by writer before any composition
  comparison (c23 law). The 09-07 total of 758M includes ~84M of
  interactive orphans; cycle-only is ~341M.
- Dedup by timestamp (each cycle writes a twin pair).
- Poison guard: exclude input > 500M (meter-poison class, c36).
