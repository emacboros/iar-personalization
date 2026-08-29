# Network Access and Infrastructure

## What I Have

SSH key at `/root/.ssh/id_ed25519` (comment: `aria@i.ar`). Mounted into the container. Added to `authorized_keys` on sophon (10.66.0.5).

NOT on rammstein (10.66.0.1) -- key was rejected (Permission denied, publickey).

## What I Can Reach

### sophon (10.66.0.5)
- SSH as root: works
- Ollama: http://10.66.0.5:11434 (3 models: gpt-oss:120b, nemotron-3-super:120b, llama3.3:70b)
- SecPlatform: all 8 containers running, BFF health endpoints return 200
- Zulip: 5 containers running, systemd service active
- i.ar repo: /home/nacho/repos/i.ar (behind main branch, at c35139a as of 2026-08-29)
- iar-personalization: /home/nacho/repos/iar-personalization
- GPU: RTX 3080, 10GB VRAM, 7.6GB free at idle

### rammstein (10.66.0.1)
- SSH: Permission denied (publickey). Key not added.

## What I Found (2026-08-29)

### SecPlatform systemd service is failed
`secplatform-prod.service` is `failed (Result: timeout)` since 2026-08-16.
The containers are running fine (12 days uptime, all healthy) because podman
keeps them alive even when the parent service times out. But on reboot, the
service won't start cleanly. The systemd unit has a timeout that's too short
for `podman compose up -d` with healthcheck dependencies.

This is a real issue that should be fixed. The service timeout needs to be
increased, or the service should use `Type=oneshot` instead of `Type=simple`
since `podman compose up -d` is a one-shot command that exits 0.

### i.ar repo on sophon is behind
At commit c35139a (before Aria's first session commits). The bug fixes from
today (delegate arity, cycle handler fixes) are not on sophon yet. Need to
push from this container and pull on sophon, or push to the bare repo on
rammstein and pull from there.

### Running Autonomous Agents

The `iar.sh` script on sophon has examples for running all three autonomous agents:

```
# Darwin
iar.sh --loop --project iar --self-modification --personalization ~/repos/iar-personalization \
  --agent darwin --gptel-fork ~/repos/gptel --max-cycles 50

# Gardener
iar.sh --loop --project iar --personalization ~/repos/iar-personalization \
  --agent gardener --gptel-fork ~/repos/gptel --max-cycles 10
```

These could be run right now via SSH. But the repo on sophon doesn't have
the bug fixes yet. Need to sync first.

## What I Can't Reach

- rammstein (no SSH key)
- The public internet (container has no external network)
- Caddy configs on rammstein
- Ansible inventory (lives in iar-infrastructure repo, not on sophon)