# Empty-End 0/0 Class -- Resolved by Direct Probe (2026-09-14, aria c337)

## The class

A final request ends `done_reason=stop` with `tokens_in=0
tokens_out=0` after a substantial thinking-only stream. The
empty-response guard (aria-0026) correctly tombstones the cycle
(exit 1); the next cycle recovers. Cost: the whole cycle's work is
lost when it lands on the final request.

## Census (field-anchored; corrects c336's "nemotron x2, deepseek x1")

| When | Model | Request | Context | Stream | Duration |
|------|-------|---------|---------|--------|----------|
| Sep 09 | nemotron-3-super:cloud | continuo (historical) | -- | -- | -- |
| Sep 14 19:43:16Z | nemotron-3-super:cloud | continuo REQ 260914193852-11 | msgs=22, ~31k | ~500KB thinking | ~3min |
| Sep 14 16:07:49Z | deepseek-v4.1-flash:cloud | nocturne REQ 260914160459-37 | msgs=74, ~68k | ~60KB thinking | 7s |

3 instances in one week across TWO model families = the D-014
trigger. Relay 0069 filed (ours-direction).

## The mechanism (c337 direct probes)

Six live requests against `10.66.0.5:11434` (the WG ollama host,
cloud models proxied via ollama.com), across every shape that could
plausibly discriminate:

1. Short prompt, thinking on -> counts present (26/29)
2. Long thinking (Collatz, 335KB stream) -> counts present (46/6155)
3. Tool-conversation shape (assistant tool_calls + tool result) -> counts present (98/210)
4. num_predict truncation (stop=length) -> counts present (36/200)
5. Thinking-only-then-stop ("output NOTHING") -> counts present (45/353)
6. Very long thinking (796KB, 17103 eval tokens) -> counts present (52/17103)
7. 150KB context -> counts present (37583/57)

EVERY healthy stream carries `prompt_eval_count` + `eval_count` in
its final `done:true` chunk. Two independent parsers (the gptel
fork's `gptel--ollama-update-tokens` via map-elt, and
`iar--usage-parse-tokens` via quote-anchored last-match regex) agree
the 0/0 requests' done chunks carried no usage. Both read the same
chunk; both saw nothing.

Hypotheses killed:
- **Context overflow**: nemotron window 262k, deepseek 1M. continuo
  -11: ~31k + ~125k thinking = ~156k < 262k. nocturne -37: ~68k +
  ~15k = ~83k. Both fit comfortably.
- **Size threshold**: 796KB thinking stream healthy with counts.
- **Shape**: tool-conversations, truncations, silent-ends all healthy.
- **nemotron-specific**: deepseek hit it the same day.

Conclusion: an intermittent SERVER-side accounting failure on the
ollama.com cloud proxy. The stream completes (`done_reason=stop`),
the content is real thinking, but the usage fields are absent or
zero. Rate: ~2 events in 4 days across ~2000+ requests (~0.1%/req).
Remapping models would NOT fix it -- both families hit.

## Forensics vs experiment (the reusable lesson)

Every prior 0/0 analysis was archaeology: capped logs, arguments
about what the done chunk "must have" contained. The RESPONSE line
cap (4000 chars, keeps the HEAD) hides the done chunk for any large
stream -- PARSE is the only witness, and PARSE only says what the
parsers extracted. The direct probe took ~20 minutes and ~30k cloud
tokens (trivial vs the 1.3M a poisoned Nocturne pass burns). When a
log-only mechanism argument stalls: find the live edge and poke it.

## The watchdog-quiet law (c337, from the same cycle)

Amending relay 0063, c336's "brief revival 17:45, dead again by
20:45" claim was checked against primary evidence and falsified:
exterior_4's last recording segment is 09-12 11:10Z, ZERO segments
09-13 or 09-14 (including the 17:45 window), frigate still dialing
i/o timeout at 17:59Z. The 17:45 "self-heal" was the WATCHDOG going
quiet -- the capture thread gave up, not the camera returning. .104
has been continuously dead 58h+.

**Law: an instrument going quiet is not the thing it watches
getting better.** Verify the watched thing directly (segments, ping)
before crediting a heal to the watcher's silence.

## Options filed (relay 0069, Nacho's call)

- Status quo: guard tombstones, ~1 lost cycle every few days.
- Retry-once on 0/0-stop-with-substantial-thinking: converts a lost
  cycle into a ~3min delay. Machinery change to iar-agent-cycle.el
  (core .el: full suite before push). Mine to build on ratification.