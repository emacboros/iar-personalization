#+TITLE: DGX Spark benchmarks (2026-09-04 research; Spark idea DROPPED)
#+CONTEXT: Nacho's criterion -- self-hosting cycles only makes sense
if unlimited AND comparable speed to cloud. Verdict: fails. Kept for
future reconsideration ("if anything changes with hardware or
pricing I'll reconsider" -- Nacho, 2026-09-04).

* The question

Replace cloud glm-5.3-flash (~320B params, FP8, via cloud proxy on
sophon ollama) with self-hosted on DGX Spark (GB10, 128GB unified,
~$4-5k). Cycles run on flash; the burn is the weekly budget
constraint.

* Baselines measured (2026-09-04, sophon)

- gemma3:4b local (RTX 3080): 134.6 tok/s eval, 665 tok/s prompt
- gpt-oss:120b local (65GB, CPU+GPU offload on 3080): 10.9 tok/s
  eval, 4.4s prompt
- glm-5.3-flash cloud: ~100 tok/s wall (300 tok / 2.9s)

* DGX Spark official numbers [EXTERNAL DATA]

Primary source: llama.cpp maintains their own bench file --
github.com/ggml-org/llama.cpp/blob/master/benches/dgx-spark/dgx-spark.md
(build b7946, Feb 2026, CUDA, flash_attn, no mmap). tg32 = gen tok/s:

| Model | tg32 | pp2048 |
|-------|------|--------|
| gpt-oss-120b MXFP4 MoE | 58.7 | 2,444 |
| GLM-4.7-Flash (30B.A3B Q8) | 46-48 | 2,364 |
| Qwen3-Coder-30B-A3B Q8 | 61 | 2,987 |
| gpt-oss-20b MXFP4 | 83 | 4,506 |

At d32768 context, tg drops ~25% (e.g. 120b: 42.8). Batched (B=8):
gpt-oss-120b sustains 139-159 tok/s aggregate.

Secondary: geeky-gadgets million-token test (Qwen3 4B, batch):
2,451 tok/s Spark vs 1,913 Radeon 960 XT vs M3 Ultra slower.

* The extrapolation that killed it

glm-5.3-flash is DENSE ~320B. At 1-2bit quant: ~40-80GB, fits in
128GB. But dense models pay full param cost per token; the Spark's
46-61 tok/s figures are all MoE (3-5B active). Dense 320B at 1-2bit
extrapolates to ~10-20 tok/s gen -- 5-10x SLOWER than cloud flash.
A 14-min cycle becomes 1-2+ hours. "Unlimited" becomes a lower
weekly budget in practice, plus the upfront cost.

* What would change the verdict

- MoE models in the flash quality class appearing (GLM-4.7-Flash
  30B.A3B is the closest today: 46-48 tok/s -- usable but not
  glm-5.3-flash quality)
- Dense-model inference getting dramatically faster (kernel-level)
- Spark-class hardware price drop
- A cycle workload that tolerates 15 tok/s (organs/patrols only)

* Sources

- llama.cpp official bench file (primary, numbers above)
- llama.cpp discussions #16514 (setup guide), #16578 (perf thread)
- geeky-gadgets.com/million-token-speed-test/ (secondary)
