# Infrastructure Overview

## What This Is

Ansible-based infrastructure as code for 3 hosts: 1 cloud VPS + 2 local machines. Unified by a WireGuard hub-and-spoke mesh network. All servers run Fedora Server 44 or Fedora Workstation (RHEL family only).

Consolidated 2026-08-04: daftpunk + greenday killed. rammstein is sole VPS.

## Network Topology

```
                         ┌─────────────────────────────────────────────────┐
                         │              INTERNET                           │
                         │                                                 │
    ┌────────────────────┤                    │                            │
    │  randazzo.ar       │                    │  i.ar (landing)            │
    │  randazzo.com.ar   │                    │  camaras.randazzo.ar       │
    │  caldav.randazzo.ar│                    │  (new owner's CF proxies   │
    │  (→redirect)       │                    │   i.ar landing to us)      │
    │                    │                    │  wiki.randazzo.ar          │
    │                    │                    │  agora.randazzo.ar (Zulip) │
    ▼                    ▼                    ▼                            │
┌──────────────────────────────────────────────────────────────────────┐  │
│  rammstein (sole VPS)                                                │  │
│  VPS 2c/4GB -- Fedora 44                                            │  │
│  Caddy + TLS (all domains)                                           │  │
│  Static pages: randazzo.ar + i.ar                                    │  │
│  Caddy proxy: camaras.randazzo.ar -> sophon:8971 (Frigate)           │  │
│  Caddy proxy: caldav.randazzo.ar -> localhost:5232 (Radicale)        │  │
│  Caddy static: wiki.randazzo.ar -> /var/lib/wiki/build               │  │
│  Caddy proxy: agora.randazzo.ar -> sophon:8090 (Zulip)              │  │
│  Radicale CalDAV server (localhost:5232)                             │  │
│  Wiki build (ruby + pandoc + pagefind, post-receive hook)            │  │
│  Git bare repos (auto-discovered, mirrors to sophon)                │  │
│  Restic remote target (SFTP, restic user)                            │  │
│  WireGuard hub: 10.66.0.1                                            │  │
└──────┬───────────────────────────────────────────────────────────────┘  │
       │   WireGuard (hub)                                                │
       ═══════════════════════════════════════════════════════════════════ │
       │                                                                  │
       ▼                                              ▼                     │
┌──────────────┐                              ┌──────────────────────────┐ │
│    yoga      │                              │   sophon                 │ │
│  Intel Ultra │                              │ 12c/96GB, RTX 3080      │ │
│  Fedora WS   │                              │ Ollama GPU              │ │
│  WG:10.66.0.4│                              │ Frigate NVR             │ │
│  pass client │                              │ Zulip chat (podman)     │ │
│  restic      │                              │ i.ar agents             │ │
│  backup      │                              │ i.ar agents             │ │
│              │                              │ Git bare repos          │ │
│              │                              │ Restic local target     │ │
│              │                              │ WG:10.66.0.5            │ │
└──────────────┘                              └──────────────────────────┘ │
                                                                            │
                         └─────────────────────────────────────────────────┘
```

## Host Inventory

| Host | Codename | WG IP | Role | Hardware |
|------|----------|-------|------|----------|
| rammstein | randazzo-ar | 10.66.0.1 | Proxy hub, Caddy, WG hub, git bare repos, Radicale, wiki, restic remote | VPS 2c/4GB |
| yoga | laptop | 10.66.0.4 | Daily driver, backup client, pass client | Intel Ultra, Fedora Workstation |

Only rammstein has public web ports (80/443). All else WireGuard-only.

## Ansible Structure

- Variables layered: role defaults -> group_vars/all -> group_vars/<group> -> host_vars -> vault
- Vault: `inventory/group_vars/all/vault.yml` (encrypted)

## Key Services

- Caddy: automatic TLS, reverse proxy for all web services
- Ollama: sophon (GPU). WireGuard-only, never public.
- Frigate NVR: 8 cameras on sophon, proxied via rammstein
- Zulip: self-hosted chat on sophon (podman compose), proxied via rammstein as agora.randazzo.ar
- i.ar debug containers: on sophon + rammstein, SSH over WireGuard, host root at /host (read-only)

## Domains

| Domain | Service | Backend |
|--------|---------|---------|
| randazzo.ar | Portfolio (static) | rammstein local |
| randazzo.com.ar | Redirect to randazzo.ar | rammstein |
| i.ar | Landing page (static) | rammstein local |
| camaras.randazzo.ar | Frigate NVR | sophon:8971 |
| wiki.randazzo.ar | Wiki (static) | rammstein local |
| caldav.randazzo.ar | Radicale CalDAV | rammstein localhost:5232 |
| agora.randazzo.ar | Zulip chat | sophon:8090 |

## Security

- Key-only SSH, password auth disabled, fail2ban
- Firewalld default deny on all hosts
- Ollama binds to WireGuard IP only
- Zulip binds to localhost:8090, Caddy provides TLS + public access

## Full Docs

operations.md (deployment, recovery), overview.md (detailed topology), playbooks.md (playbook reference), roles.md (role reference), security.md (security details). Use read_file for details.
## Restic architecture (2026-09-01 redesign)

Per-host backup targets:

| Host | Primary (full set) | Offsite (critical only) |
|------|--------------------|-------------------------|
| sophon | `/mnt/nas/restic/backups` (md0 btrfs RAID1, 7.3T) -- repos, .config, frigate storage | rammstein sftp -- repos + .config only |
| yoga | local `/mnt/backups/restic` + sophon NVMe sftp | rammstein sftp |
| rammstein | SFTP target only | -- |

Key points:
- Frigate recordings (76G+, growing) go to the NAS only. Rammstein has 80G total
  disk -- a full push would fill it and take down Caddy + every public service.
  Enforced via `restic_remote_paths` (offsite path subset) in host_vars/sophon.yml.
- NAS repo is guarded: backup/check services carry `Requires=mnt-nas.mount` --
  if the NAS is not mounted, they fail closed instead of writing the repo onto
  the root disk.
- Sophon's old primary (`/home/restic/backups` on the NVMe -- same physical disk
  as the source data) is retired as a sophon target; it remains as yoga's sftp
  push target.
- Schedule: backup daily 00:00 -03 (Persistent), check Sun 03:00 -03
  (RandomizedDelaySec 30m). `--retry-lock 10m` everywhere (the Aug 31 race).
- Deploy/verify: `ansible-playbook playbooks/restic.yml --limit sophon
  --vault-password-file ~/.vault_pass` (run from yoga or via ssh nacho@yoga).