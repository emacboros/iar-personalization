# Infrastructure Overview

## Network

3 nodes via WireGuard mesh (10.66.0.0/16):

| Host | Codename | WG IP | Role | Hardware |
|------|----------|-------|------|----------|
| rammstein | randazzo-ar | 10.66.0.1 | Proxy hub, Caddy, WG hub | VPS 2c/4GB |
| yoga | laptop | 10.66.0.4 | Daily driver, backup client | Intel Ultra, Fedora WS |
| sophon | server-pc | 10.66.0.5 | GPU Ollama, Frigate NVR, SecPlatform, Zulip | 12c/96GB, RTX 3080 |

Consolidated 2026-08-04: daftpunk + greenday killed. rammstein is sole VPS. Only rammstein has public web ports (80/443); all else WireGuard-only.

## Ansible (summary)

Inventory `inventory/hosts.yml` (functional groups); vars layered role defaults -> group_vars -> host_vars -> vault (`inventory/group_vars/all/vault.yml`, encrypted). Playbooks: site.yml (full), base.yml, wireguard.yml, ollama.yml, secplatform.yml, zulip.yml, etc.

## Key Services

- Caddy (rammstein): automatic TLS, reverse proxy for all web services
- Ollama: sophon (GPU), WireGuard-only, never public
- Frigate NVR: 8 cameras on sophon, proxied via rammstein
- SecPlatform: multi-tenant SaaS on sophon (podman compose) -- full detail in iar-prod docs
- Zulip: self-hosted chat on sophon (podman compose), proxied via rammstein
- i.ar debug containers: sophon + rammstein, SSH over WireGuard, host root at /host (read-only)

## Zulip

Self-hosted Zulip 12.2-0 (`ghcr.io/zulip/zulip-server`) on sophon via podman compose (docker-compose v2, system podman socket, SELinux `:z` -- same pattern as SecPlatform). Stack: Zulip + PostgreSQL + Memcached + RabbitMQ + Redis (5 containers). `agora.randazzo.ar` -> sophon:8090, Caddy TLS. No email, no open registration; accounts created manually via admin panel. Ansible role `roles/zulip/`: compose dir + data dirs (SELinux labels), .env from vault, systemd `zulip-stack.service`. Deploy: `ansible-playbook playbooks/zulip.yml --ask-vault-pass`.

## Security (summary)

Key-only SSH (password auth disabled), fail2ban, firewalld default deny on all hosts. Ollama and SecPlatform bind WireGuard IP only; Zulip binds localhost:8090 (Caddy provides TLS + public access). Full detail: security.md.

## Domains

randazzo.ar (portfolio), i.ar (landing), app.i.ar (SecPlatform client), app-bo.i.ar (SecPlatform BO), auth.i.ar (Keycloak), camaras.randazzo.ar (Frigate), wiki.randazzo.ar (wiki), caldav.randazzo.ar (Radicale), agora.randazzo.ar (Zulip).

## Full Docs

operations.md (deployment, recovery), overview.md (detailed topology), playbooks.md (playbook reference), roles.md (role reference), security.md (security details).