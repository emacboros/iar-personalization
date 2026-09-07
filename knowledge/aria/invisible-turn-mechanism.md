# The invisible turn: thinking-only truncated turns vanish from the conversation

Found 2026-09-07 00:33-00:37 UTC (aria cycle 4), extending
breaker-buffer-vs-context.md (c3). Root-causing continuo c73's
exit-1 from primary evidence (REQUESTS.log epoch 260907000143)
plus the gptel-fork source. THE fix belongs to continuo's
hemisphere (gptel fork + iar-agent-cycle.el).

## The mechanism (verified from source, both paths)

1. deepseek-v4-flash hits the num_predict cap (65536) MID-THINKING.
   Response: content="" , thinking=<65k tokens>. stop=length.
2. Streaming insert (gptel.el ~1970-2020): thinking goes into the
   buffer propertized 'gptel ignore. Content is empty -- nothing
   else inserted.
3. Next request rebuilds the messages array from the buffer
   (gptel--parse-buffer, gptel-ollama.el:271). 'ignore regions are
   skipped. The 'response region is EMPTY, and gptel--trim-prefixes
   (gptel-request.el:1133) "Return nil if string collapses to empty"
   -- so the when-let fails and NO assistant message is pushed.
   (Non-streaming path confirms: gptel-ollama.el:159 drops
   string-empty-p content.)
4. The post-response handler sees no sentinel, no tools -> inserts
   the continue prompt. msgs +1 (user only).
5. The model's next view: [..., user(continue), user(continue)].
   Its own 65k-token thinking turn is INVISIBLE.
6. The model re-derives the same analysis in thinking, hits the cap
   again, repeat. THE DEGENERATE LOOP IS STRUCTURAL.
7. Buffer grows ~230k chars per capped turn (thinking text).
   tokens_in stays ~70k (messages array stays small).
8. After ~3 capped turns the buffer crosses 800k -> breaker arms on
   buffer size (false premise, c3 finding). Grace round-trip spent
   on a tool call -> second fire -> exit 1, no summary.

## The live proof (continuo c73, epoch 260907000143)

- REQ-33, 34, 36: PARSE tools=0 stop=length tokens_out=65536 each.
  ~196k output tokens of thinking, all truncated, all invisible.
- msgs census: REQ-34 msgs=72 tail shows tool + user(continue);
  REQ-35 msgs=73 tail shows user(continue) + user(continue)
  BACK-TO-BACK -- no assistant message between them. The turn
  vanished. This is the smoking gun, visible in the msgs counts:
  a thinking-only turn adds +1 (the continue), not +2.
- c71's "degenerate loop of repeating phrases" in cycle.log was
  THINKING text -- visible to us in the log, invisible to the model
  in its own next request.

## This upgrades the diagnosis

continuo c74's summary called the shape a "model-compliance
failure": the fence fires correctly, the model doesn't land. WRONG
FRAMING. The model was structurally prevented from seeing its own
work. deepseek never had a chance to comply. c74 reached that
conclusion because c74 only read cycle.log (the buffer transcript,
which contains the thinking) -- the msgs census in REQUESTS.log,
which shows what the model actually SAW, tells the other story.
Two records, two stories; the one that shows the model's view is
the one that was right.

## Why c74 itself survived

c74 hit the same breaker (REQ-30 second fire, 00:32:20) but
complied and landed exit 0. Difference: the breaker's message
reached it as a TOOL RESULT (role:tool in the messages array) --
tool results are always visible. The failure mode is specific to
thinking-only turns.

## Fix ladder (revised; continuo's call)

PRIMARY (new, upstream): a thinking-only truncated turn must not
vanish. When content is empty but thinking exists, synthesize a
stub assistant message in the rebuilt array, e.g.
"[thinking truncated at output cap -- your last turn's reasoning
was cut off; land or continue concisely]". The model must see its
own state. Where: gptel--parse-buffer (ollama method) or a fork
hook. Test: buffer with ignore-propertized thinking + empty
response region -> parse must yield a non-empty assistant message.

D (breaker honesty, from c3): measure sendable context
(text-properties walk, exclude 'ignore). Still needed -- the
breaker's premise is false regardless.

A (directed landing turn) + B (thinking-stream crash dump) + C
(per-request runaway guard): unchanged from c3. C matters more
now: 3x truncated 65536-token thinking IS the budget burn, and
each truncated turn is also a data-loss event (the thinking is the
model's only record of its own work).

num_predict: raising it so thinking completes would also stop the
loop, but it is a budget trade (Nacho's mandate) and does not fix
the vanish. The stub message is cheaper and honest.

## Verification recipe

- Reproduce: any thinking model + low num_predict + a prompt that
  induces long thinking. Watch msgs counts across turns: a
  thinking-only turn must add +1 (assistant stub) not +0.
- REQUESTS.log check: "user(continue), user(continue)" back-to-back
  in a msgs tail = a vanished turn. Grep for it after any
  stop=length tools=0 turn.

## Scar (41 amended)

An instrument calibrated on one substrate lies on the next (c3).
Deeper: a TRANSPORT can silently drop a model's own turn, and the
model will not know its work was never delivered. The failure is
not "the model didn't comply" -- it is "the model never saw the
world its compliance was owed to". Before blaming compliance,
verify the model's actual view (msgs census), not the transcript
(buffer) and not the intent (prompt).
* UPDATE (2026-09-07 01:20 UTC, aria c6): third instance + the +N anomaly

The 01:00 continuo c1 (epoch 260907010044) reproduced the invisible
turn WHILE READING this file and the handoff -- knowing the
mechanism did not save it. The fix must be in the transport (P0
stub), not the prompt.

NEW: the msgs arithmetic is NOT the simple "+1 per invisible turn"
my c4 model predicted. Census: REQ-32 (truncated) -> +4; REQ-51
(truncated) -> +10. Baseline turn = +2. Candidates checked and
eliminated this cycle: unpropertized response separators (collapse
to empty in trim-prefixes), partial tool-call regions. The full
msgs array is not logged (tail= keeps only last 2 msgs) -- the
decomposition needs a cheap instrument: log the last 6 msgs' ROLES
in the START line. Filed in the handoff (UPDATE 3) with the full
census.

P0 unchanged: stub assistant message for truncated thinking-only
turns. Write the P0 regression test from a REAL captured buffer
shape, not from the c4 paper model -- the +N says the paper model
is incomplete.
