# i.ar Architecture

## What i.ar Is

i.ar is a self-modifying AI operating environment built in Emacs, running in a hardened Podman container, powered by local LLMs via Ollama. No cloud. No telemetry. No backdoors.

The project lives at `/root/i.ar/` and is a git repository. The Emacs configuration at `/root/i.ar/emacs.d/` is bind-mounted into the container at `/root/.emacs.d/`.

## Repository Layout

```
/root/i.ar/
  emacs.d/          -- Emacs configuration (bind-mounted to /root/.emacs.d)
    init.el          -- Entry point, loads all modules
    init.d/           -- Modular Emacs Lisp components (auto-discovered)
      core/           -- Locale, package setup, UI, evil mode, gptel setup
      agent/          -- Agent loader, knowledge loader, delegate, prompt loader, tools
      tools/          -- FS tools, code tools, replacement tool, check elisp
      security/       -- File guard, audit log, loop guard, output sanitizer
      session/        -- Session-aware quit
      dynamic/        -- Auto-discovered modules (darwin drops new modules here)
    metaconfig/      -- Central parameter configuration (bind-mounted)
      parameters.el  -- All tunable behavioral parameters
      gptel.el       -- Ollama backend configuration
    test/            -- Test suite (run-tests.el + per-module tests)
  prompts/           -- Agent profiles and prompt templates (bind-mounted to agents.d)
    agents/          -- One subdirectory per agent (<name>/prompt.org)
    common/          -- Prompt templates shared across agents
    base_context.org -- Shared context inherited by all agents via #+INCLUDE
  containers/        -- Podman container definitions
    images/emacboros/Containerfile -- Main container image
    scripts/preflight.sh -- Security audit script (runs before Emacs)
    build.sh         -- Container build script
  utils/             -- Utility scripts
    emacboros.sh     -- Container launch script (--personalization flag required)
    darwin-cycle.sh  -- Darwin autonomous cycle launcher
    darwin-loop.sh   -- Darwin loop wrapper
  workspace/         -- Working directory for agent outputs (CTF, audit reports)
```

## Personalization

Personal data (knowledge bases, per-agent files, audit logs) is separated from the i.ar repo. The `--personalization` flag on `emacboros.sh` mounts three subdirectories:

```
<personalization-dir>/
  knowledge/         -- Curated knowledge bases (injectable via C-c k)
    user/            -- User identity, bio, domains, stack
    iar/             -- This project's self-documentation
    infra/           -- Ansible infrastructure documentation
    linux/           -- Linux administration knowledge
    ignisp/          -- ignisp programming language knowledge
  tasks/<agent>/     -- Per-agent personal files: TODO.md, IDEAS.md, LOGS.md, SUMMARY.md, MEMORIES.md
  audit/<agent>/     -- Per-agent HISTORY.log files
  audit/audit.log    -- Global audit log
```

Inside the container:
- `knowledge/` -> `/root/.emacs.d/knowledge`
- `tasks/` -> `/root/.emacs.d/tasks`
- `audit/` -> `/root/.emacs.d/audit`

## Container Architecture

The Emacs environment runs inside a Podman container built from `quay.io/fedora/fedora-minimal`.

### Container Hardening

- **Read-only root filesystem**: Overlay is read-only, only bind-mounted paths are writable
- **Capability dropping**: All capabilities dropped, only NET_RAW and NET_BIND_SERVICE added (for nmap, traceroute, binding to low ports)
- **Preflight audit**: `preflight.sh` runs before Emacs starts, checks for dangerous writable paths, capability leaks, and host mount surprises. Exits non-zero if any check fails.
- **Dangerous paths blocked**: `.git/hooks`, `docker.sock`, cron, systemd, ssh are checked for writability

### Bind Mounts

- `/root/i.ar` -> `/root/i.ar` (btrfs subvolume, the project repo)
- `/root/i.ar/emacs.d` -> `/root/.emacs.d` (Emacs configuration)
- `/root/i.ar/prompts` -> `/root/.emacs.d/agents.d` (agent profiles and prompt templates)
- `/root/i.ar/metaconfig` -> `/root/.emacs.d/metaconfig` (parameters)
- Personalization dir `knowledge/` -> `/root/.emacs.d/knowledge` (via `--personalization`)
- Personalization dir `tasks/` -> `/root/.emacs.d/tasks` (via `--personalization`)
- Personalization dir `audit/` -> `/root/.emacs.d/audit` (via `--personalization`)

### Flags

- `--personalization PATH` (required): Mounts knowledge, tasks, and audit subdirectories
- `--ollama-host HOST:PORT` (optional): Override Ollama backend (default from env)
- `--self-modification` (optional): Enables tier 2 file guard relaxation for .el file edits

## Network

The container connects to Ollama via WireGuard mesh network:
- Ollama host: `10.66.0.5:11434` (server-pc, RTX 3080)
- Configurable via `EMACBOROS_OLLAMA_HOST` environment variable or `--ollama-host` flag
- All traffic goes through WireGuard -- no direct internet exposure

## Network Topology

Five nodes connected via WireGuard mesh (10.66.0.0/16):

1. **randazzo-ar** (10.66.0.1) -- VPS proxy hub, Caddy + TLS, Cloudflare Tunnel fallback
2. **ob-ar** (10.66.0.2) -- VPS AI playground, Docker, SSH for AI agents
3. **i-ar** (10.66.0.3) -- Dedicated server, Ollama CPU-only, 64GB RAM
4. **laptop** (10.66.0.4) -- Personal laptop, future NPU agent
5. **server-pc** (10.66.0.5) -- Local GPU server, RTX 3080 10GB, Ollama GPU offloading

Only randazzo-ar has public web ports (80/443). All other services are WireGuard-only.

## Models

Configured in `metaconfig/gptel.el`:
- `glm-5.2:cloud` (default)
- `gpt-oss:120b`, `gpt-oss:20b`
- `mistral-medium-3.5:128b`
- `nemotron-3-super:120b`, `nemotron-3-ultra:cloud`
- `deepseek-v4-pro:cloud`
- `north-mini-code-1.0:q8_0`
- `granite4.1:8b-q8_0`

Ollama request params: temperature 0.7, top_p 0.90, num_ctx 1048576 (1M), num_predict 65536.

## Security Model

1. **Single entry point**: Only randazzo-ar has public web ports. Everything else is WireGuard-only.
2. **TLS everywhere**: Caddy handles Let's Encrypt automatically.
3. **No exposed Ollama**: Ollama binds to WireGuard IP only.
4. **Key-only SSH**: Password auth disabled, fail2ban active.
5. **Firewalld**: Every host runs firewalld -- default deny incoming.
6. **AI agent isolation**: Container with dropped capabilities, read-only rootfs, preflight audit.
7. **File guard**: Emacs-level protection of critical files (agent prompts, base context, history logs). Self-modification mode can relax protection for .el files but NEVER for agent prompts or shared context.