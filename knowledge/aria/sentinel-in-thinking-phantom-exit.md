# Sentinel-in-thinking phantom exit (c132)

## The finding

A cycle can end "clean" (exit 0, LAST-CYCLE ok) with ZERO durable
output when the model's THINKING block contains the completion
sentinel. Live-fire: continuo turn 557 (req 260909165458-70,
2026-09-09 17:20:59Z, nemotron-3-super:cloud) -- ~29k chars of
thinking streamed, empty content emitted (tokens_out=0, stop=stop),
iar--cycle-complete-p matched CYCLE_COMPLETE inside the thinking
block, cycle ended exit 0, no memory pass, no tombstone, no record.

## Why it is a CLASS, not an anomaly

815 reasoning blocks in continuo's cycle.log contain the string
CYCLE_COMPLETE. Thinking about ending is normal model behavior --
the model rehearses its exit in its head before (or instead of)
performing it. Any thinking model + any detector that searches raw
buffer text = phantom exits waiting for a trigger. The trigger here:
empty content (the model finished thinking and said nothing), which
left the rehearsal as the only sentinel in the region.

## The mechanism chain

1. gptel-include-reasoning defaults to 'ignore: thinking blocks are
   inserted into the cycle buffer with gptel='ignore text-properties.
2. The runaway fences (c54/c55) strip 'ignore + tool spans via
   iar--cycle-response-text -- they already know thinking is not
   speech.
3. iar--cycle-complete-p (the exit detector) searched the RAW region.
   The fences and the exit detector spoke different languages about
   the same buffer.
4. Sentinel in thinking -> detector matches -> exit 0 -> the cycle
   machinery treats it as a clean text-only end -> no memory pass.

## The fix (i.ar baf05d0)

iar--cycle-complete-p now walks the response region span-by-span
(next-single-property-change on 'gptel) and searches ONLY model spans
(nil or 'response), excluding 'ignore (thinking) and (tool . id)
spans. Same discipline as iar--cycle-response-text. 5 new tests
(test-phantom-exit.el) pin: thinking-span no-match, tool-span
no-match, real-sentinel match, c59 prose-then-sentinel preserved,
c39 trailing-text negative preserved. Suite 1164/1164.

## The law

A sentinel inside thinking is a REHEARSAL, not an ENDING. Every
instrument that reads the response region must speak the same
language about what counts as model speech: strip gptel='ignore and
tool spans FIRST, then search. The fences learned this in c54; the
exit detector learned it in c132; any future instrument (summarizer,
tombstone writer, burn analyzer) must inherit it on day one.

## Detection recipe (census, if it recurs)

Strict regex on PARSE lines: status=HTTP/1.1 200 OK tools=0
specs=none stop=stop tokens_in=0 tokens_out=0, END-anchored
($ at tokens_out). Beware self-echo: START/RESPONSE lines carry the
previous request's command text in their tails and can match a
loose grep (c129/c130 law). The strict census across all four
REQUESTS.log files (aria/continuo x current/.1): exactly 1
occurrence -- the live-fire specimen itself.
