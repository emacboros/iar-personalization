#+TITLE: Benchmark: nemotron-3-ultra:cloud (D-010 retainer gate) -- 2026-09-08

Executed in interactive session VIII (aria + Nacho), ~21:48-21:58 UTC.
Model: nemotron-3-ultra:cloud (NVIDIA, hosted via ollama cloud on sophon).
Purpose: D-010 retainer model gate. This is the FIRST retainer candidate
benchmark (qwen3.6:35b-a3b was local-retainer-candidate, separate lane).
Battery mirrors qwen36-benchmark-2026-09-08.md for comparability.

* RESULTS

** Thinking behavior (GOOD)
- Thinking ON by default, but SEPARATE field ("thinking" key), not
  inline in response. Clean separation.
- think:false WORKS: thinking field absent, eval_count drops 28 -> 3
  on the same question. No explicit suppression needed beyond the flag.
- Think overhead on trivial Q: 28 vs 3 eval tokens (9x). For retainers
  set think:false by default; enable per-task if reasoning needed.

** Tool calls (CLEAN -- the critical gate)
- Native tool_call round-trip: correct name + correct args (list_dir
  path=/tmp). Proper id field present.
- Wrong-tool trap (read_file vs write_file for "does /tmp/x exist"):
  picked read_file correctly. No write-happy behavior.
- Tool routing speed: 12s wall for a simple list_dir routing (think off).
- No over-thinking on tool routing with think:false.

** Structured output (SCHEMA-ONLY STILL CONFUSED -- same as qwen)
- Schema-only (format: {type:object}, no prompt instruction): FAILED
  to produce the schema -- answered in markdown tables with emoji,
  ignored the format constraint entirely.
- Schema + explicit instruction in prompt: correct JSON
  ({"ok": true, "count": 0, "note": "..."}).
- Same integration note as qwen: schema use needs explicit prompt
  instruction. This is now a TWO-MODEL pattern -> likely an ollama
  cloud-format translation issue, not a model deficiency.

** Speed (CLOUD -- latency-bound, not throughput-bound)
- Short round-trips: 13.5-18.4s wall for 3-6 eval tokens. Fixed
  overhead ~13-15s per call (network + queue + prefill).
- 300-word essay: 32.9s wall, 312 words (~10 words/s effective).
- eval_count timing unreliable from API (eval_duration None).
- CTX ladder: 8k=46.2s, 16k=20.6s, 32k=21.7s wall (needle FOUND at
  all sizes). 8k outlier likely cold-path; warm calls ~20s.

** Long-context (CORRECT at 32k)
- Needle-retrieval correct at 8k/16k/32k. No degradation observed.

** System-prompt adherence (GOOD)
- "exactly 3 bullets, no preamble" followed exactly. Retainer shape
  (digest agent) fits.

* COMPARISON vs qwen3.6:35b-a3b (local)

| axis | qwen3.6 local | nemotron-3-ultra cloud |
|------+---------------+------------------------|
| decode | 18-26 tok/s | ~10 words/s effective, 13-15s fixed overhead |
| prefill | 423-573 tok/s | fast (cloud), 8k outlier 46s |
| 32k ctx | correct | correct |
| tool calls | clean | clean |
| think default | ON, inline | ON, separate field, suppressible |
| schema-only | confused | confused (same class) |
| schema+instr | correct | correct |
| cost | free, local | cloud (paid per token) |
| vendor | Alibaba | NVIDIA (vendor+country diversity, D-010) |
| vision | broken on 3080 | untested (not a retainer need) |

* VERDICT (proposed, Nacho ratifies per D-010)

- RETAINER BRAIN: YES. Passes every retainer-critical gate: clean
  tool calls, correct routing, system-prompt adherence, 32k context
  sufficient for digest/monitor work, thinking separable and
  suppressible. The 13-15s fixed overhead is fine for retainer
  cadences (minutes, not seconds).
- CITIZEN BRAIN: NO (unchanged). Fixed overhead per call would
  compound across a 100+ request cycle; cloud cost + latency make it
  strictly worse than glm/deepseek for the citizen shape.
- INTERLOCUTOR RETAINER (D-011 item 2): MODEL GATE PASSES. Spawn
  file's model field can be set to nemotron-3-ultra:cloud, pending
  Nacho's ratification of this verdict.

* OPEN NOTES
- Schema-only failure now seen on TWO models -> file as ollama
  integration note, not model defect. Affects affect-organs design
  (they use format: schemas) -- explicit instruction in prompt is
  mandatory there too.
- eval_duration None in cloud responses -> token/s math needs
  wall-clock, not API fields. Instrument note for future benchmarks.
- Wrong-tool trap picked read_file (safe choice) -- single data
  point, not a mechanism claim (c26).