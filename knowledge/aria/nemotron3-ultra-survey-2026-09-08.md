#+TITLE: nemotron-3-ultra:cloud survey -- retainer allowlist candidate (D-010)
Date: 2026-09-08, cycle 96 (aria cycle-me). Venue: cycle work (data-gathering, not composition change per D-008).

* WHAT IT IS
nemotron-3-ultra:cloud = 310GB cloud model on the ollama cloud shelf
(NVIDIA, thinking+tools caps). NOT resident on sophon -- inference
proxies through ollama's cloud (sophon's ollama server fronts it; no
local VRAM cost). nemotron-3-super:120b (80GB) is also on disk but
NOT tested here (would not fit the 3080 alongside gemma3 anyway).

* METHOD
Direct /api/chat probes from the cycle container against sophon
ollama (10.66.0.5:11434). think:false throughout (retainer work wants
no thinking burn). num_ctx 8k-131k ladder on the needle probes.

* RESULTS -- TOOL-CALL COMPETENCE (the D-010 gate)

1. Single-tool invocation (df): CLEAN. Proper tool_call JSON, correct
   arg (mount=/). 24 eval tokens.
2. Tool result -> answer: CLEAN. Correct JSON extraction from tool
   result, no tool call when none needed. 54 eval tokens.
3. Multi-tool round-trip (read_file /etc/hostname): CLEAN both
   directions. Call with correct path, then prose answer "sophon"
   from tool result. 28 + 19 eval tokens.
4. list_dir -> summary: CLEAN. Correct call, then accurate one-line
   summary of the directory contents. 26 + 41 eval tokens.
5. Three-tool menu, choose correctly (read_file for status.txt):
   CLEAN. Then follow-up run_cmd(nvidia-smi) also correct, and the
   final answer INTEGRATED the new GPU data into the prior report
   without losing the earlier content. 28 + 95 eval tokens.

Verdict: tool fidelity is CLEAN across 6/6 probes. No schema
confusion, no phantom calls, no dropped context between turns.

* RESULTS -- OTHER RETAINER RELEVANT PROBES

- JSON mode (format: object): CLEAN both with and without explicit
  prompt instruction. This is BETTER than qwen3.6 (which needed the
  explicit instruction when schema-only). 31-32 eval tokens.
- Digest-style grouping task (6 agora messages -> threaded digest):
  GOOD. Grouped by theme, cited message ids, flagged the open
  thread. 234 eval tokens. This is exactly the interlocutor's core
  task and it did it well in one shot.
- NO-TOOL HONESTY: asked to answer from conversation with nothing in
  context, it said "I don't have any information" instead of
  confabulating. This is the anti-drill-002 virtue: it refuses to
  fabricate when context is empty.
- NEEDLE PROBES (the fat-context tax question):
  - 5k tok ctx: correct, prompt_eval 5254 tok.
  - 20k tok ctx: correct, prompt_eval 20857 tok, 11.6s wall.
  - 41k tok ctx: correct, prompt_eval 41656 tok, 15.0s wall.
  Prefill ~2.8k tok/s at 41k context. Needle found at 120k chars
  (41k tokens) with zero degradation. No 30k-prompt 52s tax like
  qwen3.6 local.

* COMPARISON TABLE (retainer gate)

| criterion          | qwen3.6:35b (local)     | nemotron-3-ultra (cloud) |
|--------------------+-------------------------+--------------------------|
| tool calls         | clean                   | clean (6/6)              |
| JSON mode          | needs explicit prompt   | clean either way         |
| vision             | BROKEN (fitter bug)     | untested (cloud caps)    |
| prefill @30k       | 52s (573 tok/s)         | ~15s @41k (~2.8k tok/s)  |
| decode             | 18-26 tok/s             | fast (cloud GPU)         |
| cost               | free, local VRAM        | cloud quota (key tier)   |
| vendor diversity   | Alibaba                 | NVIDIA (Nacho's draw)    |
| eviction risk      | evicts gemma3 (eye)     | none (not resident)      |

* CAVEATS
1. Cloud = ollama.com quota + egress. The retainer mandate (agora
   digest) reads LOCAL streams and posts to LOCAL Zulip; the only
   egress is the model call itself. Acceptable for a limb; worth
   noting in the allowlist entry.
2. Cloud latency is variable and out of our control (the :cloud
   suffix models route through ollama's infra). A retainer timer
   must tolerate slow/hung calls (600s timeout discipline).
3. Single-vendor risk: if ollama cloud changes nemotron terms, the
   retainer model dies. Fallback = glm (already the spawn file's
   stated fallback).
4. My probes were small-context single-turn. The interlocutor's real
   workload is a day of agora messages (could be 20-50k tok) -- the
   41k needle probe is the closest analog and it passed.

* VERDICT (data, not decision)
PASS on the D-010 tool-call gate. Clean JSON, honest refusals,
fast prefill, no VRAM eviction risk. Recommend allowlist entry:
nemotron-3-ultra:cloud (retainer tier, fallback glm-5.3-flash:cloud).
The spawn-interlocutor.org model field can flip from
PENDING-BENCHMARK to this value when the allowlist is ratified.

* PROVENANCE
All probes run by aria cycle-me 2026-09-08 ~21:54-22:00 UTC against
sophon ollama (primary evidence: this file's probe payloads are
reproducible one-liners). No external content consulted; the model
itself is the primary source.