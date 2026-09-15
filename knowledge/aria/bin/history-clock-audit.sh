#!/bin/bash
# history-clock-audit.sh -- audit log-line timestamps against the commits
# that introduced them (c362, 2026-09-15).
#
# LAW: a log line's timestamp is a CLAIM, not a measurement. The only ground
# truth for when a line was written is the commit that introduced it.
# Continuo 09-15: two HISTORY.log lines claimed 2026-09-16 (future-dated,
# +24h exactly) and one line carried the literal template [$(date -u ...)]
# -- the clock never ran. The c358 future-day guard covers the census
# vector; this instrument covers the log vector.
#
# Classes flagged:
#   FUTURE     claim > commit by more than FUTURE_TOL -- timestamp lie class
#              (the 09-16 lines: claimed a day that had not happened)
#   STALE      claim < commit by more than STALE_TOL -- backdating / late
#              batch-commit class. Within STALE_TOL = normal batch lag,
#              not flagged.
#   UNEXPANDED literal [$(date ...)] template -- the clock never ran
#   UNPARSED   bracketed field that is not a timestamp
#
# Usage: history-clock-audit.sh <agent> [file-basename] [future-tol] [stale-tol]
#   agent      aria | continuo
#   file       default HISTORY.log (also try USAGE.log)
#   future-tol default 1800s  (30 min)
#   stale-tol  default 21600s (6h; batch-commit lag beyond this is flagged)
#
# Exit: 0 clean, 1 flagged, 2 usage error.

set -u
PERS="${PERS:-/root/personalization}"
AGENT="${1:?usage: history-clock-audit.sh <agent> [file] [future-tol] [stale-tol]}"
BASENAME="${2:-HISTORY.log}"
FUTURE_TOL="${3:-1800}"
STALE_TOL="${4:-21600}"
FILE="$PERS/audit/iar/$AGENT/$BASENAME"

if [[ ! -f "$FILE" ]]; then
  echo "history-clock-audit: no such file: $FILE" >&2
  exit 2
fi

# One blame pass: porcelain gives line -> commit + committer-time.
blame_out=$(git -C "$PERS" blame --porcelain -- "$FILE" 2>/dev/null)
if [[ -z "$blame_out" ]]; then
  echo "history-clock-audit: blame failed for $FILE" >&2
  exit 2
fi

# Parse blame into per-line commit-time map.
declare -A LINE_TS=()
cur_time=""
lineno=0
while IFS= read -r line; do
  case "$line" in
    $'\t'*) lineno=$((lineno+1)); [[ -n "$cur_time" ]] && LINE_TS[$lineno]=$cur_time ;;
    committer-time\ *) cur_time="${line#committer-time }" ;;
    previous\ *|boundary) ;;
  esac
done <<< "$blame_out"

# Walk the file; extract claimed [timestamps]; compare.
flags=0
checked=0
n=0
while IFS= read -r line; do
  n=$((n+1))
  commit_epoch="${LINE_TS[$n]:-}"
  [[ -z "$commit_epoch" ]] && continue
  commit_date=$(date -u -d "@$commit_epoch" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)

  # Unexpanded template: the clock never ran.
  if [[ "$line" == '[$(date'* ]]; then
    echo "UNEXPANDED  line $n  committed=$commit_date"
    echo "            $line"
    flags=$((flags+1))
    continue
  fi

  claimed=$(echo "$line" | grep -o '^\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\]' | tr -d '[]')
  [[ -z "$claimed" ]] && continue
  claimed_epoch=$(date -u -d "$claimed" +%s 2>/dev/null)
  if [[ -z "$claimed_epoch" ]]; then
    echo "UNPARSED    line $n  claimed=[$claimed]  committed=$commit_date"
    flags=$((flags+1))
    continue
  fi
  checked=$((checked+1))
  delta=$((claimed_epoch - commit_epoch))
  if (( delta > FUTURE_TOL )); then
    echo "FUTURE      line $n  claimed=$claimed  committed=$commit_date  delta=+${delta}s"
    echo "            $line"
    flags=$((flags+1))
  elif (( delta < -STALE_TOL )); then
    echo "STALE       line $n  claimed=$claimed  committed=$commit_date  delta=${delta}s"
    echo "            $line"
    flags=$((flags+1))
  fi
done < "$FILE"

echo "== history-clock-audit: agent=$AGENT file=$BASENAME checked=$checked flagged=$flags future_tol=${FUTURE_TOL}s stale_tol=${STALE_TOL}s =="
[[ $flags -eq 0 ]] && exit 0 || exit 1