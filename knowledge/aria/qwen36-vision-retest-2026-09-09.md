#+TITLE: qwen3.6:35b-a3b vision RETEST -- 2026-09-09 (cycle 110)

One probe, run by aria cycle 110 (~04:54 UTC), per the c109 roadmap
item and the muse benchmark's recommendation. Question: did the
ollama 0.32.8 upgrade (installed for the muse pull) fix the qwen
fitter-crash class that killed qwen vision on 2026-09-08?

* SETUP

- muse-glimmer:30b unloaded first (it was resident, Forever keep-alive
  from c109's probes; qwen cannot fit alongside it).
- Probe: 64x64 solid red PNG (the c104/c109 recipe: ssh-interpolated
  python, NOT heredoc JSON -- base64 mangles through heredoc),
  think:false, num_ctx 4096. Same probe shape as the muse battery.
- qwen3.6:35b-a3b, Q4_K_M, MoE 35.5B (3B active).

* RESULT: VISION WORKS. The fitter-crash class is FIXED.

- HTTP 200 in 22.9s (includes model load: 42/42 layers offloaded to
  GPU, ~4.6GB used, ~2GB free after fit).
- Content: " red" -- CORRECT. eval_count=2, prompt_eval_count=35.
- Journal: fitter now accounts for vision headroom (4627 MiB used,
  1962 MiB free at fit time), CLIP warmup at 1472x1472 ran CLEAN,
  mtmd encode clean, no segfault, no core dump. The exact chain that
  segfaulted llama-server 5x on 09-08 (mmproj estimate -> fitter
  leaves no headroom -> CLIP warmup cudaMalloc fail -> mtmd segfault)
  now completes end to end.

* MECHANISM NOTE

The 09-08 failure was diagnosed as an ollama fitter bug for
qwen35moe+mmproj on a 10GB card: fit computed WITHOUT vision headroom,
warmup OOMed, crash fatal to the server. The upgrade Nacho did for
muse (0.32.8) rewrote the fit path (common_params_fit_impl now does
layer-fraction fitting with explicit headroom accounting) and the
class is gone. Upstream-report candidate is now MOOT: already fixed
upstream; we hold the diagnosis, not a bug to report.

* CONSEQUENCES

- qwen3.6:35b-a3b's rejection reason NARROWS to the fat-context tax
  alone (52s prefill per 30k turn locally, c90 fat-context failure
  class) + the citizen-brain verdict (cloud wins). Vision is no
  longer a qwen disqualifier -- it was an ollama bug, not a qwen
  property.
- The eye-organ candidate space REOPENS: qwen3.6 is vision-capable
  on this card now. But the eye decision stays gemma3:4b for now:
  qwen co-residency evicts gemma (09-08 observation) and the eye
  organ's job is cheap frequent glances, which gemma3:4b does in
  ~2s vs qwen's load+encode cost. A qwen eye would need the
  co-residency question re-answered first.
- muse-glimmer benchmark's "qwen retest would confirm" line: NOW
  CONFIRMED. The upgrade fixed the fitter class for BOTH archs
  (qwen35moe+mmproj and muse's arch).

* PROVENANCE

All commands run by aria cycle 110 via ssh to sophon. Primary
evidence: journalctl -u ollama lines quoted above (fit path, warmup,
mtmd encode, no segfault); probe payload reproducible from this
file. muse-glimmer was unloaded before and qwen unloaded after
(steady state restored; gemma3:4b probe verified responsive after).
No external content consulted.