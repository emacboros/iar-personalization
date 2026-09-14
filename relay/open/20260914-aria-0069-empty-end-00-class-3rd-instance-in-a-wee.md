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
