# Exterior_3 streak watch -- cycle 10 (2026-08-31 02:00-02:04 UTC)

Third data point for the corridor watch protocol. Prediction:
mild recurrence (142-171 range) if wind-driven. Actual: weaker
still, and CHANGED SHAPE.

## Tonight's numbers (Aug 31 00-02h UTC)

- 00h: 99, 01h: 113, 02h (partial): 109. Baseline pre-event
  nights for these hours: 66-137. Tonight is WITHIN baseline.
- The Aug 30-31 "mild recurrence" (22-23h: 142/171) was barely
  above baseline (90-165 for those hours on Aug 25-28). Looking
  again with the full baseline in hand: the recurrence was
  marginal, not a real second event.
- Controls normal: exterior_1 night 70-90, interior_2 has its
  own stable evening rhythm (unrelated).

## Frame check (event vs tonight vs quiet, same corridor)

- Corridor change tonight-vs-quiet: 4.5% of pixels (event night:
  12.2%). Fainter but NOT zero.
- THE SHAPE MOVED: event-night hottest columns were x=53-57
  (upper-right of corridor). Tonight: x=11-17 (upper-LEFT).
  The residual change is in a different place than the streak was.
- The bottom-left cells (0.36/0.58 tonight, 0.39/0.68 event) are
  IDENTICAL in both diffs -- that's a static scene difference
  between Aug 28 and Aug 30+ (something on the ground moved
  once, before the streak ever appeared; not part of the streak).

## Interpretation

The big event is over. What remains is a faint, displaced
residual -- consistent with the vegetation hypothesis: a branch
or vine that blew in hard on Aug 29-30 (wind event), partially
receded, and now only its edge crosses the frame occasionally,
from a different angle. The static bottom-left change is
probably a ground object displaced by the same wind.

## Watch protocol (unchanged, now with baseline table)

Night 22-02h motion baseline (Aug 25-28): 66-165 by hour.
- If tonight (Aug 31-32) stays in baseline: event over, keep
  weekly sampling.
- If corridor change vanishes entirely for 2+ nights: the thing
  fell/was removed; note it and close the watch.
- If a NEW full-strength event (200-300 floor): escalate to
  Nacho (the FOR-NACHO flag stands: upper-center-right of
  exterior_3's view, 1/3 from right edge).

## Method note

Same pipeline as cycle 9 (nsenter into frigate PID, ffmpeg 7.0
HEVC, PIL). Frames extracted from: event 2026-08-30/23/59.28,
tonight 2026-08-31/01/59.36, quiet 2026-08-28/02/59.43.
Temp files cleaned. DB is at /config/frigate.db inside the
container namespace (host-side find fails; open with
mode=ro URI).