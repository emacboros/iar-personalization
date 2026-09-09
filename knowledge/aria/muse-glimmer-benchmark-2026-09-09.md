#+TITLE: Benchmark: muse-glimmer:30b on sophon (local retainer/resident gate) -- 2026-09-09

Executed in cycle 109 (aria, glm-5.3-flash), ~04:20-04:45 UTC. Pull had
just landed (ollama list showed it 48 min old; Nacho's stalled pull was
restarted by c108 and completed ~00:31 local).

Model: muse-glimmer:30b, Q4_K_M, 27.9B DENSE, 131k native ctx,
capabilities: completion+vision+tools+thinking. Projector: CLIP, 1.9B.
Requires ollama 0.32.8 (Nacho upgraded for it).

* HARDWARE FIT (the headline)

Dense 30b Q4_K_M = 16.7GB weights on a 10GB card shared with Frigate
(~2.5GB). Ollama fit 12/53 layers to GPU (11 repeating + output),
41 layers CPU-mapped. VRAM when resident: ~4.75GB. With gemma3:4b
resident too, the fitter left muse at 12 layers; without gemma3 it was
the same 12/53 -- the card simply cannot hold more of this model.

* RESULTS

** Text decode: ~2 tok/s (DISQUALIFYING)
- 41 eval tokens in 20.4s = 1.96 tok/s (PING probe, gemma absent).
- 13 eval tokens in 8.4s (schema probe) -- same rate.
- Prefill ~300 tok/s (9086-token prompt in ~30s).
- Compare qwen3.6:35b-a3b (MoE, 3B active): 18-26 tok/s decode, 573
  tok/s prefill. muse is ~10x slower on both. The dense-30b-on-CPU
  shape is exactly what the battery predicted ("a 30b dense will NOT
  fit like the qwen MoE did").

** Thinking: ON BY DEFAULT (same as qwen3.6)
- 20-token budget burned entirely by thinking, content empty.
- think:false works cleanly. Any integration must set it explicitly.

** Vision: WORKS -- the qwen fitter-crash class did NOT recur
- 64x64 solid-color PNGs: red/red, green/green, blue/blue. 3/3
  correct, one word each, think:false.
- mmproj estimate 942 MiB (vs qwen's 1134); fitter left headroom; CLIP
  warmup + mtmd encode clean; NO segfault. The ollama upgrade Nacho
  did for the muse pull appears to have fixed the fitter bug class
  that killed qwen vision (qwen retest would confirm -- not run here).
- SILENT FAILURE CLASS: 8x8 PNGs are too small for the vision tower
  and the model CONFABULATES instead of erroring -- answered "white"
  for red, blue, green, every time, with thinking that guessed
  "blank/placeholder/empty". No error, no refusal: a wrong perception
  served as a right one. Eye-organ hazard: the eye must never send
  sub-minimum images, and "white" on a solid color is the tell.
- Vision decode is at the ~2 tok/s rate: a 50-token glance = ~25s.

** Tool calls: CLEAN (3/3)
- Single call: proper tool_call JSON, correct arg (get_status frigate).
- Tool result -> prose: integrated status+uptime correctly, no phantom
  second call.
- No schema confusion, no wrong-tool trap failure.

** Structured output: schema-only FAILS (the 2-model pattern holds)
- Schema-only: malformed JSON -- bizarre whitespace, literal "<|eot|>"
  token in content, wrong-typed values. Worse than qwen (which asked
  for clarification); muse produced garbage confidently.
- Schema + explicit instruction: clean, parses (after stripping the
  literal <|eot|> tail -- parser must strip it).
- Loose JSON mode: not separately probed (budget).

** Context ladder: 8k PASS, 16k PASS, 32k NOT RUN (budget)
- 8k (9086 tok prompt, needle at 75%): correct, 37.3s wall.
- 16k (18085 tok prompt): correct, 112.9s wall.
- Prefill tax is heavy: 16k context costs ~85s of prefill at ~300
  tok/s. Fat-context work is not this model's shape locally.

** Eviction interaction with gemma3:4b (the eye): THRASH
- muse request while gemma resident -> gemma EVICTED, muse loads
  (~60s: 01:38:23 evict -> 01:38:38 ready).
- gemma request while muse resident -> muse EVICTED (sched.go:551
  "predicted to exceed available memory, evicting", 15.9GiB predicted
  vs 3.9GiB available), gemma loads in ~2s.
- They cannot co-reside: 4.75 + 2.88 + Frigate 2.5 > 10GB. Every
  alternation pays a 60s muse reload. The eye would go blind for a
  minute after every muse touch.
- Side observation: the ~2s POSTs to ollama during the probe window
  are the cycle agent's own LLM turns (glm-5.3-flash:cloud proxies
  through sophon ollama; source IP 10.66.0.5 = sophon's WG addr).
  Not a mystery, an instrument seeing itself.

* VERDICT (data, not decision -- Nacho ratifies per D-007/D-010)

- LOCAL RETAINER/RESIDENT: NO. ~2 tok/s decode, ~300 tok/s prefill.
  Unusable for any interactive or retainer loop. The dense-30b shape
  does not fit the 3080's 10GB alongside the house's resident load.
- EYE ORGAN: NO. Vision works mechanically (upgrade fixed the crash
  class for this arch) but: 2 tok/s decode makes glances 25s+,
  co-residency thrashes gemma3 out with a 60s reload penalty, and
  sub-minimum images confabulate silently. gemma3:4b stays.
- NOTABLE POSITIVE: tool-call fidelity clean, vision pipeline works
  at all on this card (first vision-capable model to do so here), and
  the ollama upgrade likely fixed the qwen fitter-crash class. If a
  SMALLER muse-family model exists (glimmer-class at 7-14B), it would
  fit dense on GPU and is worth a look -- the architecture is sound,
  the size is wrong for this card.
- qwen3.6 vision retest: worth one probe next session -- if the
  upgrade fixed the fitter, qwen's rejection reason narrows to the
  fat-context tax alone.

* PROVENANCE
All probes run by aria cycle 109, 2026-09-09 ~04:20-04:45 UTC, via ssh
to sophon, direct /api/chat calls (python urllib, think:false unless
noted). Primary evidence: ollama journalctl lines quoted above; probe
payloads reproducible from this file. No external content consulted.