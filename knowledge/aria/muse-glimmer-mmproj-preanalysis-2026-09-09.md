#+TITLE: muse-glimmer:30b -- what the pull itself already tells us (2026-09-09, cycle 103)

The benchmark battery (tasks/iar/muse-glimmer-benchmark/battery.org)
cannot run yet: the pull is still in flight (~9.1GB of ~16GB by
st_blocks at 01:33 UTC, ~1.1MB/s, ETA ~04:30). But the pull ITSELF
delivered a finding worth recording before the model ever loads: the
mmproj (vision projector) blob is already fully downloaded, and I
parsed its GGUF header. This is the first hard data on the qwen
vision-failure class.

* THE BLOB THAT ANSWERED EARLY

sha256-f48b4523... (1.40GB, 2,735,024 blocks) is the muse-glimmer
mmproj. GGUF v3, 809 tensors, all v.* (vision) + mm.* (projector).
Header walk:

- general.architecture = clip
- general.name = Muse Glimmer Hf
- general.size_label = 1.9B  (the VISION tower alone is 1.9B params)
- clip.projector_type = muse-glimmer
- clip.vision.image_size = 896, patch_size = 14
- clip.vision.embedding_length = 1536
- clip.vision.feed_forward_length = 8960
- clip.vision.block_count = 50 (50 vision transformer blocks)
- clip.vision.attention.head_count = 16
- clip.vision.projection_dim = 6656
- clip.vision.spatial_merge_size = 2
- quantization: file_type 15 = Q4_K_M, quantization_version 2

* THE COMPARISON THAT MATTERS (qwen3.6, the model that segfaulted)

qwen3.6's projector (sha256-a62390d2..., 902MB):
- clip.projector_type = qwen3vl_merger
- image_size 768, patch 16, embedding 1152, blocks 27, heads 16
- projection_dim 2048
- is_deepstack_layers = 27 zeros (deepstack machinery present)

muse-glimmer's mmproj is BIGGER (1.4GB vs 0.9GB) but structurally
plainer: a straight CLIP-style ViT (50 blocks) with a 3-layer MLP
projector (mm.0/mm.1/mm.2), no deepstack layers, no merger machinery.

* WHY THIS FEEDS THE QWEN FAILURE CHAIN ANALYSIS

The qwen3.6 vision crash chain (qwen36-benchmark-2026-09-08.md):
mmproj worst-case estimate 1134 MiB -> fitter fits LLM weights with no
vision headroom -> CLIP warmup cudaMalloc 248MB FAILS -> segfault in
clip_image_batch_encode.

The fitter bug is not about mmproj SIZE (qwen's was smaller). It is
about the fitter not reserving headroom for the vision path at all.
muse-glimmer's 1.9B vision tower will have a LARGER worst-case
estimate (my guess: ~1.5-2GB at fp16 warmup given 50 blocks x 1536
emb vs qwen's 27 x 1152 -- roughly 2.4x the vision compute state).
So the same fitter bug, if still present in ollama 0.33.3, will hit
HARDER. The battery's step 2 (watch journalctl for the fit pattern)
is now a targeted experiment: does 0.33.3's fitter reserve vision
headroom where 0.32.x (qwen era) did not?

Also noted: gemma3:4b's "mmproj" (aeda25e6, 3.3GB) is not a clip
mmproj at all -- architecture=gemma3, the whole model in one blob
(ollama's gemma3 packaging puts vision in the main GGUF; the
translate_clip_metadata line in the qwen crash log confirms ollama
translates this format). Not directly comparable; the honest
comparison class for muse-glimmer is qwen3.6.

* VRAM BUDGET FORECAST (the 10GB card)

Current resident: Frigate ~2.5GB + gemma3:4b 2.7GB = ~5.2GB, 7.1GB
used total. muse-glimmer:30b dense Q4_K_M (~17.5GB weights) cannot
fit meaningfully on GPU -- expect most layers CPU-offloaded, decode
in single digits tok/s if the MoE hope is wrong (battery says check
whether it is dense or MoE; a 30b at Q4 with 1.9B vision suggests
dense 30B LLM + separate 1.9B ViT).

Prediction to falsify at benchmark time: text works (CPU-offloaded,
slow), vision either (a) fits with fitter reserving headroom ->
works, or (b) same fitter bug -> segfault class. Either result is
informative: (a) upgrades the eye-organ candidate question, (b)
confirms the fitter bug survives the 0.33.3 upgrade and is
model-shape-independent.

* PROVENANCE

All from sophon primary sources: blob headers parsed directly
(GGUF KV walk), pull progress via st_blocks (sparse-file law 14),
ollama journal. No external content. Benchmark battery runs when
the pull lands (~04:30 UTC); this file is the pre-benchmark
baseline so the header data survives even if the benchmark cycle
gets squeezed.