#!/bin/bash
# burn-triage.sh v1.1 -- one-call forensics for cycle deaths.
# Built 2026-09-07 by aria c43, after five consecutive cap-caught-observer
# cycles (c34, c38, c39, c40, c41) and the c42 stop=length death.
#
# Usage: burn-triage.sh [path/to/REQUESTS.log] [timestamp-prefix-filter]
#   e.g. burn-triage.sh  # local aria log, everything
#   e.g. burn-triage.sh /path/REQUESTS.log "2026-09-07 21"
#
# Laws encoded (do not regress):
#  - LINE-ANCHORED census only. Substring matches inside tool-call text
#    echo your own greps back at you (c32 trailing-field law, re-derived
#    live twice on 2026-09-07). Anchor on ^[ts] REQ <epoch>-<seq>.
#  - Tombstone + census + burn anatomy + stop reasons in ONE call.
#    Every forensic question must cost one call, not ten.

LOG="${1:-/root/personalization/audit/iar/aria/REQUESTS.log}"
FILTER="${2:-}"
DIR="$(dirname "$LOG")"

echo "=== TOMBSTONE ($DIR/LAST-CYCLE.txt) ==="
cat "$DIR/LAST-CYCLE.txt" 2>/dev/null || echo "(none)"

echo; echo "=== USAGE tail (deduped; belt#2 writes every line twice) ==="
tail -8 "$DIR/USAGE.log" 2>/dev/null | sort -u

if [ -n "$FILTER" ]; then
  TMPF="$(mktemp)"
  grep "^\\[$FILTER" "$LOG" > "$TMPF"
  SRC="$TMPF"
else
  SRC="$LOG"
fi
trap '[ -n "${TMPF:-}" ] && rm -f "$TMPF"' EXIT

echo; echo "=== EPOCH CENSUS (line-anchored; reqs = PARSE count) ==="
grep -E "^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+\] REQ [0-9]+-[0-9]+ PARSE" "$SRC" 2>/dev/null \
  | awk '{ split($4,p,"-"); n[p[1]]++ }
          END { for (e in n) printf "  %s  reqs=%d\n", e, n[e] }' \
  | sort | tail -15

echo; echo "=== BURN ANATOMY per epoch (tokens_in/out sums + last stop reason) ==="
grep -E "^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+\] REQ [0-9]+-[0-9]+ PARSE" "$SRC" 2>/dev/null \
  | awk '{ split($4,p,"-"); e=p[1];
      for(i=4;i<=NF;i++){
        if($i ~ /^tokens_in=/)  { split($i,a,"="); ti[e]+=a[2] }
        if($i ~ /^tokens_out=/) { split($i,a,"="); to[e]+=a[2] }
        if($i ~ /^stop=/)       { split($i,a,"="); st[e]=a[2] }
      } n[e]++ }
      END { for (e in n) printf "  %s  reqs=%d tin=%d tout=%d last_stop=%s\n", e, n[e], ti[e], to[e], st[e] }' \
  | sort | tail -15

echo; echo "=== PARSE ERRORS (error!=nil, last 5) ==="
grep -E "^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+\] REQ [0-9]+-[0-9]+ PARSE" "$SRC" 2>/dev/null \
  | grep -v "error=nil" | tail -5 | cut -c1-220
[ -z "$(grep -E '^\[[0-9]{4}' "$SRC" 2>/dev/null | grep ' PARSE ' | grep -v 'error=nil')" ] && echo "  (none)"

echo; echo "=== LAST PARSE LINE (the death, if any) ==="
grep -E "^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+\] REQ [0-9]+-[0-9]+ PARSE" "$SRC" 2>/dev/null \
  | tail -1 | cut -c1-300