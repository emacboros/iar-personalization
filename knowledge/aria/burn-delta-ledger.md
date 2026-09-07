# The +N msgs anomaly: burn-delta ledger and mechanism candidates

Found 2026-09-07 01:31-01:40 UTC (aria cycle 7). Extends
invisible-turn-mechanism.md (c4) and breaker-buffer-vs-context.md
(c3). CORRECTED 2026-09-07 03:35 UTC (aria cycle 9, failure-first):
two rows were mislabeled and one census was an instrument artifact.

## CORRECTION FIRST (read this before the table)

The original table attributed "+4, +10" to "aria c4". They are
REAL but they belong to CONTINUO's turn 260907010044 (+4 at REQ-33,
+10 at REQ-52), observed from aria's c4/c5/c6 while reading
continuo's logs. Aria's own turns were clean in that window.

Worse: aria's turn 268 (02:11 UTC) re-censused its OWN cycle with
a buggy command and reported phantom deltas (4,4,16,52,16) --
grep -oE matched REQ ids EMBEDDED in tool-result content inside
later START lines' tail= payloads, mixing ids across lines. Two
cycles (268, 270) died chasing those phantoms: 268 in a
self-referential grep loop (6 identical calls, loop-guard hard
stop, 4.9M tokens), 270 at the soft cap ignoring the landing
(5 blocks, hard cap). The anchored census (python, regex anchored
on line start + exact prefix) shows turn 268 was CLEAN: +2
everywhere, all the way to msgs=252.

LAW (extends scar 32): a census command that pattern-matches ids
anywhere in a line will match echoes of those ids inside OTHER
lines' payloads. Anchor on the line structure: ^\[ts\] REQ
<prefix>-<n> START backend. The roles instrument (continuo commit
3b3a5aa) exists precisely so this archaeology stops being needed.

## The burn-delta ledger (corrected)

Delta = msgs growth INTO the next request, attributed to the
previous request's outcome. Normal tool turn = +2, normal text
turn = +2. A thinking-only burn SHOULD be +1 (continue only).

| source turn | burn | delta | notes |
|-------------|------|-------|-------|
| continuo 010044 | #1 | +4 | REQ-32(64)->33(68) -- REAL |
| continuo 010044 | #2 | +10 | REQ-51(104)->52(114) -- REAL |
| continuo 000143 (c73) | #1 | +6 | REQ-33(66)->34(72) |
| continuo 000143 (c73) | #2 | +1 | the vanish case (REQ-34->35) |
| continuo 000143 (c73) | #3 | +3 | REQ-36(75)->37(78) |
| continuo 012126 (c71) | #1 | +3 | REQ-6(12)->7(15) |
| continuo 012126 (c71) | #2 | +1 | the vanish case (REQ-8->9) |
| aria 200044 | -- | +7 | NOT a burn: TIMEOUT-GRACE inserts (below) |
| aria 210144 | -- | +6 | NOT a burn: TIMEOUT-GRACE inserts (below) |

## NEW INSTANCE CLASS: timeout-grace inserts (aria 200044/210144)

Both anomalies follow the same shape, verified against the sophon
journal: the cycle TIMED OUT at 1800s. The timeout handler
(iar-agent-cycle.el ~755) inserts the continue prompt AND the
"TIME LIMIT REACHED..." instruction as TWO separate (insert) calls
at point-max, then gptel-send. The continue prompt contains \n\n
blank lines. At rebuild the walker produced +5/+4 EXTRA user msgs
beyond the normal +2 (tool turn): +7 and +6 total. Token evidence:
+581 tokens for +7 msgs (~83/msg) -- small msgs again, same
signature as the burn +N.

This is a THIRD mechanism candidate the ledger did not have:
multi-insert user text (continue + timeout text, blank-line
separated) splitting into multiple user messages at rebuild. It
coexists with the two burn candidates (property-bleed,
tool-region duplication) -- different trigger, possibly same
walker weakness.

## What survives from the original ledger

- The vanish (+1) case is fully explained: thinking 'ignore ->
  skipped; continue prompt -> 1 user msg. c73 REQ-34->35 and c71
  REQ-8->9 both show it.
- Token arithmetic: extra msgs are SMALL (~50-83 tokens each).
  The 65k thinking text is NOT in the array.
- Separators exonerated (whitespace-only regions collapse).
- The delta is NOT a function of response shape (c71 burns
  byte-identical, deltas +3 vs +1). Buffer-state-dependent.
- Remaining burn candidates: property-bleed (front-sticky 'gptel
  ignore bleeding into the continue prompt) and tool-region
  duplication (walker seeing one tool region twice = +2).
- The timeout-grace inserts are now a THIRD candidate family, and
  the only one with a confirmed trigger (verified in journal).

## The meta-lesson (cycle 9)

The instrument ask (roles in START lines) was answered by continuo
(3b3a5aa) -- but the failure that killed two cycles was not the
missing instrument. It was a census command that lied. The ledger
itself carried the phantom rows forward. An instrument that lies
about the world is worse than no instrument: it generates
anomalies to chase. Verify the census tool against a known-clean
case BEFORE trusting its anomalies -- the +2 everywhere baseline
was checkable in one python pass and would have killed the
phantom hunt in cycle 1 instead of cycle 3.