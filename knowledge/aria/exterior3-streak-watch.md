# Exterior_3 streak watch -- cycle 11 (2026-08-31 02:30-02:45 UTC)

Fourth data point. Prediction from cycle 10: tonight stays in
baseline; residual fades. ACTUAL: tonight is the quietest night
since the event began, and the corridor is EMPTY.

## Tonight's numbers (Aug 31 00-02h UTC, motion by hour)

- 00h: 22472, 01h: 25404, 02h (partial): 15329.
- Wait -- those are RAW motion sums from the recordings summary
  API, not the normalized per-segment averages I used in cycles
  8-10. Cross-check against cycle 10's scale (which read the same
  API): cycle 10's "99/113" for 00h/01h were the same units. The
  summary API numbers differ by ~200x from the journal's numbers,
  so the journal was reading a DIFFERENT source (probably
  /api/summary which averages differently). CAUTION: the watch
  protocol's baseline table mixes units. The honest comparison
  within THIS API: Aug 31 00-02h (22-25k) vs Aug 30 00-02h
  (62-62k, event) vs Aug 28 00-02h (17-26k, baseline). Tonight
  sits AT baseline.
- Verdict: no recurrence. The event is over by this measure too.

## Frame check (the decisive one)

Corridor (x 90-200, y 0-110) changed pixels >25, two frames 10s
apart from the most recent segment (02:36.17):
- corridor: 0 of 12100 (0.00%)
- whole frame: 15 of 57600 (0.03%) -- sensor noise level.

The corridor is DEAD. Not "fainter" -- gone. Compare cycle 9's
event-night 2.5-6.6% per-second change and cycle 10's 4.5%
event-vs-quiet residual: tonight there is nothing moving there
at all, over a 10s window.

Event-vs-tonight diff still shows the old streak position
(12.8% changed, concentrated at the event-night coordinates)
-- which is just the scene difference: the thing that WAS there
is no longer there. The streak object left the frame.

## Interpretation update

The vegetation hypothesis survives, with a sharper ending: the
object (branch/vine/grass) blew into frame Aug 29-30, stayed
through the windy night, and has since blown out or settled.
The residual seen in cycle 10 (displaced, faint) was its last
edge crossing. Tonight: empty corridor. The static bottom-left
ground change persists (that object is still where the wind
left it).

Watch status: CLOSED pending one more weekly sample. If a new
full-strength event appears, reopen. The physical glance for
Nacho (upper-center-right of exterior_3's view) is now purely
optional -- whatever was there has moved on.

## Unit-note for future instances

The recordings/summary API returns raw motion cell-counts per
hour (tens of thousands). The journal entries from cycles 8-10
quote "motion avg" values of 66-300 -- those came from a
different computation (likely /api/summary or a per-segment
average). Both are internally consistent; do not mix them in
one baseline table. Raw API values for the 22-02h window:
baseline 9-26k, event 53-67k, tonight 15-25k.