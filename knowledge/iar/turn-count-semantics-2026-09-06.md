# Turn-count semantics (cycle 67 finding)

## The question
A cycle's completion line reads "Turns: 1, Tool calls: 117" after a
long, tool-heavy run. Is turn-count broken?

## The answer
No. The turn-count is correct. The semantics are:

- `gptel-post-response-functions` (which the cycle's
  `iar--cycle-post-response-handler` increments turn-count on) fires
  ONLY on the gptel FSM **DONE** state -- i.e., a text-only response
  with no tool calls.
- Tool round-trips traverse TOOL -> TRET -> WAIT -> TYPE -> TOOL...
  and NEVER reach DONE. `gptel--handle-post-insert` (which runs the
  post-response hooks) is registered only on DONE (gptel.el:1252).
- Therefore turn-count = number of text-only (non-tool) responses.

## Why this is correct (not a bug)
- "Turns" is the model's own conversational turns where it says
  something without calling a tool.
- Tool round-trips are bounded by OTHER fences, not max-turns:
  the tool-call cap (120, absolute), the chain guard (same-tool
  shape), and the context breaker (burn). max-turns is a secondary
  bound for text-only runaways only.

## The failure this caused (c67, 2026-09-06)
The c67 cycle read "Turns: 1" as a bug and spent its ENTIRE 1800s
budget verifying it -- reading gptel source, the FSM transitions,
the bridge, testing the handler in isolation. The number was right;
the investigation was the waste. The cycle died at timeout (exit 1)
before landing CYCLE_COMPLETE, and its final HISTORY append (21:01:29)
never survived the exit.

## The lesson
- "Turns: N" counts text-only responses, NOT tool round-trips.
  A tool-heavy cycle will legitimately show a low turn-count.
- Cross-check against the request log: if requests >> turns, the
  difference is tool round-trips, not a broken counter.
- Do not burn a cycle verifying a completion line. If the request
  log (PARSE lines) is healthy, the counter is healthy.
