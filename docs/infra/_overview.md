# Infrastructure Overview

## Network

WireGuard mesh 10.66.0.0/16, 3 nodes: rammstein=10.66.0.1 (VPS, Caddy/WG hub), yoga=10.66.0.4 (workstation), sophon=10.66.0.5 (12c/96GB RTX 3080: Ollama, Frigate, Zulip, i.ar agents). Consolidated 2026-08-04 (daftpunk+greenday killed); only rammstein has public web ports (80/443), all else WireGuard-only. Host inventory detail: overview.md.

## Ansible (summary)

Inventory `inventory/hosts.yml` (functional groups); vars layered role defaults -> group_vars -> host_vars -> vault (`inventory/group_vars/all/vault.yml`, encrypted). Playbooks: site.yml (full), base.yml, wireguard.yml, ollama.yml, zulip.yml, etc.

## Key Services

Caddy (rammstein, TLS+proxy), Ollama (sophon, WG-only), Frigate NVR (8 cams, sophon), Zulip (sophon), i.ar debug containers (sophon+rammstein, SSH over WG, host root /host read-only). Detail: overview.md.

## Zulip

Self-hosted Zulip (Agora) on sophon, podman compose, Caddy TLS at agora.randazzo.ar. Full doc: zulip.md (stack, unit, realm data, bot API, backup gap).

## Security (summary)

Key-only SSH (password auth disabled), fail2ban, firewalld default deny on all hosts. Ollama binds WireGuard IP only; Zulip binds 0.0.0.0:8090 on sophon (perimeter is firewalld + WG-only routing; Caddy provides TLS + public access). Full detail: security.md.

## Domains

randazzo.ar (portfolio), i.ar (static landing, proxied by new owner's Cloudflare), camaras.randazzo.ar (Frigate), wiki.randazzo.ar (wiki), caldav.randazzo.ar (Radicale), agora.randazzo.ar (Zulip). Full domain->backend table: overview.md.

## Full Docs

operations.md (deployment, recovery), overview.md (detailed topology), playbooks.md (playbook reference), roles.md (role reference), security.md (security details), zulip.md (Zulip full doc).
## Git Server

Self-hosted bare repos on sophon (/home/git/repos, 20 repos) mirrored to
rammstein via post-receive hook. Cycle containers push as root (file-path);
hook heals ownership + mirrors as git user. Known verified issues (fixes
queued for Nacho): root-push pollution (reactive heal, never zero while root
pushes continue), dangling HEAD on 19/20 sophon repos (HEAD->master, only
main exists), mirror push silent failure (|| true). Full detail: git-server.md.