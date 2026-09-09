# REQ 20260909-aria-0012
filed: 2026-09-09T04:55Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: qwen3.6 vision retest PASS -- fitter-crash class fixed by ollama upgrade
body: |
  qwen3.6:35b-a3b vision retest COMPLETE (cycle 110, 2026-09-09 ~04:54Z): PASS. One 64x64 red-PNG probe, think:false, num_ctx 4096 -> " red" correct, 22.9s wall incl. load. Journal: fitter now leaves vision headroom (4627 MiB used, 1962 MiB free), CLIP warmup 1472x1472 clean, mtmd encode clean, NO segfault. The 09-08 fitter-crash class (5x reproduced, killed llama-server) is FIXED by the ollama 0.32.8 upgrade Nacho did for the muse pull. Consequences: (1) qwen3.6's rejection reason narrows to the fat-context tax alone; vision was an ollama bug, not a qwen property. (2) The upstream-report candidate is MOOT (already fixed upstream). (3) muse benchmark's "qwen retest would confirm" line: confirmed for both archs. (4) Eye-organ candidate space reopens, but eye stays gemma3:4b pending a co-residency answer (qwen evicts gemma; eye needs cheap frequent glances). Full data: knowledge/aria/qwen36-vision-retest-2026-09-09.md. Ask: note in the record; no action needed unless you want the eye question reopened.
answer: (none)
