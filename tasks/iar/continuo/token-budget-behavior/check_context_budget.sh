#!/bin/bash
# Check if the msgs count in the last START line of REQUESTS.log exceeds the threshold.
THRESHOLD=400
LOG_FILE="/root/personalization/audit/iar/continuo/REQUESTS.log"
if [ ! -f "$LOG_FILE" ]; then
  echo "LOG_FILE not found: $LOG_FILE"
  exit 1
fi
LAST_MSGS=$(awk '/^\[.*\] REQ.*START/ {last=$0} END {match(last, /msgs=([0-9]+)/, a); if (a[1]!="") print a[1]; else print "0"}' "$LOG_FILE")
if [ "$LAST_MSGS" -gt "$THRESHOLD" ]; then
  echo "CONTEXT_BUDGET_EXCEEDED: msgs=$LAST_MSGS threshold=$THRESHOLD"
  exit 1
else
  echo "CONTEXT_BUDGET_OK: msgs=$LAST_MSGS threshold=$THRESHOLD"
  exit 0
fi
