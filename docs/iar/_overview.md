# i.ar Overview

## What i.ar Is

Self-modifying AI operating environment in Emacs, running in a hardened Podman container, powered by local LLMs via Ollama. No cloud, no telemetry. Repo at `/root/i.ar/`, Emacs config at `/root/i.ar/emacs.d/` (bind-mounted to `/root/.emacs.d/`).

## Three-Axis Assembly

Every agent is assembled from three independent primitives:

1. **Archetype** (`prompts/archetypes/<name>.org`) -- behavioral mode (interactive, autonomous, continuous, delegated, one-shot). Has `#+MODE:` metadata. Determines memory injection and completion semantics.
2. **Personality** (`prompts/personalities/<name>.org`) -- voice/character. Pure character, no tools or knowledge.
3. **Project** (`personalization/projects/<name>.org`) -- knowledge (`#+KNOWLEDGE`), tools (`#+TOOLS`), containers (`#+CONTAINERS`), mounts (`#+MOUNTS`), objective (`#+OBJECTIVE`).

Assembly engine (`iar-prompt-assembly.el`) combines: base_context.org -> archetype -> personality -> project objective -> auto-loaded knowledge -> memory injection -> mount info -> containers -> MCP servers.

## Pointers

- **Archetypes + personalities + memory injection**: agents.md (full tables: mode, memory, completion, per-personality mapping).
- **Tools**: tools.md (per-tool reference). Gating is per-project via `#+TOOLS`; `#+CONTAINERS` auto-includes `execute_code_remote`.
- **Modules**: modules.md (full per-module table: assembly engine, loaders, tool-call layer, security modules, configs/, shared/).
- **Memory system**: LOGS.md (interactive, last N lines, `iar-personal-file-max-lines` default 200), STATE.org (autonomous/continuous, full), HISTORY.log (via read_history). Files in `audit/<project>/<personality>/`.
- **Security model**: architecture.md + philosophy.md. Six layers: container hardening (read-only rootfs, dropped caps), file guard (tier 1 prompt files always protected; tier 2 .el relaxed with --self-modification), per-project tool gating, multi-container separation (sidecars), loop guard (soft/hard thresholds), audit logging.
- **Cycle agents** (aria/continuo): run via aria-cycle.service + rotate.sh on sophon, 10-min rotation. The darwin/gardener/librarian autonomous loops were removed 2026-09-07 (never deployed; graveyard doc has the why).
- **Delegation**: agents.md + tools.md. delegate -> agent-assistant plans -> implementer/reviewer, depth-limited (default 3), turn-limited (default 15), timeout 600s.

## Documentation Structure

Full docs in `docs/iar/`: agents.md, architecture.md, modules.md, philosophy.md, tools.md, tool_gating.md, usage.md, workflow.md, future_ideas.md. Use read_file for details.

## Maintenance Rule

When code changes, update the corresponding docs/iar/ file. The knowledge base IS the documentation. See workflow.md for the update mapping table.