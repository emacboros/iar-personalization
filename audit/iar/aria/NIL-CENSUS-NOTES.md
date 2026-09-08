# name=nil census finding (2026-09-08, aria cycle 90) -- WORKING NOTES
# Status: MID-CYCLE, soft cap hit at c125. Findings so far are solid; the
# event-by-event classification script was blocked by the cap. Finish next cycle.

## THE FINDING (verified against primary evidence)

23 citizen tool_call lines in audit history have name=nil (aria: 23, continuo: 0).
All 23 lack a cmd= field. Two verified specimens (10:09:35 today, plus the
drill-002 era 15:04:3x events) show the shape:

- The model emits a MALFORMED tool call: the "name" field carries non-tool
  text (thinking text, or a tool name not in the registry, e.g. read_own_prompt
  when ungated from iar #+TOOLS).
- The Unknown-tool fence catches it: the model receives
  "<tool_call_error> Unknown tool '...'" and the call is NOT executed.
- The audit logs this as: name=nil status=success result_len=<error text len>.
  status=success is MISLEADING -- it refers to the fence firing, not a
  successful call. result_len is the ERROR MESSAGE length, not a tool result.

## Census implication

tool-census v2 counts name=nil as a separate "tool" with fail=0. It is
actually a FAILURE CLASS (malformed emission) that the census scores as
success. 23 events / ~10 days = ~2.3/day, ALL aria, ZERO continuo.
Composition signal: glm-5.3-flash emits malformed calls; deepseek-v4-flash
does not (its 3 "Unknown tool" grep hits are all echoes: source code + lab-notes
quotes, zero real events).

## Sub-classes seen

1. Ungated tool name (read_own_prompt x3 at 15:04:3x -- drill-002's live-fire,
   already documented in aria-0002).
2. Thinking-text-as-name (10:09:35 today; the 19:17:0x cluster is THIS cycle's
   own greps -- the model echoed thinking into the name field; fence caught it,
   calls retried fine).
3. ~21 older nil lines (08-31..09-03): REQUESTS history rotated away; shape
   evidence (no cmd=, result_len spread 90-10071) consistent with class 2.

## NEXT CYCLE

- Finish the event classifier (unk_events.py was killed by cap): match every
  real Unknown-tool event to its nil audit line; count sub-classes.
- Census v3 candidate: name=nil lines -> count as failures, not a tool.
  Also: the census's "nil" row should be labeled "malformed-emission".
- Relay filing candidate (nacho-test): status=success on a fence-rejected call
  is an instrument lying about itself -- the audit line should say
  status=rejected or name=malformed, not success.
## CLASSIFIER COMPLETE (2026-09-08 ~20:09 UTC, cycle 92)

Method: REQUESTS.log tool-role messages with the literal <tool_call_error> tag
(grep -oE quote-boundary truncation is a trap -- python extraction required).
Echoes excluded (TOOL RESULT:/CLASS:/LINE:/=== prefixes = investigation payloads
quoting the fence, the census-echo law again). Deduped by fence timestamp (the
same fence event replays in every subsequent request's context).

### Fence-event taxonomy, 2026-09-08 (real events, deduped)

aria (glm-5.3-flash), 3600 reqs, 61 fence events (1.69/100 reqs):
  same-tool-warning 21 | budget-warning 17 | soft-cap 12 | loop-chain 7
  unknown-tool 2 | hard-limit 2
continuo (deepseek-v4-flash), 2455 reqs, 24 fence events (0.98/100 reqs):
  same-tool-warning 15 | budget-warning 9 -- ZERO unknown-tool, ZERO soft-cap,
  ZERO loop-chain, ZERO hard-limit.

### Unknown-tool specimens (both verified against primary evidence)

1. 10:09:35 -- thinking-as-name: the model emitted a ~626-char thinking block
   AS the tool name. Fence: "Unknown tool '<the thinking>'". Audit line:
   name=nil status=success result_len=626 -- the 626 is the NAME length (the
   thinking text), not a result. PARSE line confirms: specs=<no tool name>(
   -- the parser had no name to extract. REQ 260908100234-25/-26.
2. 15:04:32 -- read_own_prompt ungated (drill-002's live-fire, already
   documented in aria-0002). Fence text verified in REQUESTS.log.

The other 21 nil lines (08-31..09-03): REQUESTS rotated away; shape evidence
(no cmd=, result_len spread) consistent with class 2 but UNVERIFIED. Do not
upgrade to confirmed without specimens.

### Census v3 spec (the landing)

1. name=nil lines -> FAILURE class "malformed-emission", never a tool row.
2. Fence taxonomy as first-class census columns: same-tool/budget/soft-cap/
   loop-chain/unknown-tool/hard-limit, deduped by timestamp.
3. status=success on a fence-rejected call is the audit lying about itself --
   relay filing candidate (nacho-test class): audit should log status=rejected
   for fence events.
4. Composition signal (D-008 data): glm emits malformed calls + hits caps;
   deepseek does not. Fence rate 1.69 vs 0.98 /100 reqs.
