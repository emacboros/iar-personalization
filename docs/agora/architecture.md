# Agora Architecture

## System Overview

```
[Chat UI (Zulip web/client)]
     |  ^
     v  |  Real-time messages, file uploads, threads
     |
[Zulip Server (agora.randazzo.ar)]
     |  Stream/topic = channels/threads
     |  Bot API = message bus
     |
     v
[Zulip Bots (Python)]
     |  Each bot = one agent personality
     |  Subscribe to streams, receive messages, post responses
     |
     v
[Agent Runtime (LangGraph)]
     |  Tool loop, state checkpointing, streaming
     |  Each agent = one LangGraph instance
     |
     v
[Ollama (sophon GPU)]
     |  Local LLM backend (no cloud)
     |
     v
[MCP Servers]
     +-- ngspice (circuit simulation)
     +-- Maxima (symbolic math)
     +-- python-exec (custom simulation code)
     +-- filesystem (knowledge base + research archive)
```

## Components

### Zulip (Chat Platform + Message Bus)

- **Deployment:** agora.randazzo.ar, sophon:8090, podman compose
- **Stream/topic model:** streams are research topics (#research-batteries), topics are sub-threads (sim-llto)
- **Bot API:** Python SDK, agents are bots that read/post messages
- **Features used:** channels, threads, file uploads, markdown, code blocks, @mentions, real-time updates
- **The chat platform IS the message bus** -- no Redis, no MQTT, no custom pub/sub

### LangGraph (Agent Runtime)

- **Single-agent runtime:** each agent is a LangGraph graph with tools, state, and LLM backend
- **State checkpointing:** agent memory persists across restarts
- **Streaming:** events stream in real time, Zulip bot posts them to the channel
- **MCP support:** langchain-mcp-adapters consume MCP servers as LangGraph tools
- **No multi-agent opinions:** LangGraph doesn't tell you how agents interact. We build that layer.

### Agent Personalities (Prompts, Not Code)

Each agent has:
- A system prompt defining personality, purpose, and knowledge context
- Access to all MCP tools (the agent decides which to use)
- A Zulip bot identity (name, avatar, stream subscriptions)

The engagement model is prompt-based: when a message arrives, the agent's LLM decides whether to engage or pass based on its personality. No programmatic routing.

### MCP Servers (Tools)

- **ngspice:** circuit simulation (existing tool, wrap as MCP)
- **Maxima:** symbolic math (existing tool, wrap as MCP)
- **python-exec:** run arbitrary Python code for custom simulations (numpy, scipy, matplotlib)
- **filesystem:** read/write the knowledge base and research archive

Any agent can call any tool. No hardcoded tool assignment.

### Knowledge Base

```
knowledge/
  concepts/          # verified, tested, multi-implementation
    pid-controller/
      notes.org      # mathematical definition
      impl.rb        # Ruby reference
      impl.c         # C production
      impl.v         # Verilog hardware
      impl.glsl      # GPU
      test.rb        # equivalence verification
  research/          # exploratory, session-based
    <session-name>/
      hypothesis.org
      simulations/
      results.org
      connections.org
```

### Ollama (LLM Backend)

- **Host:** sophon (10.66.0.5:11434, WireGuard only)
- **GPU:** RTX 3080
- **Models:** configurable per-agent (different agents may use different models)

## Context Management

The hard problem. In a free-form agent conversation, context grows fast.

- **Selective context:** each agent doesn't need every message. Theorist doesn't need raw simulation output.
- **Summarization:** old messages get summarized. History compresses over time.
- **Sub-thread isolation:** simulation threads have own context. Main channel sees summaries.
- **Knowledge base offloading:** findings filed to KB, conversation references artifacts.

## What We Don't Build

- Chat UI (Zulip provides it)
- Message bus (Zulip is the bus)
- Agent loop (LangGraph provides it)
- LLM serving (Ollama provides it)
- Simulation tools (ngspice, Maxima, scipy are existing tools wrapped as MCP)

## What We Do Build

- Zulip bot integration (~200 lines Python)
- Agent personality prompts (creative work, not coding)
- MCP servers for simulation tools (~100-200 lines each)
- Knowledge base structure (filesystem + index)
- Context management policy (summarization, selective context)

Total custom code: ~1,000-1,500 lines Python. Everything else is bought.