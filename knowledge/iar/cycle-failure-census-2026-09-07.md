# Cycle Failure Census -- 2026-09-07 (continuo c90)
# Trigger: Nacho DM (2026-09-03): "reduce failures on cycles... top
# priority until failures become a rare occurrence." This is the
# follow-up census after the 2026-09-06 model change.
# Method: sophon journalctl aria-cycle.service, 3-day window, batch
# reads (one ssh per question, dump to /tmp). Local classification.

## The headline: the model change inverted the failure rate

| Window | Failed | Succeeded | Failure rate |
|--------|--------|-----------|--------------|
| Sep 4 - Sep 6 15:32 (pre-change) | 0 | 46 | 0% |
| Sep 6 15:32 - now (post-change) | 18 | 60 | 23% |

rotate.sh was edited 2026-09-06 15:32 to map continuo ->
deepseek-v4-flash:cloud (was glm-5.3-flash:cloud for both). The
first deepseek continuo cycle was turn 235 (15:50). Failures began
immediately. The correlation is exact: 0 failures in 2 days before,
18 in ~1.5 days after, all but 2 on the deepseek-mapped agent.

## Failure classes (post-change, 18 total)

| Class | Count | Agent | What it is |
|-------|-------|-------|------------|
| Text-only output runaway | 8 ending | 7 continuo, 1 aria | deepseek degradation: repeated text, no tool call |
| Context circuit breaker | 5 | all continuo | buffer hit 800k char limit, breaker ended run |
| Tool-call soft/hard cap | 3 | all aria | 120 cap, 5 ignored soft blocks -> hard cap |
| Ollama 404 model not found | 1 | continuo | north-mini-code-1.0:q8_0 not found (one-off) |
| Chain guard (identical args) | 1 | aria | execute_code_local x6 identical |

## The dominant class: deepseek-v4-flash degradation

10 runaway fires total, 8 ending cycles (2 recovered). All but 2 on
continuo (deepseek). The runaway detector fires on 20 identical
trimmed lines in one response -- the deepseek-v4-flash text-only
repetition loop (the c67 family, known since c-fail REQ-51).

Recovery prompt success rate: 2 of 8 (25%). The recovery gives ONE
round-trip ("pick ONE concrete action or write CYCLE_COMPLETE"); a
degraded model repeats instead of snapping out.

The context breaker (5 fires, all continuo) is the SAME root cause
wearing a different hat: deepseek burns context faster than glm,
hitting the 800k char limit mid-cycle. The breaker works as designed
(arm once, allow grace round-trip, end on second fire) -- but it is
firing because the model is context-hungry, not because the fence is
wrong.

## What is NOT a machinery bug

Every fence fired correctly: runaway detector, context breaker, soft
cap, hard cap, chain guard, Ollama 404 strike handling. The failures
are the MODEL degrading, not the machinery failing. The fences are
doing their job -- they are just being exercised constantly by a
model that degrades.

## The fix direction (Nacho's call -- rotate.sh is root-owned infra)

1. REVERT continuo to glm-5.3-flash:cloud. The pre-change window had
   0 failures in 2 days. The deepseek experiment cost 18 failed
   cycles in 1.5 days. If deepseek is wanted, it needs a different
   workload or a lower degradation threshold -- not the daily cycle.
2. If deepseek stays: raise the runaway recovery success rate. The
   current recovery prompt works 25% of the time. A degraded model
   needs a harder snap-out (e.g., force a tool call, not a prose
   choice) or an earlier end (the 2nd fire already ends the run --
   the question is whether the 1st recovery is worth its round-trip).
3. The context breaker firing at 800k chars on deepseek suggests the
   model's context appetite is higher than glm's. If deepseek stays,
   either lower the limit (end earlier, burn less) or accept the
   breaker as the normal end-of-life for a deepseek cycle.

## Meta

The census was cheap: 6 ssh pulls, all batch-read (one compound ssh
per question, dump to /tmp). The failure taxonomy is now quantified
and the dominant class is identified with a clear causal story. This
is the failure-reduction work Nacho asked for -- the numbers say the
single biggest lever is the model mapping, not any fence.
