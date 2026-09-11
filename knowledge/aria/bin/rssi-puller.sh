#!/bin/bash
# rssi-puller.sh -- sophon-side collector for the camera RSSI longitudinal series.
#
# WHY: each camera appends to /var/rssi.log on local flash. Whether /var
# survives the nightly reboot crons (01:00-06:00 -03) is UNVERIFIED
# (test window: first reboots after 2026-09-11). This puller makes the
# dataset durable regardless: full cat of each camera's log into
# /var/lib/aria-fleet/rssi/<ip>.log every run. Full-cat (not append)
# because it is idempotent across camera reboots and the files are small
# (~160KB/day/camera at 1 line/min).
#
# RUNS ON: sophon (needs L2/routed access to 192.168.2.x camera VLAN).
# INSTALL (nacho, relay 0043): cron on sophon, every 15 min:
#   */15 * * * * /var/lib/aria-fleet/rssi-puller.sh >> /var/lib/aria-fleet/rssi/puller.log 2>&1
#
# AUTH: thingino web UI default cred (thingino:thingino) on the isolated
# camera VLAN -- no WAN exposure; credential already in git history via
# audit trail. Dropbear ssh on the cameras rejects our keys; the curl
# login + run.cgi path is the verified working transport (c209).
#
# Atomicity: write to .tmp, validate (first field = unix epoch), mv.
# On failure the last good copy is kept -- a puller outage never
# destroys data, it only stops updating it.

DEST=/var/lib/aria-fleet/rssi
CAMS="192.168.2.101 192.168.2.102 192.168.2.103 192.168.2.104 192.168.2.105 192.168.2.201 192.168.2.202 192.168.2.203"

mkdir -p "$DEST"

for ip in $CAMS; do
  CJ=$(mktemp)
  curl -s --max-time 8 -c "$CJ" -X POST "http://$ip/x/login.cgi" \
    -H "Content-Type: application/json" \
    -d '{"username":"thingino","password":"thingino"}' >/dev/null
  curl -s --max-time 10 -b "$CJ" \
    "http://$ip/x/run.cgi?cmd=$(printf 'cat /var/rssi.log' | base64 -w0)" \
    > "$DEST/$ip.log.tmp" 2>/dev/null
  rm -f "$CJ"
  if head -1 "$DEST/$ip.log.tmp" 2>/dev/null | grep -qE '^[0-9]{9,} '; then
    mv "$DEST/$ip.log.tmp" "$DEST/$ip.log"
  else
    rm -f "$DEST/$ip.log.tmp"   # keep last good copy
    echo "$(date '+%s') $ip: pull failed, keeping last good" >&2
  fi
done