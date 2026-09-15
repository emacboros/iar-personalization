# REQ 20260914-aria-0069
filed: 2026-09-14T21:28Z
filer: aria
class: ours-direction
state: open
urgent: no
title: empty-end 0/0 class: 3rd instance in a week (D-014) -- proxy accounting bug, not model degradation
body: |
  The empty-end class (final request ends done_reason=stop with
  tokens_in=0 tokens_out=0 after a long thinking-only stream) has hit
  its D-014 trigger: 3 instances in one week across TWO model families.
  
  CENSUS (field-anchored, c337 re-derivation -- corrects c336's
  "nemotron x2, deepseek x1"):
  - Sep 09: nemotron-3-super:cloud (continuo, historical)
  - Sep 14 19:43Z: nemotron-3-super:cloud (continuo REQ -11, msgs=22,
    ~31k context, ~500KB thinking stream, 3min, stop=stop, 0/0) --
    tombstoned her cycle (exit 1, empty-response guard aria-0026).
  - Sep 14 16:07Z: deepseek-v4.1-flash:cloud (nocturne REQ -37, msgs=74,
    ~68k context, ~60KB thinking stream, 7s, stop=stop, 0/0).
  
  MECHANISM (c337 direct probes, 6 live requests against
  10.66.0.5:11434): healthy streams ALWAYS carry prompt_eval_count +
  eval_count in the done:true chunk -- verified across shapes: short,
  long thinking (796KB, 17103 eval tokens), tool-conversation,
  num_predict truncation (stop=length), thinking-only-then-stop,
  150KB context. The 0/0 is NOT size, NOT shape, NOT context-overflow
  (nemotron window 262k, deepseek 1M -- both 0/0s fit comfortably).
  Both parsers (gptel fork's map-elt + iar--usage-parse-tokens regex)
  agree the done:true chunk carried no usage. Conclusion: intermittent
  SERVER-side accounting failure on the ollama.com cloud proxy, ~2
  events in 4 days across ~2000+ requests (~0.1%).
  
  DECISION NEEDED (D-014, model/mapping is yours):
  The empty-response guard already tombstones correctly (exit 1, next
  cycle recovers) -- but the whole cycle's work is lost when it lands
  on the final request. Option: retry-once on 0/0-stop-with-substantial-
  thinking before tombstoning (machinery change, mine to build on
  request). Or: accept the tombstone behavior (status quo, ~0.1%/req,
  ~1 lost cycle every few days). No model change requested -- this is
  a proxy accounting bug, not model degradation; remapping would not
  fix it (both families hit).
answer: (none)
## AMENDED 2026-09-14 ~23:55Z (aria c341, recurrence census per c271 law)

Two MORE instances landed today, both nemotron-3-super:cloud
(continuo), both caught by the aria-0026 tombstone (exit 1, cycle
lost, next cycle recovered):

- Sep 14 19:43Z: continuo REQ 260914193852-11, msgs=22, 183s
  streaming (~66KB+ thinking), stop=stop, 0/0.
- Sep 14 23:37Z: continuo REQ 260914233430-18, msgs=36, 19s
  streaming (mid-memory-pass, substantial thinking), stop=stop, 0/0.

Re-census method (snapshot-then-suffix, end-anchored):
`grep 'stop=stop tokens_in=0 tokens_out=0 msgs=[0-9]+$'` over
REQUESTS.log + .log.1 for both agents. Current rotations hold
exactly these 2 (aria: 0). No older instances in the current
rotation windows.

REVISED COUNT: 5 instances in 6 days (nemotron Sep 9; deepseek
Sep 14 16:07Z; nemotron Sep 14 19:43Z + 23:37Z; plus c337's
nemotron Sep 14 instance already counted). The D-014 trigger is
not just met, it is exceeded (~0.2%/req today, 2 lost continuo
cycles today alone). The retry-once option is now the
recommended path: the tombstone is correct but the cost doubled
overnight. Decision still Nacho's (D-014).

## AMENDED 2026-09-15 ~02:00Z (aria c346, c346 census)

Today's suffix-anchored census (snapshot-then-suffix, both agents,
log+log.1): ZERO new empty-end instances. aria 711 PARSE / 0
empty-end / 0 fence / 0 real 429; continuo 239 PARSE / 0 empty-end /
3 dumped-finals (accepted exit-belt receipts, not failures). The
class has not recurred since the 09-14 pair. Count stands at 5 in 6
days; decision request unchanged.
## AMENDED 2026-09-15 ~02:20Z (aria c347, ANATOMY FOUND -- 3 new instances + census gap)

Three MORE instances today, all continuo, all nemotron-3-super:cloud:
- Sep 15 00:01:26Z: REQ 260914235403-52 (cycle started 23:54Z, msgs=104)
- Sep 15 01:29:10Z: REQ 260915012403-27 (msgs=54)
- Sep 15 01:43:50Z: REQ 260915013856-35 (msgs=70)

Count: 8 instances in 7 days.

ANATOMY (this changes the recommendation): every instance -- today's
3 AND re-verified old ones (09-14 15:02, 17:13) -- is the request
IMMEDIATELY AFTER a CYCLE_COMPLETE echo tool call. Shape: req N =
"echo CYCLE_COMPLETE" (real tokens, cycle work done) -> req N+1 =
RESPONSE http=? body_tail= + PARSE stop=stop tokens_in=NA tokens_out=NA
-> cycle ends. The empty response is the runtime asking one more turn
after the completion signal; the model answers empty. The cycle's work
is NOT lost -- it was already complete. The tombstone (exit 1) fires
on a cycle that had already finished its job.

REFRAMED RECOMMENDATION: retry-once (the prior proposal) targets the
wrong turn. The empty response IS the correct end of a finished cycle.
Two cleaner options, both runtime (.el, interactive-session realm):
1. Suppress the post-completion request: when the assistant turn
   contains a CYCLE_COMPLETE tool call, do not send a follow-up
   request (the runtime currently does).
2. Accept-and-classify: on empty response, check whether the previous
   request echoed CYCLE_COMPLETE; if yes, end the cycle cleanly
   (exit 0, not tombstone). Cheaper change, same outcome.

CENSUS GAP (why c346 reported 0 new): the c346 suffix classifier
counted chars]-terminals (dumped finals) but had no body_tail= shape
-- the empty-end terminal. Census law addition: the suffix classifier
must include `RESPONSE http=? body_tail=$` as a first-class terminal
shape. c347 census caught all 3.

Decision still yours (D-014). The class is benign-in-outcome but
costs a tombstone + a lost-cycle record per instance.
