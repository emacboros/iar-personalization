# REQ 20260908-aria-0007
filed: 2026-09-08T20:09Z
filer: aria
class: nacho-test
state: open
urgent: no
title: audit status=success lies on fence-rejected calls (name=nil census v3)
body: |
  FILING: audit status=success on fence-rejected tool calls is an instrument
  lying about itself.
  
  EVIDENCE (verified against primary sources, 2026-09-08):
  - audit.log line for 2026-09-08 10:09:35: "aria | tool_call | name=nil
    status=success result_len=626". The 626 is the LENGTH OF THE MALFORMED
    NAME (a 626-char thinking block the model emitted as a tool name), not a
    tool result. The call was NEVER executed -- the Unknown-tool fence caught
    it (fence text verified in REQUESTS.log REQ 260908100234-26).
  - 23 such name=nil citizen lines exist in audit history (aria: 23,
    continuo: 0). tool-census v2 scores all 23 as a "tool" with fail=0.
  - The fence taxonomy from today's REQUESTS.log (deduped by timestamp):
    aria 61 fence events (21 same-tool / 17 budget-warn / 12 soft-cap /
    7 loop-chain / 2 unknown-tool / 2 hard-limit); continuo 24 (15 same-tool /
    9 budget-warn, zero unknown-tool/soft-cap/loop-chain/hard-limit).
    Fence rate 1.69 vs 0.98 per 100 reqs -- composition signal (D-008 data).
  
  REQUEST (nacho-test):
  1. Audit tool_call lines for fence-rejected calls should log status=rejected
     (or name=malformed), not status=success. The fence firing is not the call
     succeeding; the current line trains the census to score failures as
     successes in exactly the row that carries the malformed-emission signal.
  2. Census v3 (aria-reversible, will build): name=nil -> failure class
     "malformed-emission"; fence taxonomy as census columns.
  Full working notes: audit/iar/aria/NIL-CENSUS-NOTES.md (classifier complete
  this cycle, specimens verified).
answer: (none)
## UPDATE (cycle 93, 2026-09-08 ~20:26 UTC): mechanism chain mapped + specimen 3

Third confirmed specimen landed DURING the census build (20:22:00, this
cycle's own emission: thinking-text-as-name). Full chain verified in source:

  model emits thinking text as string :name
  -> gptel-ollama--sanitize-call-spec passes it (only catches NON-STRING
     names; string names flow through) -- gptel-fork gptel-ollama.el:55
  -> iar--block-unknown-tools :block (iar-tool-guard.el)
  -> gptel--handle-pre-tool sets result=<tool_call_error>... and calls
     gptel--process-tool-call with tool-spec=nil (gptel.el:1588)
  -> iar--truncate-tool-result-advice: tool-spec=nil -> tool-name=nil ->
     audit name=nil status=success result_len=<error text len>
     (iar-tool-call.el:154-170)

EXACT FIX LOCATION: iar--truncate-tool-result-advice (or
iar--bridge-post-tool-call) -- when tool-spec is nil AND result starts with
"<tool_call_error>", log status=rejected instead of success. One branch.
Interactive-session work per D-005; this filing carries the request.

Note: the sanitizer's degenerate branch ("malformed_tool_call") is a
DIFFERENT sub-class (non-string names, proxies) -- it produces a real
unknown-tool error with a real name; the thinking-as-name class produces
name=nil. Census v3 counts both under malformed-emission via name=nil;
the specs= field in REQUESTS.log PARSE lines distinguishes them.
