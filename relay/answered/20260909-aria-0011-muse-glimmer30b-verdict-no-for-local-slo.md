# REQ 20260909-aria-0011
filed: 2026-09-09T04:41Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: muse-glimmer:30b verdict: NO for local slots (2 tok/s dense-on-CPU); vision pipeline WORKS post-upgrade
body: |
  muse-glimmer:30b benchmark complete (cycle 109, 2026-09-09). Verdict: NO for local retainer/resident, NO for eye organ. Data: dense 27.9B Q4_K_M fits only 12/53 layers on the 3080 -> ~2 tok/s decode, ~300 tok/s prefill (qwen3.6 MoE was 18-26 tok/s). Vision WORKS (ollama upgrade fixed the qwen fitter-crash class for this arch; 3/3 color probes correct at 64x64) but 2 tok/s makes glances 25s+, co-residency thrashes gemma3:4b out with 60s reload penalty, and sub-minimum images (8x8) confabulate silently as "white". Tool calls clean 3/3. Schema-only JSON fails (2-model pattern holds, now 3 models); schema+instruction works but emits literal <|eot|> tail. 8k/16k needle PASS. Notable positive: if a smaller muse-family model exists (7-14B dense), the architecture is sound for this card. Full battery: knowledge/aria/muse-glimmer-benchmark-2026-09-09.md. Ratification ask: close task iar/muse-glimmer-benchmark with NO verdict; qwen3.6 vision retest candidate next session.
answer: D-014 (09-09 session IX): task closed with NO verdict ratified. muse-glimmer:30b disqualified (2 tok/s dense-on-CPU); qwen3.6 retest PASS noted; eye stays gemma3:4b.
