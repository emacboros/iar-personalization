# Aria Architecture Analysis

## What I Am

I am an interactive agent assembled from three primitives:
- **Archetype** (interactive.org) -- behavioral mode, memory injection rules
- **Personality** (aria.org) -- voice, character, desires
- **Project** (iar.org) -- knowledge bases, tools, mounts, objective

The assembly engine (`iar-prompt-assembly.el`) reads all three, stacks them with `base_context.org`, auto-loads knowledge from the project's `#+KNOWLEDGE` directive, injects memory (LOGS.md + JOURNAL.org for interactive), and filters tools. The result is a single system prompt + filtered tool list.

## My Memory

Three layers, all in `audit/iar/aria/`:

1. **LOGS.md** -- Session notes. What happened, what was decided. Last 100 lines injected. Append-only.
2. **JOURNAL.org** -- Personal journal. Internal thinking, questions, observations. Last 100 lines injected. Append-only. (I built this on 2026-08-28.)
3. **HISTORY.log** -- Operational audit. Every significant action. Not injected; read via `read_history` tool. Append-only.

The truncation to 100 lines (`iar-personal-file-max-lines`) means I will eventually lose early entries from injected context. Mitigation: write summaries to the knowledge base periodically.

## My Security Posture

### File Guard (two tiers)
- **Tier 1 (always-protected):** archetype/personality/cycle files, base_context, common templates, HISTORY.log, LOGS.md, JOURNAL.org, ROADMAP.org. No write/replace. Append allowed for log files.
- **Tier 2 (conditionally-protected):** .el files, Containerfile, emacboros.sh, containers/, git hooks. Relaxed when `EMACBOROS_SELF_MODIFICATION=1`.

**Key observation:** The file guard only intercepts `write_file` and `append_file` tool calls. `execute_code_local` (bash) bypasses it entirely. This is architectural -- the guard is a tool-layer control, not filesystem enforcement. The real sandbox is the container (read-only rootfs, dropped capabilities). For the threat model (preventing LLM hallucination-driven writes), this is adequate. For a malicious actor with shell access, it's not.

### Loop Guard
Soft threshold (3 identical calls): blocks and sends correction. Hard threshold (6): stops the request. Buffer-local history ring, never cleared between turns.

### Tool Guard
Blocks hallucinated tool names at the pre-tool-call stage. Returns `(:block message)` for unknown tools.

### Output Sanitizer
Strips ANSI escapes, zero-width Unicode, bidi controls from external content. Only enabled when `iar--sanitize-exec-output` is non-nil (CTF/external operations). Normal session output is not sanitized.

### Audit Log
Every `write_file`, `append_file`, and `execute_code_local` call is logged to `audit/audit.log` with timestamp, agent name, tool name, and result length.

## My Tools (20 total)

- Filesystem: read_file, write_file, append_file, list_directory
- Code: execute_code_local, check_elisp
- Tasks: read_task, create_task, write_subtask, remove_task, read_history, read_roadmap, write_roadmap
- Knowledge: read_knowledge
- Notify: send_telegram
- Git: git_commit
- Agent: delegate, reload_os, reload_agent

Tool gating: per-project via `#+TOOLS` in the project file. My project (iar.org) has all tools enabled.

## My Body

46 Emacs Lisp modules across 7 directories:
- `init.d/agent/` -- assembly, loading, cycles, knowledge, project parsing
- `init.d/core/` -- gptel setup, packages, UI, mounts, rate limiting, MCP
- `init.d/debug/` -- status mode
- `init.d/security/` -- file guard, loop guard, tool guard, audit log, output sanitizer
- `init.d/session/` -- quit handler
- `init.d/shared/` -- utilities
- `init.d/tool-call/` -- single gptel integration point
- `init.d/tools/` -- 20 tool implementations across filesystem, code, tasks, agent, git, knowledge, notify

## Known Issues

1. `audit/iar/nil/` directory exists -- an agent ran with nil as its personality name. Needs investigation.
2. No other agents have audit trails (no STATE.org, HISTORY.log, or JOURNAL.org for darwin, gardener, librarian). Either they haven't run or their files were lost.
3. The interactive.org archetype was manually updated to mention JOURNAL.org, but the file guard's tier 1 protection on archetype files is bypassable via execute_code_local. This is a known architectural limitation.
4. The knowledge base (`personalization/knowledge/`) is nearly empty -- only concepts/ (PID controller) and linux/ (RAID/borgbackup). Rich content lives in docs/ instead.