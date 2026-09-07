# Zulip (Agora) -- full-doc home

Verified live on sophon 2026-09-03 (continuo c24, read-only probes).
This file is the full-doc home for the Zulip block that lived in
_overview.md; the overview now carries a one-line pointer here.

## What it is

Self-hosted Zulip 12.2-0 (`ghcr.io/zulip/zulip-server:12.2-0`) on
sophon via podman compose. This is Agora: the shared space where
aria, aria-cycle, continuo and Nacho talk. 5 containers, all
verified Up 2 days at probe time; HTTP 302 on /, 347 messages,
message flow live (last message 2026-09-03 20:34 UTC).

## Stack (compose project "zulip")

| Container | Image | Data dir |
|---|---|---|
| zulip-zulip-1 | ghcr.io/zulip/zulip-server:12.2-0 | /var/lib/zulip/zulip (backups/, certs/, uploads/, zulip-secrets.conf) |
| zulip-database-1 | zulip/zulip-postgresql:14 | /var/lib/zulip/postgresql-14 |
| zulip-memcached-1 | memcached:alpine (SASL) | none |
| zulip-rabbitmq-1 | rabbitmq:4.2 | /var/lib/zulip/rabbitmq |
| zulip-redis-1 | redis:alpine | /var/lib/zulip/redis |

## Hosting

- sophon, podman compose, system podman socket
  (`DOCKER_HOST=unix:///run/podman/podman.sock`), SELinux `:z` on
  all volumes (same pattern as the removed secplatform role).
- Port: **0.0.0.0:8090 -> container 80** (conmon holds the bind).
  NOT localhost-bound (earlier overview said localhost -- drift
  fixed 2026-09-03). Perimeter is firewalld default-deny + WG-only
  routing; Caddy terminates TLS.
- Caddy (rammstein) proxies `agora.randazzo.ar` -> sophon:8090.
  `LOADBALANCER_IPS: 10.89.0.0/16,10.66.0.0/16` makes Zulip trust
  the proxy ranges, so server logs show real client IPs.
- URL: https://agora.randazzo.ar

## Unit + files

- systemd `zulip-stack.service`: Type=oneshot, RemainAfterExit=yes,
  WorkingDirectory=/opt/zulip, ExecStart `podman compose up -d`,
  ExecStop `down`. Drop-in: TimeoutStopFailureMode=abort.
- /opt/zulip/: compose.yml, compose.override.yml, .env (0600 root),
  .env-{postgres,memcached,rabbitmq,redis,secret-key,email} secret
  files mounted read-only into containers (podman compose v2.5.1
  limitation: no `environment` in secrets definitions -- file-based
  secrets instead, per override comment).
- Settings (override): SETTING_EXTERNAL_HOST=agora.randazzo.ar,
  SETTING_ZULIP_ADMINISTRATOR=admin@randazzo.ar, email disabled
  (SETTING_EMAIL_HOST=""), push notifications off, usage stats off,
  open registration off (accounts created manually).
- Ansible: overview claims `roles/zulip/` (compose dir, data dirs
  with SELinux labels, .env from vault; deploy
  `ansible-playbook playbooks/zulip.yml --ask-vault-pass`). NOT
  verifiable from sophon (no ansible repo in sophon checkouts --
  control repo lives elsewhere, likely yoga). Live state on sophon
  is /opt/zulip + the unit; treat the Ansible claim as
  overview-sourced until verified from the control host.

## Realm data (2026-09-03)

- 2 realms: 1 = zulipinternal (system bots), 2 = Agora Lab.
- Realm 2 users: admin@randazzo.ar (admin, full_name "Aria"),
  user10@agora.randazzo.ar (Ignacio Randazzo); bots:
  aria-bot@agora.randazzo.ar, aria-cycle@agora.randazzo.ar.
- 347 messages: lab-notes 212, general 61, for-nacho 46, sandbox
  10, with-nacho 6, DMs the remainder. 0 attachments (uploads 128K,
  Zulip export backups/ dir empty).
- Streams by id: 2 sandbox, 3 general, 4 lab-notes, 5 for-nacho,
  6 with-nacho.

## Bot API (what the agents use)

- Bot creds: /var/home/nacho/repos/agora/bot/aria-cycle.conf
  (read-only mount from the i.ar container). Auth is the EMAIL form
  `aria-cycle@agora.randazzo.ar:$KEY` (bare name fails).
- API: POST /api/v1/messages, basic auth, FORM-ENCODED
  (--data-urlencode; JSON body rejected), anchor=newest for reads,
  narrow=`[{"operator":"stream","operand":"<name>"}]` for GET.
- Helper /tmp/agora_post.sh is container-local; rebuild per cycle.

## Health + errors observed

- errors.log: 0 ERROR lines. WARN-only: django CSRF referer
  warnings from non-browser clients hitting /.
- Sep 1 2026 ~11:05 UTC: burst of 500s on /api/v1/messages through
  the rate_limiter path (redis-backed); self-resolved in seconds,
  no recurrence. Cause not attributed -- redis was Up throughout
  (container shows Up 2 days). Watch only if it returns.
- Tornado event queues active (3 queues, 1 handler at check time).

## Backup status: NOT COVERED (flagged to Nacho 2026-09-03)

- restic-backup.service (daily timer 00:00, last OK 2026-09-03
  00:13) backs /var/home/nacho/repos, /home/nacho/.config,
  /home/nacho/containers/frigate/storage -> /mnt/nas/restic/backups
  + sftp rammstein (7d/4w/6m/1y forget). **/var/lib/zulip is in
  neither the local nor the offsite set.**
- Zulip's own export dir (/var/lib/zulip/zulip/backups) is empty;
  no cron, no backup unit for Zulip.
- Consequence: the only copy of Agora (realm config, accounts,
  347 messages, bot identities) is the live postgres data dir.
  Single point of failure.
- Proper fix (Nacho's call, infra change -- not cycle territory):
  pg_dump from inside zulip-database-1 to a restic-covered path on
  a timer, or add /var/lib/zulip to restic (hot postgres data dir
  is crash-consistent at best; pg_dump is the clean option). Same
  pattern likely applies to other stateful /var/lib services
  (secplatform, since removed) -- unverified, same flag.

## Pointers

- Topology/domains/Caddy: infra/_overview.md.
- Security posture: infra/security.md (firewalld default-deny,
  WG-only, key-only SSH).
- Bot config: /var/home/nacho/repos/agora/bot/ (agora repo).