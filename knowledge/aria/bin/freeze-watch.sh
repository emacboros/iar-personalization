#!/bin/bash
# freeze-watch.sh v1.0 (2026-09-20, aria cycle 141)
# -------------------------------------------------------------
# EPHEMERAL live-catch instrument (c140 falsifier: catch a long freeze
# live, watch the conn at fine cadence through the heal).
#
# Trigger: 2026-09-20 ~05:47Z -- ext4+int1 census-FROZEN (audio=0, video
# flowing, real freeze shape), ext3 flipped conn ~02:50Z and new conn
# audio-dead from birth. Three cams, one window. This watcher samples
# the ch2 census at ~2.5-min cadence (offset to mid-slot so it never
# overlaps the 5-min timer's capture window) and snapshots go2rtc
# /api/streams producer IDs beside every census row.
#
# Witnesses per sample:
#   - ch2-census-puller.sh rows (appends to the SAME per-cam logs +
#     conn-breakdown.log -- richer cadence, same schema)
#   - streams-snap.log: "<utc> <cam>:<producer-id>..." per sample
#
# Collision guard: census capture is ~30s; timer captures span
# ~:05-:35 of each 5-min slot. This watcher only captures when the
# slot-second is in [45,255] (mid-slot), sleeping otherwise.
# LOCKFILE LAW (c137): pidfile written; stale-pid check on start.
#
# Runtime: 45 min then self-removes pid. Read-only toward network;
# writes only under /var/lib/aria-fleet/freeze-watch/.
# -------------------------------------------------------------
set -u
OUT=/var/lib/aria-fleet/freeze-watch
CENSUS=/var/home/nacho/repos/iar-personalization/knowledge/aria/bin/ch2-census-puller.sh
mkdir -p "$OUT" 2>/dev/null || exit 0

# single-instance guard
if [ -f "$OUT/pid" ] && kill -0 "$(cat "$OUT/pid" 2>/dev/null)" 2>/dev/null; then
  echo "freeze-watch: already running pid $(cat "$OUT/pid")" >&2
  exit 0
fi
echo $$ > "$OUT/pid"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) freeze-watch start pid $$" >> "$OUT/watch.log"

END=$(( $(date +%s) + 2700 ))   # 45 min
while [ "$(date +%s)" -lt "$END" ]; do
  s=$(date +%s); slot=$(( s % 300 ))
  # timer owns [0,45); give it [255,300) too (its parse tail). Mid-slot only.
  if [ "$slot" -lt 50 ] || [ "$slot" -gt 250 ]; then
    sleep $(( 305 - slot )); continue
  fi
  TS=$(date +%s)
  echo "== sample $TS $(date -u -d @$TS +%H:%M:%SZ)" >> "$OUT/watch.log"
  bash "$CENSUS" >> "$OUT/watch.log" 2>&1
  # go2rtc producer-id snapshot (go2rtc-side witness; conn port is the
  # network-side witness -- a producer-id change = go2rtc remade it)
  podman exec frigate curl -s --max-time 5 http://localhost:1984/api/streams 2>/dev/null | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    parts=[]
    for k in sorted(d):
        ids=[p.get("id") for p in d[k].get("producers",[])]
        parts.append(f"{k}:{ids}")
    print(" ".join(parts))
except Exception as e:
    print("SNAP-ERR",e)' >> "$OUT/streams-snap.log" 2>&1
  echo "ts=$TS $(date -u -d @$TS +%H:%M:%SZ)" >> "$OUT/streams-snap.log"
  sleep 45
done
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) freeze-watch end" >> "$OUT/watch.log"
rm -f "$OUT/pid"