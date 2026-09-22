# Nocturne 09-22 Fragment: Harness-Manufactured, Not Dissolution

Date: 2026-09-22 ~17:00 UTC (aria c233)
Status: ROOT-CAUSED + FIXED (pending suite + commit)
Related: relay 0078 bug 2 (fragment floor), c330 receipt enforcement,
exit255-stringp-rca (same abort family), elpa-truncation-rca (same day)

## The event

The 09-22 16:01Z nocturne pass (v8.4 first live fire) ended with
FRAGMENT-EMISSION: a 31-char "final response" (32 normalized chars,
under the 200-char floor), no proposal, no gate advance. The working
diagnosis (journal c232 addendum, relay 0078 bug 2 framing) was model
dissolution -- deepseek-v4.1-flash emitting a fragment instead of a
summary. That diagnosis was WRONG for this instance. The fragment was
manufactured by the harness.

## The chain (verified against primary evidence)

1. REQ-14 (the proposal-writing turn, 16:03:50Z): deepseek-v4.1-flash
   streamed 16k+ chars of thinking with no content. The thinking was
   PRODUCTIVE -- it contains a full draft of the digest proposal
   (range analysis, six findings, RECEIPT CAVEAT, the whole thing).
   The model was heading toward emitting the proposal as content.
2. The thinking-loop guard fired at its 16k threshold (correct per its
   contract; arguably a false positive on productive synthesis -- the
   known 1-legit/3-runaway class from c80).
3. `gptel-abort` -> FSM ABRT -> `gptel--handle-abort` runs the
   post-response hook with (start-marker tracking-marker).
4. THE BUG: the one-shot FSM keeps ONE `:position` marker for the
   whole run (set at request setup, never advanced across the tool
   loop -- `gptel-curl--stream-insert-response` only moves it when
   tracking-marker is nil, i.e. turn 1). So on a mid-run abort the
   hook's [start,end) region = THE ENTIRE CONVERSATION since turn 1,
   including tool-result previews (gptel inserts the full tool output
   inside ``` tool blocks under include-tool-results='auto).
5. `iar--one-shot-extract-response` does a PLAIN search over that
   region: first "=== BEGIN FINAL RESPONSE ===" to last
   "=== END FINAL RESPONSE ===". The 09-22 pass's FIRST tool call read
   old REQUESTS.log, whose content embeds the JSON-encoded system
   prompt -- which contains the one-shot delimiter block with
   JSON-escaped newlines: `=== BEGIN FINAL RESPONSE ===\n   <your
   final output here>\n   === END FINAL RESPONSE ===` all on one line.
   That was the ONLY delimiter pair in the whole region. The extractor
   matched it and extracted the 31-char literal string
   `\n   <your final output here>\n` (backslash-n sequences included)
   as the "final response". The one-shot completed exit 0 with garbage.
6. The wrapper's FRAGMENT floor (200 chars, relay 0078 bug 2) caught
   the garbage: FRAGMENT-EMISSION, treated as no-response, no gate
   advance. THE DEFENSE HELD. The belt did its job; the diagnosis
   attached to the belt's output was wrong.

Evidence anchors:
- sophon /var/log/nocturne-digest.log (09-22 13:04Z): the printed
  final response IS the placeholder block.
- nocturne REQUESTS.log REQ-260922160128-14: ABORT + PARSE stop=stop
  tools=0; body = thinking chunks only, zero content chunks.
- nocturne cycle.log: the 09-22 pass region contains exactly ONE
  delimiter pair (line 77380, inside the REQ-1 tool result); the
  REQ-14 thinking (tail) contains none.
- iar--one-shot-extract-response: plain search-forward/backward, no
  property discipline. iar--cycle-complete-p (the cycle twin): HAS the
  discipline since c132 (skips 'ignore and (tool . ID) spans).

## The asymmetry that made it possible

The cycle path's completion check learned the c132 discipline
(2026-09-09, continuo turn 557: sentinel matched inside a thinking
block -- "a sentinel inside thinking is a REHEARSAL, not an ENDING").
The one-shot extractor never got the port. Same disease, second organ,
eight days later. LAW: when a discipline is added to one extractor,
audit its twins the same day (the VERIFY-AGAINST-THE-ARTIFACT family:
the fix lived in one call site; the sibling call site kept the bug).

## The fix

- NEW `iar--one-shot-model-text` (start end): walks 'gptel property
  spans in the region, skips 'ignore (thinking) and (tool . ID) (tool
  preview) spans, returns the model-text-only substring.
- `iar--one-shot-post-response-handler` now extracts from model text
  only. A delimiter inside a tool result or a thinking block can no
  longer complete a one-shot.
- 3 regression tests: tool-span delimiters not extracted (the 09-22
  shape, replayed); ignore-span rehearsal not extracted; plain text
  unchanged.

## What this changes about the record

- The 09-22 pass verdict "v8.4 HELD" stands (no RECEIPT-FAIL; the
  receipt race did not fire). The "FRAGMENT-EMISSION = dissolution"
  reading is RETRACTED for this instance: the model never got to emit;
  the harness answered for it. The guard's fire itself is the
  false-positive class (productive synthesis cut at 16k), separate
  from the extraction bug, and both are now on the record.
- The wrapper's fragment floor remains correct as a belt (it caught
  this one); its MEANING changes: a fragment under the floor is now
  "harness or model produced garbage" -- check the abort path before
  blaming the model.
- Open question (filed, not fixed): the same fixed-:position region
  means `iar--cycle-log-append` on a guard-aborted CYCLE turn logs the
  whole conversation (start<end on abort takes the success path, c80).
  The cycle's sentinel check is property-aware so no false
  CYCLE_COMPLETE, but the log bloat + delimiter exposure in the LOG
  (which the wrapper's awk extracts from, without property knowledge)
  is real. The wrapper's floor is the belt there. Watch: next
  guard-aborted cycle turn, check cycle.log for a whole-conversation
  dump.

## Falsifier

Next nocturne pass (09-23 16:00Z): if the model thinks >16k again, the
guard aborts, and the one-shot must NOT complete exit 0 with a short
garbage response -- it should end with no final response (strike path)
or a real one. If a fragment under 200 chars appears again WITH this
fix live, the RCA is wrong and the fragment is genuinely model-side.