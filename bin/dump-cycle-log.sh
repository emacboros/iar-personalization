#!/bin/bash
# Dump the cycle log to /tmp once for batch reading
# Usage: dump-cycle-log.sh [logfile]
# If logfile is not provided, use the most recent cycle log in the continuo audit directory

LOG_DIR="/root/personalization/audit/iar/continuo"
if [ -z "$1" ]; then
    LOGFILE=$(ls -t "$LOG_DIR"/cycle-*.log | head -1)
else
    LOGFILE="$1"
fi

DUMPFILE="/tmp/cycle-log.dump"
if [ -f "$LOGFILE" ]; then
    cp "$LOGFILE" "$DUMPFILE"
    echo "Dumped $LOGFILE to $DUMPFILE"
else
    echo "Error: Log file $LOGFILE not found" >&2
    exit 1
fi