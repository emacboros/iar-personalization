#!/usr/bin/env bash
# relay-heartbeat.sh -- the relay's delivery limb (D-006).
#
# Runs host-side on sophon (relay-heartbeat.timer, 10-min cadence).
# The human channel must NOT share fate with citizen health -- that is
# why this is host-side, not piggybacked on the cycle preflight.
#
# Contract (relay/open/20260908-0006):
#   1. Read the relay ledger from the sophon working copy.
#   2. For each open/ request with type: watch, evaluate its `check:`
#      condition (shell command, run from the repo root).
#   3. On condition MET: move open/ -> fired/, send telegram via
#      telegram.sh, log the fire.
#   4. Log EVERY evaluation to journalctl -t relay-heartbeat.
#
# Scope guard: this script ONLY evaluates `type: watch` entries and
# ONLY moves open/ -> fired/. It never edits bodies, never answers,
# never drops. The ledger is owned by the citizens; the heartbeat is
# a limb: it acts on conditions, it does not deliberate.
#
# Install: 2026-09-08 by interactive aria under the session-VI
# autonomy rule (additive, reversible, read-only toward existing
# state). Relay note filed: aria-0008. Undo: systemctl disable --now
# relay-heartbeat.timer && rm /etc/systemd/system/relay-heartbeat.*

set -u

REPO="/var/home/nacho/repos/iar-personalization"
OPEN_DIR="$REPO/relay/open"
FIRED_DIR="$REPO/relay/fired"
TELEGRAM_SH="/var/home/nacho/repos/i.ar/utils/telegram.sh"
LOG_TAG="relay-heartbeat"

log() { logger -t "$LOG_TAG" "$*"; }

# The repo working copy must be fresh: pull before evaluating.
# Pull failure is NOT fatal -- stale checks are better than no checks,
# and the ledger records staleness via the fired-file's pull timestamp.
cd "$REPO" || { logger -t "$LOG_TAG" "FATAL: repo dir missing: $REPO"; exit 1; }
PULL_OUT="$(git pull --ff-only origin main 2>&1 | tail -1)"
logger -t "$LOG_TAG" "pull: $PULL_OUT"

shopt -s nullglob
for req in "$OPEN_DIR"/*.md; do
  # Only type: watch entries are heartbeat business.
  grep -q "^type: watch" "$req" || continue
  # The check command is the line starting "check: " in the body.
  check_cmd="$(grep -m1 "^check: " "$req" | sed 's/^check: //')"
  if [ -z "$check_cmd" ]; then
    logger -t "$LOG_TAG" "WARN: $(basename "$req") has type: watch but no check: line -- skipping"
    continue
  fi
  if ( cd "$REPO" && eval "$check_cmd" ) >/dev/null 2>&1; then
    base="$(basename "$req" .md)"
    title="$(grep -m1 "^title: " "$req" | sed 's/^title: //')"
    # Move to fired/ BEFORE sending: a send failure must not re-fire
    # forever (at-most-once per condition-met; retry is manual).
    mv "$req" "$FIRED_DIR/$base.md"
    logger -t "$LOG_TAG" "FIRED: $base -- $title"
    # Send telegram (credentials sourced from the existing pattern)
    if [ -f "$TELEGRAM_SH" ]; then
      MSG="relay: WATCH FIRED -- $title
req: $base
check: $check_cmd
repo: $REPO/relay/fired/$base.md"
      ( source "$TELEGRAM_SH" && curl -s -m 30 -X POST \
          "https://api.telegram.org/bot${AGENT_TELEGRAM_BOT_TOKEN}/sendMessage" \
          -d chat_id="$AGENT_TELEGRAM_CHAT_ID" --data-urlencode "text=$MSG" \
          >/dev/null 2>&1 ) \
        && logger -t "$LOG_TAG" "telegram sent for $base" \
        || logger -t "$LOG_TAG" "ERROR: telegram send failed for $base (file moved to fired/ -- manual retry)"
    else
      logger -t "$LOG_TAG" "ERROR: telegram.sh missing: $TELEGRAM_SH"
    fi
  else
    logger -t "$LOG_TAG" "check-not-met: $(basename "$req")"
  fi
done
logger -t "$LOG_TAG" "heartbeat pass complete"
exit 0