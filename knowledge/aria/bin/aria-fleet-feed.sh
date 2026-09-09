#!/bin/bash
# aria-fleet-feed.sh v1.0 (2026-09-09, aria cycle 121)
# -------------------------------------------------------------
# Host-side feeder: runs fleet-check ON sophon, writes the verdict
# to /var/lib/aria-fleet/fleet-latest.txt, and the fear organ reads
# it as $1. Restores the composite-signal input the fear organ has
# been missing since install (c120 find: the unit passed "" and the
# organ's fleet branch was dead code).
#
# Design (c121):
#   - Runs as root via a system timer (fleet-check needs root: it
#     reads frigate DB, git bare repos, restic unit state).
#   - fleet-check.sh is fetched from the personalization repo at
#     run time -- the version in git IS the running version (the
#     standing fleet-check rule, no copy on sophon to drift).
#   - Writes atomically (tmp + mv) so the fear organ never reads a
#     half-written verdict.
#   - NEVER exits nonzero (feeder failure must not alarm the
#     OnFailure hook -- the organ's own staleness logic is the
#     failure surface; see staleness note below).
#   - The fear organ treats a MISSING/unreadable fleet file as
#     "no fleet input" (its existing behavior), so a broken feeder
#     degrades to today's state, not to a false alarm. Staleness
#     of the file is the feeder's failure signal: the fear organ
#     v1.2 (this cycle) now checks fleet-latest mtime and fears if
#     the composite signal is >26h old (fleet-check is meant to
#     run at least daily).
#
# Install (D-011 aria-reversible class: additive, reversible,
# read-only toward existing state):
#   1. copy this file to /usr/local/bin/aria-fleet-feed.sh
#   2. copy aria-fleet-feed.timer + .service to /etc/systemd/system/
#   3. systemctl daemon-reload && systemctl enable --now aria-fleet-feed.timer
# UNDO: systemctl disable --now aria-fleet-feed.timer; rm the three files.
# -------------------------------------------------------------
set -u

OUT_DIR=/var/lib/aria-fleet
OUT="$OUT_DIR/fleet-latest"
REPO=/var/home/nacho/repos/iar-personalization
SCRIPT="$REPO/knowledge/aria/bin/fleet-check.sh"

mkdir -p "$OUT_DIR" 2>/dev/null || exit 0

if [ ! -r "$SCRIPT" ]; then
  # Repo missing/unreadable: leave the old verdict in place (it
  # will age out via the organ's staleness check). Do not write a
  # fake verdict.
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] fleet-feed: script unreadable: $SCRIPT" >&2
  exit 0
fi

# Run the check. fleet-check exits nonzero on FAIL -- capture, don't die.
TMP="$OUT_DIR/.fleet-latest.tmp"
timeout 420 bash "$SCRIPT" > "$TMP" 2>&1
rc=$?
echo "exit=$rc" >> "$TMP"

mv "$TMP" "$OUT" 2>/dev/null || exit 0
exit 0