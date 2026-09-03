# Infrastructure Overview

## Network

3 nodes via WireGuard mesh (10.66.0.0/16):

| Host | Codename | WG IP | Role | Hardware |
|------|----------|-------|------|----------|
| rammstein | randazzo-ar | 10.66.0.1 | Proxy hub, Caddy, WG hub | VPS 2c/4GB |
| yoga | laptop | 10.66.0.4 | Daily driver, backup client | Intel Ultra, Fedora WS |
| sophon | server-pc | 10.66.0.5 | GPU Ollama, Frigate NVR, SecPlatform, Zulip | 12c/96GB, RTX 3080 |

Consolidated 2026-08-04: daftpunk + greenday killed. rammstein is sole VPS.

Only rammstein has public web ports (80/443). All else WireGuard-only.

## Ansible Structure

- Inventory: `inventory/hosts.yml` with functional groups (cloud, local, proxy, ollama_hosts, secplatform_hosts, etc.)
- Variables layered: role defaults -> group_vars/all -> group_vars/<group> -> host_vars -> vault
- Vault: `inventory/group_vars/all/vault.yml` (encrypted)
- Playbooks: site.yml (full), base.yml, wireguard.yml, ollama.yml, secplatform.yml, zulip.yml, etc.

## Key Services

- Caddy: automatic TLS, reverse proxy for all web services
- Ollama: sophon (GPU). WireGuard-only, never public.
- Frigate NVR: 8 cameras on sophon, proxied via rammstein
- SecPlatform: multi-tenant SaaS on sophon (podman compose + docker-compose v2), proxied via rammstein
- Zulip: self-hosted chat on sophon (podman compose), proxied via rammstein as agora.randazzo.ar
- i.ar debug containers: on sophon + rammstein, SSH over WireGuard, host root at /host (read-only)

## SecPlatform

Multi-tenant SaaS (vulnerability management + asset scanning) on sophon via podman compose. Originally developed by a friend, adapted to our infra. URLs: app.i.ar (portal, :8091), app-bo.i.ar (BO, :8092), auth.i.ar (Keycloak, :8080) -- all sophon, Caddy-terminated on rammstein.

Runtime: podman + docker-compose v2 (Go binary) as compose provider (podman-compose lacks healthcheck conditions). docker-compose v2 connects via `podman.socket`. Root podman context, SELinux `:z` labels, nginx direct `proxy_pass`.

Ansible role `roles/secplatform/`: installs docker-compose v2, enables podman sockets, clones repo, creates .env + tenant dirs, systemd service (`secplatform-prod.service`). Deploy: `ansible-playbook playbooks/secplatform.yml --ask-vault-pass`.

MVP: no email, no MFA, no CI/CD. Seed users in Keycloak realm JSONs.

Full detail lives in the iar-prod knowledge label (its overview + deployment.md).

## Zulip

Self-hosted Zulip chat server for the AI research laboratory project. Running on sophon via podman compose (same pattern as SecPlatform). Caddy on rammstein terminates TLS and reverse-proxies to sophon:8090.

### URLs

| Domain | Service | Backend |
|--------|---------|---------|
| agora.randazzo.ar | Zulip chat | sophon:8090 |

### Container Runtime

- Same podman compose pattern as SecPlatform (docker-compose v2, system podman socket, SELinux `:z` labels)
- Stack: Zulip server + PostgreSQL + Memcached + RabbitMQ + Redis (5 containers)
- Image: ghcr.io/zulip/zulip-server:12.2-0
- No email, no open registration. Accounts created manually via admin panel.

### Ansible Role

`roles/zulip/` in iar-infrastructure:
- Installs docker-compose v2 if not present
- Creates compose dir + data dirs with SELinux labels
- Generates .env with secrets from vault
- Creates systemd service (`zulip-stack.service`)
- Deploy: `ansible-playbook playbooks/zulip.yml --ask-vault-pass`

## Security

- Key-only SSH, password auth disabled, fail2ban
- Firewalld default deny on all hosts
- Ollama binds to WireGuard IP only
- SecPlatform services bind to WireGuard IP only (10.66.0.5)
- Zulip binds to localhost:8090, Caddy provides TLS + public access

## Domains

randazzo.ar (portfolio), i.ar (landing), app.i.ar (SecPlatform client), app-bo.i.ar (SecPlatform BO), auth.i.ar (Keycloak), camaras.randazzo.ar (Frigate), wiki.randazzo.ar (wiki), caldav.randazzo.ar (Radicale), agora.randazzo.ar (Zulip).

## Full Docs

operations.md (deployment, recovery), overview.md (detailed topology), playbooks.md (playbook reference), roles.md (role reference), security.md (security details). Use read_file for details.