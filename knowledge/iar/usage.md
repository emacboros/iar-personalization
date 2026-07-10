# i.ar Usage Guide

## Quickstart

### Prerequisites
- Podman (container runtime)
- Emacs 28+ (for local development without container)
- Ollama running on a reachable host (local or WireGuard mesh)
- A personalization repository (see below)

### Clone

```bash
# Just want to use the tool:
git clone https://github.com/randazzo-ignacio/i.ar.git

# Want to work on i.ar or understand the codebase (includes personalization submodule):
git clone --recursive https://github.com/randazzo-ignacio/i.ar.git
```

The personalization submodule at `personalization/` contains knowledge bases, per-agent tasks, and audit logs. Users should fork or create their own personalization repo with their own knowledge, tasks, and agent configurations.

### Build the Container

```bash
cd i.ar
./containers/build.sh
```

### Run

```bash
# Basic usage (connects to remote Ollama via WireGuard):
./utils/emacboros.sh --personalization ~/repos/iar-personalization

# With self-modification enabled (for development/darwin):
./utils/emacboros.sh --personalization ~/repos/iar-personalization --self-modification

# With local Ollama and self-modification:
./utils/emacboros.sh --personalization ~/repos/iar-personalization --local --self-modification

# Mount additional directories into the container:
./utils/emacboros.sh --personalization ~/repos/iar-personalization \
  --mount /home/user/projects/myapp \
  --mount-ro /etc/ansible
```

### Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--personalization PATH` | Yes | Mounts knowledge/, tasks/, audit/ subdirectories into container |
| `--ollama-host HOST:PORT` | No | Override Ollama backend (default: from env or WireGuard IP) |
| `--self-modification` | No | Enables tier 2 file guard relaxation for .el file edits |
| `--local` | No | Use localhost Ollama instead of remote |
| `--mount PATH` | No | Mount additional writable directory into container |
| `--mount-ro PATH` | No | Mount additional read-only directory into container |

## Inside Emacs

### Keybindings

| Key | Command | Description |
|-----|---------|-------------|
| C-c a | `my-gptel-load-agent` | Load agent personality (mirror, darwin, auditor, etc.) |
| C-c k | `my-gptel-load-knowledge` | Load a knowledge base directory (iar/, user/, infra/, etc.) |
| C-c p | `my-gptel-prompt-info` | Show prompt size (chars + approximate tokens) |
| C-c m | `my-gptel-memory-summarize` | Summarize conversation to LOGS.md/SUMMARY.md |

### Typical Workflow

1. Start the container with `emacboros.sh --personalization ...`
2. Emacs opens with gptel-mode active
3. Load an agent: `C-c a mirror` (or darwin, auditor, ctfwizard)
4. Load knowledge: `C-c k iar/` (project docs), `C-c k user/` (your identity), `C-c k infra/` (infrastructure)
5. Check prompt size: `C-c p` (monitor context window usage)
6. Converse with the agent. It uses tools (read_file, execute_code_local, delegate, etc.) as needed.
7. When done: `C-c m` to summarize the session to memory.

### Talking to Mirror

The mirror agent is your thinking partner. Load `knowledge/iar/` into it and ask it about the codebase, design decisions, or to review a change you're planning. The mirror challenges your assumptions, pushes back on scope, and helps you think through problems.

### Running Darwin (Autonomous Mode)

Darwin runs in cycles without human direction. Use the shell scripts:

```bash
# Run a single cycle:
./utils/darwin-cycle.sh --personalization ~/repos/iar-personalization --self-modification

# Run a loop (continuous cycles with cooldown):
./utils/darwin-loop.sh --personalization ~/repos/iar-personalization --self-modification
```

Darwin reads its own memories, picks one thing to improve, makes the change, delegates to reviewer for code review, runs tests, commits, logs, and sleeps. One mutation per cycle.

## Setting Up Your Personalization Repo

The personalization repo has three subdirectories:

```
my-personalization/
  knowledge/         -- Your knowledge bases (injectable via C-c k)
    user/            -- Your identity, bio, domains, stack
    iar/             -- i.ar self-documentation (from submodule or fork)
    infra/           -- Your infrastructure docs
    linux/           -- Linux administration knowledge
  tasks/<agent>/     -- Per-agent files: TODO.md, IDEAS.md, LOGS.md, SUMMARY.md
  audit/<agent>/     -- Per-agent HISTORY.log files
  audit/audit.log    -- Global audit log
```

1. Create the three subdirectories
2. Add knowledge bases you want agents to access
3. Create task/audit subdirectories for each agent you use
4. Point `--personalization` at your repo when running emacboros.sh

You can use the iar-personalization repo as a starting point and customize it.