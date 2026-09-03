# Infrastructure Overview

## Network

WireGuard mesh 10.66.0.0/16, 3 nodes: rammstein=10.66.0.1 (VPS, Caddy/WG hub), yoga=10.66.0.4 (workstation), sophon=10.66.0.5 (12c/96GB RTX 3080: Ollama, Frigate, SecPlatform, Zulip, i.ar agents). Consolidated 2026-08-04 (daftpunk+greenday killed); only rammstein has public web ports (80/443), all else WireGuard-only. Host inventory detail: overview.md.

## Ansible (summary)

Inventory `inventory/hosts.yml` (functional groups); vars layered role defaults -> group_vars -> host_vars -> vault (`inventory/group_vars/all/vault.yml`, encrypted). Playbooks: site.yml (full), base.yml, wireguard.yml, ollama.yml, secplatform.yml, zulip.yml, etc.

## Key Services

Caddy (rammstein, TLS+proxy), Ollama (sophon, WG-only), Frigate NVR (8 cams, sophon), SecPlatform (sophon), Zulip (sophon), i.ar debug containers (sophon+rammstein, SSH over WG, host root /host read-only). Detail: overview.md.

## Zulip

Self-hosted Zulip 12.2-0 (`ghcr.io/zulip/zulip-server`) on sophon via podman compose (docker-compose v2, system podman socket, SELinux `:z` -- same pattern as SecPlatform). Stack: Zulip + PostgreSQL + Memcached + RabbitMQ + Redis (5 containers). `agora.randazzo.ar` -> sophon:8090, Caddy TLS. No email, no open registration; accounts created manually via admin panel. Ansible role `roles/zulip/`: compose dir + data dirs (SELinux labels), .env from vault, systemd `zulip-stack.service`. Deploy: `ansible-playbook playbooks/zulip.yml --ask-vault-pass`. NOTE: no full-doc home yet -- this block is the only copy of these facts.

## Security (summary)

Key-only SSH (password auth disabled), fail2ban, firewalld default deny on all hosts. Ollama and SecPlatform bind WireGuard IP only; Zulip binds localhost:8090 (Caddy provides TLS + public access). Full detail: security.md.

## Domains

randazzo.ar (portfolio), i.ar (landing), app.i.ar (SecPlatform client), app-bo.i.ar (SecPlatform BO), auth.i.ar (Keycloak), camaras.randazzo.ar (Frigate), wiki.randazzo.ar (wiki), caldav.randazzo.ar (Radicale), agora.randazzo.ar (Zulip). Full domain->backend table: overview.md.

## Full Docs

operations.md (deployment, recovery), overview.md (detailed topology), playbooks.md (playbook reference), roles.md (role reference), security.md (security details).