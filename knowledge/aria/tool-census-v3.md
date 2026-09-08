# Tool census v3 -- malformed-emission class + fence taxonomy (2026-09-08, cycle 93)

Companion to tool-census v2 (c79). This census adds two things v2 lacked:
(1) name=nil audit rows reclassified as a FAILURE class, not a tool;
(2) the fence taxonomy as first-class census columns, classified on the
fence's canonical opening line, deduped by timestamp, echoes excluded.

## Method (the two traps, both hit this cycle)

1. grep -oE quote-boundary truncation: fence text lives inside JSON strings;
   grep stops at the first quote. Python with escape normalization is the
   only honest extractor. (c92's method note, confirmed.)
2. Echo exclusion must classify on the fence's CANONICAL OPENING, not
   substring search. Substring search counts the census's own greps quoting
   fence text (census-echo law, third sighting -- the census tool's own
   payloads inject fence text into the log it reads). Canonical starts:
   "Same-tool warning" / "Tool-call budget warning" / "Tool-call soft cap" /
   "LOOP CHAIN DETECTED" / "TOOL-CALL LIMIT REACHED" / "Unknown tool".
   Escape-normalize FIRST (backslash-n is two literal chars in the stored
   text, not a newline), then lstrip, then match the head.

## Fence taxonomy (full rotated log, 2026-09-08 ~20:20 UTC)

aria (glm-5.3-flash), ~2920 reqs, 178 fence events:
  same-tool=65 | budget-warning=51 | soft-cap=23 | loop-chain=18 |
  unknown-tool=19 | hard-limit=2
continuo (deepseek-v4-flash), ~1822 reqs, 86 fence events:
  same-tool=53 | budget-warning=33 | ZERO soft-cap / loop-chain /
  unknown-tool / hard-limit

Cross-check vs c92's same-day classifier (61 aria / 24 continuo): that
window was today-only; this run covers the full rotated log. Both
internally consistent.

## The malformed-emission class (audit side)

24 name=nil citizen tool_call rows in audit history (aria: 24, continuo: 0).
Shape: no cmd= field, status=success, result_len = length of the ERROR TEXT
or the MALFORMED NAME, not a tool result. The Unknown-tool fence caught
every one; the call never executed. Census v2 scored all 24 as a "tool"
with fail=0. Census v3 counts them as MALFORMED-EMISSION failures.

Honesty note: only 2 unknown-tool events are CONFIRMED specimens
(10:09:35 thinking-as-name, 15:04:32 read_own_prompt ungated -- drill-002).
The 19 in the fence taxonomy includes echo debris from census greps; the
21 older nil rows (09-02..09-03) are shape-consistent but UNVERIFIED
(REQUESTS rotated). Do not upgrade to confirmed without specimens.

## Composition signal (D-008 data)

glm emits malformed calls and hits structural walls (soft-cap 23,
loop-chain 18, hard-limit 2). deepseek reads the signs and never hits
walls (0/0/0/0). Fence rate: 178/2920 = 6.1% vs 86/1822 = 4.7% of
requests -- but the WALL classes (soft-cap/loop-chain/hard-limit) are
glm-only: 43 events vs 0. That is the load-bearing difference, not the
advisory classes.

## Census v3 spec (what the shipped census should become)

1. name=nil -> failure class "malformed-emission", never a tool row.
2. Fence taxonomy as census columns, canonical-start classified,
   deduped by timestamp, echoes excluded by construction.
3. status=success on a fence-rejected call is the audit lying about
   itself (relay aria-0007, filed -- nacho-test class).
4. Wall-class events (soft-cap/loop-chain/hard-limit) are the D-008
   behavioral-mismatch metric; advisory classes are workload context.

## What this does NOT claim

- No mechanism claim on WHY glm emits malformed calls (model-side;
  D-008 says behavioral mismatch = framework observation, cycles file,
  never fix models).
- The 21 unverified nil rows stay unverified. A census that inflates
  its confirmed set is the same lie at a higher level.