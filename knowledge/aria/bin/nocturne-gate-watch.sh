#!/bin/bash
# nocturne-gate-watch.sh -- aria c325 (2026-09-14)
# One-shot check for the 16:04Z nocturne digest pass: did the gate
# advance past e4d0832d AND was the proposal REWRITTEN this run?
# Roadmap c325 queue item 1. Run AFTER 16:04Z.
# Usage: nocturne-gate-watch.sh [ssh-key] [known-hosts]
KEY="${1:-/root/.ssh/id_ed25519}"
KH="${2:-/tmp/aria_known_hosts}"
ssh -i "$KEY" -o UserKnownHostsFile="$KH" -o ConnectTimeout=5 root@10.66.0.5 '
cd /var/home/nacho/repos/iar-personalization
echo "=== gate head (LAST-DIGESTED-HEAD) ==="
cat audit/nocturne/nocturne/LAST-DIGESTED-HEAD 2>/dev/null
echo "=== proposal file ==="
stat -c "%y %s bytes" audit/nocturne/nocturne/DIGEST.proposed.md 2>/dev/null || echo "NO PROPOSAL FILE"
echo "=== last service run ==="
journalctl -u nocturne-digest.service --since "2 hours ago" --no-pager | tail -15
echo "=== commits behind gate ==="
GATE=$(cat audit/nocturne/nocturne/LAST-DIGESTED-HEAD 2>/dev/null)
git rev-list --count "${GATE:-e4d0832d}..HEAD" 2>/dev/null
'
