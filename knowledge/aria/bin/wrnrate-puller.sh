#!/bin/bash
# wrnrate-puller v1 (2026-09-20, aria c160)
# Per-cam go2rtc producer i/o-timeout WRN counts, 5min cadence.
# Purpose: the WRN histogram IS the freeze clock (c158/c159 heal-lock,
# 10/10 shapes). This puller turns heal-lock analysis into a JOIN
# against ch2-census rows instead of a per-cycle log walk.
# Deploy: sophon root cron */5. Output: /var/lib/aria-fleet/wrnrate.log
#   one line per run: ts=<epoch> <ISO8601Z> <cam>=<n> ...
# Laws baked in:
#   ROOTLESS-PODMAN (c154): frigate lives in nacho's store; su -l nacho.
#   CLOCK-FROM-TOOL: timestamps from date(1), never generation.
#   LAW-50 CLOCK: relative --since window only (T...Z parses as LOCAL
#     on sophon, c158 fifth clock-law member).
#   LAW-50 STRUCTURED-FIELDS (c154): cam<->IP mapping from the go2rtc
#     /api/streams structured API, never hardcoded guesses.
#   FIELD-ANCHORED CENSUS (c327): count anchored on the IP:554 parse
#     field inside WRN lines, never the whole line.
#   INSTRUMENT-SELF-TEST (c156): no state, no sleep loop -- a stall is
#     structurally impossible; failure modes are MAP=FAIL lines.
set -u
LOG=/var/lib/aria-fleet/wrnrate.log

API=$(runuser -l nacho -c "podman exec frigate curl -s --max-time 5 http://localhost:1984/api/streams" 2>/dev/null)
if [ -z "$API" ]; then
  echo "ts=$(date +%s) $(date -u +%Y-%m-%dT%H:%M:%SZ) MAP=FAIL" >> "$LOG"
  exit 1
fi

MAP=$(printf "%s" "$API" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    sys.exit(1)
for name,spec in sorted(d.items()):
    for p in spec.get("producers",[]):
        url=p.get("url","")
        if "@192.168.2." in url:
            ip=url.split("@")[1].split("/")[0]
            print(ip.split(".")[-1], name)
' 2>/dev/null)
if [ -z "$MAP" ]; then
  echo "ts=$(date +%s) $(date -u +%Y-%m-%dT%H:%M:%SZ) MAP=PARSE-FAIL" >> "$LOG"
  exit 1
fi

LOGS=$(su -l nacho -c "podman logs --since 5m frigate 2>&1" 2>/dev/null | grep "WRN")
line="ts=$(date +%s) $(date -u +%Y-%m-%dT%H:%M:%SZ)"
while read -r ip cam; do
  [ -z "${ip:-}" ] && continue
  n=$(printf "%s\n" "$LOGS" | grep -c "192\.168\.2\.${ip}:554" || true)
  line="$line ${cam}=${n}"
done <<< "$MAP"
echo "$line" >> "$LOG"

# rotation: keep the log under ~2MB
if [ "$(stat -c%s "$LOG" 2>/dev/null || echo 0)" -gt 2000000 ]; then
  tail -4000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi