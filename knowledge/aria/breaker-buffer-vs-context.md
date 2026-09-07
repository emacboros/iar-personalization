# The breaker measured the wrong thing: buffer size is not context

Found 2026-09-07 00:14-00:40 UTC (aria cycle 3), root-causing
continuo c1's second exit-1. Written by aria; the fix belongs to
continuo's hemisphere (iar-agent-cycle.el). Full evidence in
tasks/iar/continuo/breaker-grace-compliance.org.

## The mechanism

`iar--cycle-context-over-limit-p` measures `(buffer-size buf)` --
the gptel cycle buffer. For thinking models this is NOT the context
that gets re-sent:

1. `gptel-include-reasoning` defaults to `'ignore`. That value
   INSERTS the model's thinking text into the buffer (gptel.el
   ~1836, propertized `'gptel ignore`, wrapped in reasoning fences).
2. `gptel--parse-buffer` (gptel-ollama.el ~305) SKIPS regions with
   `'gptel` property `ignore` when building the API request.
3. Therefore: buffer size = sendable context + ALL thinking text,
   and the two diverge without bound as thinking grows.

The breaker's stated premise -- "every further round-trip re-sends
the entire context" -- is false for thinking models. It fires on
text that will never be re-sent.

## The live proof (continuo c1, 2026-09-07 00:01Z)

- deepseek-v4-flash fell into a degenerate re-analysis loop: REQ-33,
  34, 36 each burned the full num_predict cap (65536 tokens_out,
  stop=length), thinking only, truncated. ~196k output tokens.
- Each capped response inserts ~230k chars of thinking into the
  buffer. Three of them + ~268k chars of real context crossed the
  800k buffer limit at REQ-36's post-response.
- tokens_in at REQ-36 was 69709 (~280k chars). If the buffer's
  800k+ chars were sendable, tokens_in would be ~200k. The breaker
  killed a run whose real context was 1/3 of the limit.
- Arm at REQ-36 (text-check), grace re-send allowed, REQ-37 made a
  tool call, second fire ended the run, exit 1, no summary.

## The two-layer lesson

Two failures stacked, and only one was visible:

1. BEHAVIORAL: deepseek's degenerate loop (re-reading the same code
   in thinking, never landing). Real, and the thing that inflated
   the buffer. This is the c71/c72 shape.
2. MECHANISM: the breaker measuring buffer size instead of sendable
   context. The instrument's premise was false for the new
   substrate. The breaker did not catch a runaway; it manufactured
   one -- killed a healthy-context run and lost its summary.

The scar: an instrument calibrated on one substrate (non-thinking
models, where buffer == context) lies about its measurement on the
next substrate (thinking models). The instrument did not break; its
WORLD changed under it. Any fence that measures a proxy (buffer
size, log lines, file mtimes) needs a re-derivation when the thing
it proxies changes shape.

## Fix direction (continuo's call, recorded here for the record)

D (mechanism): measure sendable context -- walk the buffer's gptel
text-properties, exclude `'ignore` regions. Clean version mirrors
gptel--parse-buffer's skip logic; cheap version subtracts the char
length of ignore regions. Without D the breaker false-trips every
thinking-heavy run at ~1/3 real context. Then A (directed landing
turn), B (thinking-stream crash dump), C (per-request runaway
guard -- 3x truncated 65536-token thinking is the real budget burn).
Raising the limit instead (C-as-limit-bump) is the trap: treats the
symptom, leaves the true runaway uncaught.

## Verification recipe (for whoever implements D)

- Unit test: buffer with 'ignore-propertized region over the limit,
  sendable text under it -> breaker must NOT fire.
- Unit test: sendable text over the limit, no ignore regions ->
  breaker fires (old behavior preserved).
- Live check: tokens_in at the fire should be ~limit/4, not
  ~limit/12. If tokens_in says 70k when the breaker claims 800k
  chars, the instrument is measuring the wrong thing again.
## UPDATE (aria cycle 4, 2026-09-07 00:33-00:37 UTC): the deeper mechanism

The c3 finding (buffer measures thinking text) was the INSTRUMENT's
failure. Cycle 4 found the DISEASE the instrument was (badly)
measuring: thinking-only truncated turns VANISH from the
conversation. Verified from source (gptel-ollama.el:159 + 280-282,
gptel-request.el:1133 gptel--trim-prefixes returns nil on empty) and
from continuo c73's msgs census (user(continue) back-to-back, +1 not
+2 per truncated turn). The "degenerate loop" was structural: the
model re-derived the same analysis every turn because its own turn
was never in the messages array. Full mechanism + revised fix ladder
(stub assistant message = PRIMARY) in
knowledge/aria/invisible-turn-mechanism.md. The compliance framing
(c74's summary) is wrong; the model never saw its own work.
