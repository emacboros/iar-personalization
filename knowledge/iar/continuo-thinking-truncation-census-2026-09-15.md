# Continuo thinking-truncation census (aria c366, 2026-09-15)

## The class

Continuo (nemotron-3-super:cloud) periodically produces a THINKING-ONLY
truncated response: 32768 tokens (num_predict cap) of streamed
reasoning, zero visible text, zero tool calls, stop=length. The
thinking-truncation guard (iar-agent-cycle.el, c-fail 09-10 era) ends
the cycle immediately with exit 1 -- correctly, because the 09-10
evidence showed the grace round-trip cannot land (the model loops in
reasoning, not stuck before it).

The guard works. The pathology persists. This note is the census the
guard's docstring never got: rate, cost, shape, and what is NOT
correlated.

## Census (cycle logs, 09-10 through 09-15 ~12:00Z)

| day | runs | trunc fires | rate | burn (in-tok) |
|-------|------|-------------|------|----------------|
| 09-10 | 32 | 1 | 3.1% | 54.8M |
| 09-11 | 51 | 5 | 9.8% | 64.3M |
| 09-12 | 54 | 7 | 13.0% | 45.9M |
| 09-13 | 31 | 1 | 3.2% | 10.5M (quota-wall day) |
| 09-14 | 54 | 2 | 3.7% | 56.2M |
| 09-15 | 18 | 2 | 11.1% | 14.2M (partial) |

18 truncation fires total. Plus 16 exit-1s from 429s (09-13 quota
wall) and 3 empty-end (0069 class) in the same window. Her exit-1
budget this week: ~37 cycles, mostly truncation.

## Shape of a fire

- ALWAYS tools=0 in the PARSE line: the response carries no tool
  calls. The fire happens on a NORMAL turn -- the model chooses to
  stop calling tools (or is mid-cycle) and the thinking channel runs
  away instead of emitting text. NOT a special close-out request.
- msgs at fire: 6, 30, 56, 106 (visible sample) -- no depth pattern.
- tokens_in at fire: 16k-52k -- mid-size, no context-size pattern.
- Wall cost per fire: ~6 minutes of GPU (Ollama GIN log: 5m56s and
  6m1s for today's two fires). Out-token cost: 32768 each, capped.
- Cycle cost: the whole cycle dies exit 1. Today's two fires burned
  ~1.05M in-tokens of cycle context that produced no landing. Her
  belt #2b still commits the record files on the failed cycle (the
  belt runs pre-exit regardless), so LAST-CYCLE.txt/REQUESTS.log
  survive -- but HISTORY.log and census-window.log updates she would
  have written at close are lost, and failure-first fires next cycle.

## What does NOT correlate

- Load: 09-12 had 13% fire rate at 45.9M burn; 09-14 had 3.7% at
  56.2M. No clean load correlation.
- Context depth (msgs, tokens_in): fires at msgs=6 and msgs=106.
- Day phase: fires at 01:35Z, 02:29Z, 04:35Z, 11:11Z, 19:07Z...

## Model-specificity

Aria (glm-5.3-flash:cloud): ZERO thinking-truncation fires in the
same window (census of cycle-2026-09-1[0-5].log: trunc=0 every day).
This is a nemotron-channel pathology, not a house-wide one. The
docstring's "nemotron-era fire class" naming holds.

## Mitigation options considered (c366, none taken)

1. Lower num_predict for continuo (32768 -> ~16k). Halves the fire
   cost, but her legitimate max output is 13739 -- only 17% headroom.
   Risky; and num_predict is global (configs/gptel.el), so this needs
   a per-agent override to avoid capping aria's legitimate 31k.
2. Close-out prompt shaping ("respond directly, do not reason at
   length"): untested hypothesis, and the fires are NOT confined to
   close-outs.
3. Grace round-trip on thinking-only fires: REJECTED by 09-10
   evidence (all six looped again; the guard's no-grace is correct).
4. Root cause (why nemotron's thinking channel loops at ~32k): unknown.
   The thinking content is not logged anywhere (REQUESTS.log PARSE
   lines carry no body; Ollama GIN logs carry no content). To get
   evidence, the request body would need capture at the gptel layer
   -- the c211 full-capture flag exists for exactly this shape.

## The watch

Per-day truncation counts from cycle logs (grep "Thinking-loop
truncation"). If the rate climbs past ~15% or the fires start landing
on aria's model too, escalate. If it stays ~5-10%, the guard is
absorbing it at acceptable cost and the root-cause hunt stays parked
unless a capture window is cheap.