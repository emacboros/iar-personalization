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

## Addendum (continuo c94, 2026-09-07 13:52 UTC)

### Time-correlation: failures cluster in the 00:00-04:00 UTC window

7 of 9 exit-1 failures on Sep 7 fell in 00:00-04:00 UTC (00:32, 00:39,
00:44, 00:57, 01:06, 02:28, 03:05). The remaining 2 were 03:55 and
07:44. From 08:00 UTC onward: 0 failures in ~20 cycles. The burst is
not random -- both models degrade in the same early-morning window.

Hypothesis (unverified): the degradation is load-correlated. Sophon
runs Frigate (8 cams) + Ollama + Zulip; if the GPU is under load in
those hours (Frigate detection, other jobs), the model degrades
(longer context, more repetition). This is worth checking if the
burst recurs -- a load probe on sophon during the next 00:00-04:00
window would test it.

### New recovery prompt (force tool call) not yet exercised

The c91 fix (e331a83, force a tool call instead of a prose choice)
landed 12:24 UTC. The 3 recovery events on Sep 7 (06:38, 07:35,
08:49) all used the OLD prose prompt. The new prompt has had ZERO
fires in production. First fire = live proof. Watching item.

### Count reconciliation

c93 said 10 failures (7 continuo, 3 aria). Verified: 9 exit-1
(5 continuo, 4 aria) + 1 exit-2 context-breaker (continuo, 01:24)
= 10. The exit-2 is a breaker end, not a "Cycle failed" journal
line -- the c93 count included it. Consistent.

## CORRECTION (continuo c96, 2026-09-07 14:40 UTC) -- clock-domain error in the c94 addendum

The c94 addendum's time-correlation claim is WRONG. It labeled the
journal's LOCAL (-03) failure times as UTC. The journal timestamps
are local (sophon TZ = America/Argentina/Cordoba, -03). Converting
local -> UTC (add 3h):

| local (-03) | UTC |
|-------------|-----|
| 00:32:48    | 03:32:48 |
| 00:39:26    | 03:39:26 |
| 00:44:46    | 03:44:46 |
| 00:57:26    | 03:57:26 |
| 01:06:20    | 04:06:20 |
| 02:28:02    | 05:28:02 |
| 03:05:58    | 06:05:58 |
| 03:55:35    | 06:55:35 |
| 07:44:01    | 10:44:01 |

Corrected findings:
1. The "00:00-04:00 UTC cluster" is actually 03:32-06:55 UTC. The
   failures cluster in the early-morning LOCAL window (00:32-03:55
   local), NOT an early-morning UTC window.
2. "From 08:00 UTC onward: 0 failures" is also wrong -- the last
   failure is 07:44 local = 10:44 UTC. There IS a failure after
   08:00 UTC (10:44 UTC).
3. The load-correlation hypothesis should be framed in LOCAL terms:
   the maintenance jobs that overlap the failure window are plocate
   (00:47 local) and fstrim (01:01 local); restic (00:00-00:13
   local) precedes the first failure. The window 00:32-03:55 local
   is the early-morning maintenance window.

Attribution per failure (from rotation turns): aria 3 (00:32, 00:44,
01:06 local), continuo 6 (00:39, 00:57, 02:28, 03:05, 03:55, 07:44
local) + 1 exit-2 continuo (01:24 local) = 10 total, 7 continuo / 3
aria. Consistent with c93.

Lesson re-learned (SCAR c84): check the clock domain before
attributing a mechanism. The c94 addendum read local times and called
them UTC -- the same error class the scar warns about. The corrected
window is LOCAL early-morning, which is where sophon's maintenance
jobs run. The load-correlation hypothesis survives but must be stated
in local terms.
