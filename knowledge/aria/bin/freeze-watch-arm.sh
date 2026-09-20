#!/bin/bash
# freeze-watch-arm.sh v1.0 (2026-09-20, aria cycle 156)
# -------------------------------------------------------------
# SELF-ARMING freeze watcher (the c156 missed-window scar: a 15-min
# freeze started and ended between two cycle wakes; wake-triggered
# deployment cannot catch a freeze shorter than the wake gap).
#
# Design: sophon cron runs this every 2.5 min. Each run:
#   1. reads the LATEST census rows (per-cam logs under
#      /var/lib/aria-fleet/ch2census/<cam>.log, written by the 5-min
#      timer's ch2-census-puller.sh);
#   2. if any cam's newest row is FROZEN (ch2=0, anchored, not
#      ARTIFACT), it starts freeze-watch.sh (45-min fine-cadence
#      watcher) UNLESS one is already running (pidfile guard);
#   3. logs its decision to arm-state.log.
#
# The FROZEN detection reuses the puller's own verdict: rows carry a
# trailing " FROZEN" flag (v1.4 artifact guard included). We do NOT
# re-derive frozenness here -- the census is the single source of
# truth for the verdict (two derivations = two verdicts).
#
# Writes only under /var/lib/aria-fleet/freeze-watch/. Read-only
# toward the network. Lockfile law: freeze-watch.sh has its own
# pidfile guard; this arm script is idempotent by construction.
# -------------------------------------------------------------
set -u
OUT=/var/lib/aria-fleet/freeze-watch
CENSUSDIR=/var/lib/aria-fleet/ch2census
FW=/var/home/nacho/repos/iar-personalization/knowledge/aria/bin/freeze-watch.sh
mkdir -p "$OUT" 2>/dev/null || exit 0

# already running? (freeze-watch.sh's own guard is authoritative, but
# we skip the spawn attempt to keep the log clean)
if [ -f "$OUT/pid" ] && kill -0 "$(cat "$OUT/pid" 2>/dev/null)" 2>/dev/null; then
  exit 0
fi

FROZEN_CAMS=""
for f in "$CENSUSDIR"/*.log; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in conn-breakdown.log|census-errors.log) continue;; esac
  last=$(tail -1 "$f")
  case "$last" in
    *" FROZEN")
      cam=$(echo "$last" | awk '{print $2}')
      FROZEN_CAMS="$FROZEN_CAMS $cam"
      ;;
  esac
done

if [ -n "$FROZEN_CAMS" ]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ARM: frozen cams:$FROZEN_CAMS -> spawning freeze-watch" >> "$OUT/arm-state.log"
  nohup bash "$FW" >> "$OUT/arm-state.log" 2>&1 &
else
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) idle (no frozen rows)" >> "$OUT/arm-state.log"
fi
exit 0
