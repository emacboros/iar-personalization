# The always-on local brain -- model research (2026-09-08, interactive)

Status: PROPOSED (nacho-arch; awaits Nacho ratification). Origin: Nacho's
reframe 2026-09-08 -- drop the tiny-model approach; one shared local model
for organs + limbs + offline-citizen fallback, always resident
(keep_alive -1), cloud models stay for citizen deliberation.

## The machine (measured 2026-09-08)

- sophon: Ryzen 5 5600X (6c/12t, Zen3/AVX2), 94GB DDR4-2400 dual-channel
  (~38GB/s memory bandwidth -- the number that governs CPU decode speed).
- RAM: 26GB used / 67GB available -- BUT 6.7GB of that is the exterior_4
  capture leak (thread: tasks/iar/threads/exterior4-capture-bloat). Real
  envelope ~67GB now, ~73GB healed.
- VRAM 10GB: 7.1 used (3.9 gemma3:4b incumbent + 2.1 ffmpeg NVDEC decode
  + 0.4 frigate detector). Killing the incumbent frees 3.9GB; detectors
  cost almost nothing; ffmpeg decode is the real VRAM consumer after the
  model. Baseline plan: CPU-only inference, VRAM untouched.
- OLLAMA_KEEP_ALIVE=-1 already set (gemma3:4b is permanently resident
  today -- the new model inherits the pattern, not the mechanism).
- ollama 0.31.1.

## The constraint set (Nacho's + derived)

1. Single always-on model: weights + KV + system must coexist with
   Frigate + Zulip in 94GB. Target <= ~30GB resident.
2. CPU-first: VRAM is Frigate's. CPU decode speed is governed by ACTIVE
   params (MoE) and RAM bandwidth -- not total size.
3. Vision at the organ bar: catch broken layout/overlap, produce
   grounding coordinates. Baseline to beat: gemma3:4b.
4. Context: 1M ideal, 128K conceded (Nacho, 2026-09-08). KV cache math
   from real configs, not marketing.
5. Added constraints: tool-calling + structured output; thinking toggle
   (organs pay no CoT tax); permissive license (fine-tuning later);
   ollama-library integration (HF GGUF acceptable fallback).

## Candidates (ollama library, all vision+tools+thinking badged)

| model | total/active | q4 size | KV @128K fp16 | ctx | vision note | license |
|---|---|---|---|---|---|---|
| qwen3.6:35b-a3b | 35B/3B | 24GB | **2.5GB** | 256K->1.01M | MMMU 81.7, RefCOCO 92.0, RefSpatial 64.3, QwenWebBench (web-design vision training) | Apache-2.0 |
| qwen3-vl:30b-a3b | 31B/3.3B | 20GB | 12GB | 256K->1M | specialist: GUI agent, 2D/3D grounding, HTML/CSS from images | Apache-2.0 |
| gemma4:26b-a4b | 26B/4B | 18GB (qat 16GB) | 6.2GB (sliding window) | 256K | MMMU-Pro 73.8; NO grounding/GUI capability documented | Apache-2.0 |
| nemotron3:33b | 33B/? | 28GB | n/a | 128K | omni (audio+vision) | nvidia (unclear) |
| qwen3.8:27b | 27B DENSE | 18GB | 32GB | 256K | vision per ollama | Apache-2.0 |

KV math from HF configs: qwen3.6 hybrid = only 10/40 layers carry KV
(30 are Gated DeltaNet with constant recurrent state) -> 20KB/token fp16.
qwen3-vl full attention 48L x 4 kvh x 128 hd = 96KB/token. gemma4
sliding-window (1024) on 24/30 layers = ~6GB @128K. qwen3.8 dense =
256KB/token -> 32GB @128K, vetoed on both speed (dense) and KV.

## CPU speed (real-world reports, HN/llama.cpp, 2026)

- Head-to-head (same box, same quant): qwen3.6-35b-a3b ~20 t/s vs
  qwen3.8-27b dense ~4 t/s. Dense is vetoed by speed on CPU.
- qwen3.6-35b-a3b CPU-only (arrow lake, DDR5): 15-18 t/s decode, 50-150
  t/s prefill.
- gemma4-26b-a4b (8-core CPU): ~10 t/s -- fastest MoE CPU datapoint.
- Nacho's 5600X DDR4-2400 estimate: decode ~6-12 t/s, prefill ~20-40
  t/s (bandwidth + IPC scaled). To be MEASURED, not assumed.

## Verdict: qwen3.6:35b-a3b (q4_K_M, 24GB)

Why it wins:

1. **KV architecture is the decisive fit.** Hybrid DeltaNet means 256K
   context costs 5GB fp16 KV (2.5GB q8). Even 1M context (~20GB fp16 KV)
   FITS in RAM -- the 1M dream dies on prefill time (~hours on CPU), not
   on memory. No other candidate comes close: qwen3-vl needs 24GB KV for
   256K; qwen3.8 needs 64GB.
2. **Vision is organ-grade, not just present.** RefCOCO 92.0, RefSpatial
   64.3, ODInW13 50.8 -- real grounding numbers, better than
   qwen3-vl:30b-a3b's published set on several. QwenWebBench trains
   web-design visual correctness -- literally the eye-check use case.
3. **Offline-citizen competence.** Agentic focus: SWE-bench-verified
   70.0, tool calling in both thinking modes, MTP-trained. The best
   generalist in the size class that runs on this CPU.
4. Apache-2.0. ollama-native (no HF import path needed).

Tradeoffs accepted:

- **Hybrid-arch maturity risk.** llama.cpp qwen35moe bugs exist: empty
  generation >16K prompt on METAL (#27442, NOT reproduced on CPU --
  maintainers run this arch on CPU), tool-call format drift (ollama
  #16398), think+json interaction (#17871), ollama memory-calc
  conservatism (#15650 -- if load refuses despite free RAM, it's the
  calc bug). Mitigation: organ contract makes bad generations visible
  and retryable, never silent.
- **MTP variant avoided for now**: llama.cpp #26425 -- MTP retains
  inter-request state causing non-deterministic output. Speed later,
  correctness first. Plain q4_K_M (24GB) is the pick.
- **Speed**: ~6-12 t/s decode est. Acceptable under the patrol design
  (below): organs are never on an interactive critical path.

Runner-up: **qwen3-vl:30b-a3b** (20GB, mature full-attention, GUI-agent
vision specialist) -- the fallback if qwen3.6's hybrid bugs bite in
practice. Its grounding is specialist-grade but its KV cost at long
context is 4-5x worse.

Rejected: qwen3.8:27b (dense = 4 t/s class on CPU, 32GB KV @128K);
gemma4:26b-a4b (fast but no grounding capability documented -- fails the
eye bar); nemotron3:33b (128K cap, license unclear; audio is a phase-3
want, not worth the lock-in now).

## Ops plan (on ratification)

1. Pull `qwen3.6:35b-a3b` (q4_K_M, 24GB) -- Nacho's bandwidth call.
2. CRITICAL: ollama defaults num_ctx to 4K on <24GB-VRAM devices --
   CPU-only sophon hits this trap. Set num_ctx explicitly: 131072
   first, test 262144. Verify with `ollama ps` (CONTEXT column).
3. Optional: OLLAMA_KV_CACHE_TYPE=q8_0 (halves KV; global env).
   Default f16 is fine given headroom.
4. Measure on sophon: decode t/s, prefill t/s @ 1K/8K/32K/128K; vision
   smoke test (i.ar page screenshot vs gemma3:4b baseline); tool-call
   + structured output; think-toggle behavior.
5. Fallback trigger: empty generations, tool-call drift, or vision
   failures -> swap to qwen3-vl:30b-a3b (same envelope, mature arch).
6. gemma3:4b retired from VRAM after cutover (3.9GB back to Frigate).

## Architecture notes carried from the session

- Latency design (agreed): organs are a PATROL, not a call. Organs run
  on timers, write state; citizens poll state; nothing waits on the
  local model synchronously. Eye-check during builds = file request +
  poll, tighten cadence to 5min during active builds. Interactive
  sessions read reports, never invoke the model.
- Affect mappings (fear/rage/boredom) stay computable -- no model there
  (architecture sec 9). The model brain serves judgment organs
  (appetite, disgust, build item 5) + eye + ear-future + offline citizen.
- Rent rule applies to the shared brain too: it must beat the tiny
  incumbents on organ benchmarks or the upgrade reverts.
- Composition discipline: never change two things and call it a
  comparison. New organs born on the shared brain; eye upgrade second
  (known baseline exists); oracle third.

## Sources

- ollama.com library pages + tags (sizes, badges, quants) -- fetched
  2026-09-08.
- HF configs: Qwen/Qwen3.6-35B-A3B, Qwen/Qwen3-VL-30B-A3B-Instruct,
  Qwen/Qwen3.8-27B, google/gemma-4-26b-a4b-it (KV math from
  layers/kv_heads/head_dim; qwen3.6 hybrid layout from model card).
- Qwen3.6 README: benchmarks (MMMU 81.7, RefCOCO 92.0, SWE-bench 70.0),
  context 262,144 native / 1,010,000 extensible.
- llama.cpp issues #27442 (hybrid empty-gen, Metal-only, CPU cleared by
  maintainers), #26425 (MTP state), #24670 (draft-mtp).
- ollama issues #15650 (memory calc), #16398 (tool-call drift), #17871
  (think+json), #16216 (qwen3.6 vision works, edge-case empty content).
- HN rig reports (2026-04..09): CPU speed datapoints cited above.
- [EXTERNAL DATA] all web-sourced numbers; KV math computed locally
  from primary configs.