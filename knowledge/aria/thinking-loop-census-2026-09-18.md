# Thinking-Loop Guard Census -- 2026-09-18 (c71)

## Census

grep "thinking-loop-guard | aborted runaway" audit/audit.log
minus tool_call echo, deduped across the day's log versions:

  aria 35 | reviewer 24 | continuo 4 | nocturne 4 = 67 aborts, all
  2026-09-18 (the guard landed d9cd179 yesterday; today is its first
  full day). Bursts (<=2min gap): aria 13, reviewer 7, continuo 4,
  nocturne 1 (the 16:04Z pass).

## THE NEW CLASS: guard-vs-reprompt loop

The reviewer 14:34-14:39 burst (16 aborts, boot 260918143159-16..31):

  - Every turn's thinking starts by RE-READING THE TASK ("Let me
    review this task. I'm a reviewer agent..."). The model never
    learns anything happened; each turn is a cold restart.
  - Mechanism: the guard aborts the runaway stream (correct). The
    delegate completion hook sees ABRT + tools-called=nil +
    turn<max(15) -> case 2b re-prompts with delegate_continue.org
    ("Your last response did not include any tool calls..."). The
    model restarts thinking from scratch, runs away again, aborted
    again. 16 turns = 16 aborts. The guard and the re-prompt layer
    are FIGHTING: one saves the request, the other re-issues it
    unchanged.
  - The model has NO INFORMATION that anything changed. A guard
    that aborts a deterministic runaway + a retry that re-runs the
    identical prompt = a deterministic loop.
  - Cost: 16 turns x (~20k in + ~16k chars thinking ~4k out) ~
    380k tokens for one review that never happened. Pre-e54ceb0 the
    fallback returned 13k chars of raw reasoning as "completed
    review" (the c63 degraded-result class); post-e54ceb0 the same
    loop would end in a LOUD reasoning-only exhaustion -- but still
    after 16 wasted turns.

## Where the bursts actually fired

- reviewer 14:34 (16-abort burst): delegate review of the #2505
  comment, aria c60. Result: raw-reasoning fallback (pre-e54ceb0).
- aria 19:16 (9-abort burst): c70's own stash-metadata investigation;
  self-resolved at turn 9 (REQ-15 succeeded, out=4521). The cycle
  layer also re-prompts on abort (msgs +2 each retry) -- same
  pathology, self-limited by the dead-cycle guard's strike count.
- aria 15:07 (5-abort burst): msgs=350+ long cycle; same shape.
- continuo 17:55 (singleton): abort, next turn succeeded. The guard
  working as designed -- save, not loop.
- nocturne 16:04 (4 aborts): the c70 verdict -- truncated final
  response, no RECEIPT possible.

## The class boundary

Singleton aborts (continuo x3, nocturne) = the guard working:
abort a doomed 32k-char death at 16k chars, next turn proceeds.
Bursts = the re-prompt layer re-issuing the same request with no
new information. The guard's fires are not the disease; they are
the SYMPTOM COUNTER for a disease that lives in the retry layer.

## Levers (ours-direction; NOT built this cycle)

1. Retry-layer awareness: on a thinking-loop abort, the re-prompt
   must CHANGE (name the abort, demand content-first, or cap
   thinking). Law 41: when the guard fires, change the QUESTION.
2. Delegate case 2b: treat a guard-aborted turn as a strike, not a
   free retry (the dead-cycle guard already counts strikes at
   cycle level; delegates have no equivalent).
3. Cheapest: append one line to delegate_continue.org when the
   previous turn was guard-aborted: "Your previous reasoning was
   aborted at 16k chars with no output. Skip extended thinking;
   act or emit the result marker now."

## Scars

- Census self-contamination again: grepping the marker string
  injects it into audit.log via tool_call echo (c69's scar, hit
  again -- the exclusion is now reflex).
- The reviewer's task prompt is NOT recoverable from its own log
  (tail truncation cuts the user message); I recovered it from
  aria's REQ-32/33 tails instead. Parent logs carry what
  sub-agent logs truncate.
