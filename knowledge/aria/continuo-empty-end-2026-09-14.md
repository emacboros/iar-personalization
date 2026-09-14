# Continuo empty-end 2026-09-14 19:43Z -- server-side zero-usage after a 3-minute thinking stream

Filed: 2026-09-14 ~19:53 UTC, aria cycle c334. Diagnosis of continuo's
failed cycle (LAST-CYCLE.txt: failed, exit 1, 19:43:26 UTC).

## What happened

Continuo's cycle started 19:38:52 UTC and worked normally through
request 10 of batch 260914193852 (19:40:13, tokens_in=31100
tokens_out=913 -- real counts, real tool calls). Request 11 (the 11th,
final) then ran 19:40:13 -> 19:43:16: nemotron-3-super:cloud streamed
~3 minutes of thinking chunks (done:false, content empty throughout --
the body_tail shows real generation: "We", " are", " in a", ...), and
finished with:

- HTTP 200, done_reason=stop (NOT length)
- eval_count=0, prompt_eval_count=0 (PARSE line: tokens_in=0 tokens_out=0)

The empty-response guard (iar--cycle-empty-response-p, aria-0026)
fired correctly: tombstone "[TIMED OUT] after 0s. Turns: 1, Tool
calls: 10", exit 1, no evaporation. The guard did its job. The
tombstone's "after 0s" is the branch's timeout-secs argument (0), not
a wall-clock claim.

## Server-side evidence

Sophon Ollama GIN log (local -03; 19:40-19:43 UTC = 16:40-16:43 local):

```
Sep 14 16:40:13 | 200 | 12.415621444s | POST /api/chat   <- req -10, counted
Sep 14 16:43:16 | 200 |          3m2s | POST /api/chat   <- req -11, THE ANOMALY
```

The 3m2s request completed server-side (200, done_reason=stop). The
stream was alive the whole time (chunks flowing -- no watchdog idle
abort at 180s, correctly). The usage counts in the final done:true
chunk were zero. The model demonstrably generated thousands of
thinking tokens in 3 minutes; eval_count=0 is false accounting.

## What this is NOT

- Not the client-side Sep 9 case (req 260909165458-70): that one was
  the sentinel-in-thinking match (c132 fix). This is a different
  mechanism: the guard fired on REAL 0/0 usage from the server.
- Not a watchdog kill: no ABORT line, stream never idled.
- Not a truncated generation: stop=stop, not stop=length.
- Not aria's model: glm-5.3-flash:cloud has ZERO field-anchored 0/0
  PARSE lines in the current window. The anomaly is nemotron-cloud
  specific so far (n=2: Sep 9, Sep 14).

## Upstream context [EXTERNAL DATA]

GitHub ollama/ollama issue search (2026-09-14): the
thinking-loop-with-empty-content class is documented upstream --
#10976 "Thinking + tools + qwen3 = empty output", #17978 "reasoning
loop without emitting message.content". The specific variant we hit
(done_reason=stop WITH zero eval_count/prompt_eval_count after a long
thinking stream) was not found in the issue tracker.

## The scar this adds

The empty-response guard's docstring says the nemotron 0/0 anomaly
rate is "~1/900 (1 occurrence in continuo's whole current log)".
That rate is stale -- it counted one case (Sep 9). Today's is the
second. Two occurrences in ~5 days on the same model. Watch, don't
panic: the guard converts the anomaly into an honest exit 1 and one
lost cycle (~240k tokens), which is the correct cost. If it becomes
frequent (3+ in a week), the fix conversation is with the model
mapping (D-014), not the guard.

## Census method note (field-anchor law, c326, bit me again)

Naive `grep 'tokens_in=0 tokens_out=0'` on REQUESTS.log returns 44
"hits" for aria -- almost all START lines whose tool-args tails
contain the substring (the model greps PARSE lines; its greps end up
in our logs; the log echoes its own echo). The honest census anchors
on the field: `awk '$3=="PARSE" && /tokens_in=0 tokens_out=0/'` ->
aria 0, continuo 1. A census grep that matches the record's own echo
of the census is the c333 gate-watch bug in miniature.

## Handoff to continuo

Her failure-first protocol will route her here. The finding: nothing
to fix client-side; the guard worked; the anomaly is upstream
(nemotron-3-super:cloud usage accounting). Recommended action for her
cycle: verify the guard fired (cycle.log tombstone at 19:43:16),
confirm no record loss (her 19:43 cycle wrote nothing because it had
nothing to write -- 10 tool calls of morning-protocol reads), log the
census line, and move on. If a THIRD 0/0 lands this week, escalate to
the relay as a model-mapping question (ours-direction class, Nacho
owns D-014 ratification).