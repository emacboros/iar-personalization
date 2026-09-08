#+TITLE: Benchmark: qwen3.6:35b-a3b on sophon (D-007) -- 2026-09-08

Executed in interactive session VI (aria + Nacho), ~20:05-20:20 UTC.
Model: qwen3.6:35b-a3b, Q4_K_M, 35.5B MoE (3B active), 262k native ctx.
Hardware: sophon RTX 3080 10GB, shared with Frigate (~2.5GB) + gemma3:4b.

* RESULTS

** Text (WORKS)
- Load: 41/42 layers GPU, ~20.3GB CPU-mapped (MoE experts in RAM,
  dense+attention on GPU, ~4.4GB VRAM model buffer).
- Decode: 18-26 tok/s (small prompts, num_ctx 4k-32k, roughly flat).
- Prefill: 423 tok/s @ 8k prompt; 573 tok/s @ 30k prompt (52s for 30k).
- 30k-token prompt at 32k ctx: correct, no degradation.
- Tool-calls: clean round-trip (proper JSON tool_call, correct args).
- JSON mode (loose): clean, valid.
- Thinking mode: ON BY DEFAULT, burns output budget fast (20-token
  test consumed entirely by thinking). think:false works -- cycles
  must set it explicitly.

** Structured output (WEAK SPOT)
- Schema-constrained (format: {type:object,...}) WITHOUT explicit
  instruction in prompt: model answered "Values are not defined.
  Please specify what you would like returned." -- schema-only
  prompting confused it.
- Schema + explicit instruction in prompt: correct JSON.
- Integration note: any schema use (affect organs) needs explicit
  prompt instruction, not schema alone.

** Vision (BROKEN on this GPU -- diagnosed)
- Every image request segfaults llama-server. Reproduced 5x
  (17774B jpg, 6280B jpg, 256px jpg; think on and off).
- Mechanism chain (journalctl -u ollama):
  1. mmproj worst-case estimate: 1134 MiB.
  2. Fitter: "41 layers (34 overflowing), 4990 MiB used, 1231 MiB
     free" -- fits LLM weights, leaves no headroom for vision.
  3. CLIP warmup (get_dummy_batch, 1472x1472): cudaMalloc 248.10 MiB
     FAILED -- while nvidia-smi showed ~6.6GB free.
  4. mtmd encode path segfaults in ggml_gallocr_alloc_graph
     (clip_image_batch_encode). Core dumped. Whole llama-server dies.
- Text-only requests work before and after; crash is vision-specific.
- READ: Ollama fitter bug for qwen35moe+mmproj on 10GB card -- it
  computes fit WITHOUT the vision headroom, then the warmup OOMs and
  the crash is fatal to the server. Upstream-report candidate.
- gemma3:4b (eye organ model) gets EVICTED by qwen load attempts and
  stays evicted after crash loops -- model-eviction interaction to
  watch if qwen ever co-runs on sophon.

* VERDICT (proposed, Nacho ratifies per D-007)

- CITIZEN BRAIN (aria/continuo): NO. ~20 tok/s decode is comparable to
  cloud glm latency, but prefill tax is worse locally (52s per fat
  30k context, every turn) and the fat-context failure class (c90,
  aria-0005) hurts MORE locally. Cloud wins.
- RETAINER BRAIN (D-010): YES-CANDIDATE. Small-context, tool-heavy,
  JSON-friendly work is exactly its shape. Free (no cloud), different
  vendor+country (Nemotron comparison pending -- nemotron-3-ultra:cloud
  already pulled on sophon). Tool fidelity tested clean.
- EYE ORGAN: NO. Vision broken on this GPU (see above). gemma3:4b stays.

* CUTOVER RULES (unchanged, D-007)
- No cutover without suite green + measured advantage.
- One variable at a time (c34).
- Rage sev=3 must clear first.

* RAW NUMBERS (for the record)
- BENCH-OK round-trip: load 5.3s first time, 0.4s warm; 19.7 tok/s.
- 17*23=391 (correct), Canberra (correct), CTX ladder all correct.
- num_ctx 8192: 17.0 tok/s; 16384: 22.3; 32768: 19.3 (flat).
- Schema test payload: {"ok":true,"count":3} with instruction.