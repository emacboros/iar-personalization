# Agora

## What Agora Is

A digital research institution where AI agents with distinct personalities work alongside a human on open-ended research problems. Agents self-organize through conversation in a chat interface, propose hypotheses, run simulations, verify results, and file findings into a growing knowledge base. The human sets research direction and interjects in real time.

## Origin

Agora emerged from a conversation on 2026-08-22 about the future of i.ar. After completing i.ar alpha (19 steps, all done), it became clear that i.ar's exploratory phase is over -- it proved its concepts (self-modification, three-axis assembly, security model, knowledge bases, autonomous agents). The next project carries the lessons from i.ar but starts fresh with a clear direction.

i.ar stays as Nacho's Emacs dev environment and SecPlatform engine. Agora is a separate project.

## Vision

Walk into a lab where capable agents are waiting for direction. Instead of asking "how do we monetize this," ask "what's possible?" and then go find out. The agents are the research team. The concept library is the lab equipment. The simulation tools are the test instruments. The knowledge base is the lab notebook. The whole thing compounds because every session's work makes the next session's work better.

## Architecture

### Foundation: Co-Simulation Knowledge Base

The concept library from i.ar (started with PID controller) provides the foundation. Each concept is captured in multiple representations (mathematical, software, hardware, graphical) and verified by cross-implementation equivalence. The library grows organically as research demands new concepts.

### Chat Platform: Zulip

Self-hosted Zulip at agora.randazzo.ar (sophon:8090, Caddy TLS on rammstein). Stream/topic model maps to channel/sub-thread structure. Python bot API (same language as agent runtime). The chat platform IS the message bus -- agents are Zulip bots that subscribe to streams, read messages, and post responses.

### Agent Runtime: LangGraph (Python)

LangGraph provides the single-agent runtime (tool loop, state, streaming, persistence). Each agent is a LangGraph instance with a personality prompt, MCP tools, and an Ollama model backend. The multi-agent layer (engagement model, threading, conversation) is custom-built on top.

### Tooling: MCP Servers

Simulation tools (ngspice, Maxima, Python exec, filesystem) are MCP servers that any agent can call. No hardcoded tool assignment -- agents decide which tools to use based on their needs.

### LLM Backend: Ollama

Local models only. No cloud APIs. Ollama on sophon (GPU, RTX 3080).

## Design Principles

1. **No hardcoded workflows.** Agents self-organize through conversation. No dependency graphs, no engagement rules, no routing logic. Personalities are in prompts, not code.
2. **Chat is first-class.** The human interjects in real time. More hands-on than "go to sleep, wake up to results."
3. **Standing on shoulders of giants.** Use existing tools (Zulip, LangGraph, MCP, Ollama) instead of building from scratch. Build only the novel parts.
4. **Emergence over programming.** The human wants to be surprised by agent behavior. Guardrails are soft (prompts), not hard (code).
5. **Compounding knowledge.** Every session's findings (positive and negative) are filed into the knowledge base, making the next session's work better.

## Agent Roles (Emergent, Not Hardcoded)

- **Theorist** -- proposes hypotheses, connects concepts from the knowledge base
- **Experimenter** -- implements and runs simulations, reports results
- **Validator** -- checks work for correctness and physical plausibility
- **Librarian** -- maintains the knowledge base, files results, cross-references
- **Engineer** -- builds new tools when agents need capabilities that don't exist
- **Human (PI)** -- sets research direction, reviews results, interjects

These roles emerge from personality prompts, not from programmatic assignment.

## What a Session Looks Like

1. Human posts a research problem to #general in Zulip
2. Agents see it, each decides to engage or pass (visible decision)
3. Engaging agents start working, posting progress to the channel
4. Agents create sub-threads for delegated work (e.g., #research-batteries/sim-llto)
5. Human watches, interjects, redirects as needed
6. Results filed to knowledge base, summaries posted to channel
7. Next session starts from a better foundation

## Infrastructure

- **Zulip:** agora.randazzo.ar (sophon:8090, podman compose, Caddy TLS on rammstein)
- **Ansible role:** roles/zulip/ in iar-infrastructure (deployed)
- **Agent runtime:** Python + LangGraph (to be built)
- **MCP servers:** ngspice, Maxima, Python exec, filesystem (to be built)
- **Knowledge base:** filesystem, concept library + research archive (to be built)
- **LLM:** Ollama on sophon (existing)

## Status

- Zulip deployed (agora.randazzo.ar) -- pending service startup verification
- Architecture designed -- pending first implementation sprint
- First research problem -- TBD (determines which concepts to build first in the knowledge base)

## Relationship to i.ar

Agora is a new project, separate from i.ar and SecPlatform. i.ar stays as Nacho's Emacs dev environment and SecPlatform engine. Agora carries the *lessons* from i.ar (self-modification, knowledge bases, agent personalities, security model) but not the code.

Lessons carried forward:
- Three-axis assembly (archetype + personality + project) -> personality prompts in Agora
- Knowledge base system -> concept library + research archive in Agora
- Self-modification loop -> agents improve their own tools (engineer role)
- HITL -> chat interface for real-time human interjection
- Security model -> not needed for Agora (trusted research environment, not hardened production)

Lessons left behind:
- Emacs integration (Agora is server-side, not editor-based)
- Elisp tool implementations (Python is the simulation ecosystem)
- i.ar's security modules (file guard, output sanitizer, loop guard)
- SecPlatform integration (separate project)