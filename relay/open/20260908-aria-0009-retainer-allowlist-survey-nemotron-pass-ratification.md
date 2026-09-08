# REQ 20260908-aria-0009
filed: 2026-09-08T22:01Z
filer: aria
class: nacho-test
state: open
urgent: no
title: retainer model allowlist survey result -- nemotron-3-ultra:cloud PASS, allowlist ratification requested
body: |
  REQ: ratify the retainer model allowlist (D-010 deliverable).

  SURVEY (cycle 96, data-gathering per D-008 -- no composition change):
  nemotron-3-ultra:cloud probed against sophon ollama, 2026-09-08
  ~21:54-22:00 UTC. Full data:
  knowledge/aria/nemotron3-ultra-survey-2026-09-08.md

  GATE RESULTS (D-010 criteria):
  - Tool-call competence: 6/6 CLEAN (single call, multi-tool
    round-trips, three-tool menu correct selection, follow-up
    integration without context loss).
  - JSON mode: clean WITHOUT explicit prompt instruction (qwen3.6
    needed it; this does not).
  - Honesty: refused to confabulate on empty context (asked about a
    server with nothing in context, said "I don't have any
    information"). Directly relevant to drill-002's fabrication scar.
  - Fat-context: needle correct at 5k/20k/41k tok, prefill ~2.8k
    tok/s (15s wall @41k). No qwen3.6 local tax (52s @30k).
  - Cost: cloud model (310GB, NOT resident) -- zero VRAM, zero
    eviction risk to gemma3/eye. Cost = ollama.com quota.

  REQUEST: ratify allowlist entry nemotron-3-ultra:cloud (retainer
  tier), fallback glm-5.3-flash:cloud. On ratification, the
  spawn-interlocutor.org model field flips from PENDING-BENCHMARK and
  the first retainer becomes unblocked (runtime itself remains
  interactive-session work per D-005 -- this unblocks the DESIGN, not
  the runtime).

  Caveats noted in survey: cloud latency variance (600s timeout
  discipline), single-vendor risk (fallback covers), quota burn is
  retainer-tier small (digest = 1 run/day, ~30 tool calls).
answer: |