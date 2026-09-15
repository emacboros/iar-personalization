#!/bin/bash
# history-clock-audit.sh -- audit log-line timestamps against the commits
# that introduced them (c362, 2026-09-15; classification c365, 2026-09-15).
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
#   UNEXPANDED literal [$(date ...)] template at the LINE START (anchored --
#              GUARD-AUTHORING LAW c362/c363: the action site is the leading
#              timestamp slot; mid-line prose quoting the template is
#              discussion, not the action).
#   UNPARSED   leading bracketed field that is not a timestamp
#
# Classification (c365) -- the daily watch question is "did a NEW violation
# land after the guard existed", not "do violations exist":
#   <CLASS>-ANNOTATED  line carries an annotation marker (CLOCK FABRICATION --
#                      or CLOCK-NEVER-RAN --): a known, preserved fabrication
#                      (evidence stays in place per c362 policy). Known.
#   <CLASS>-BASELINE   introducing commit predates the guard install
#                      (GUARD_SINCE): pre-guard history. Known.
#   <CLASS> (bare)     unannotated AND introduced at/after the guard install:
#                      the guard failed or was escaped. THIS IS THE ALARM.
#   Exit: 0 = no NEW violations (baseline/annotated flags may exist),
#         1 = at least one NEW violation, 2 = usage error.
#   Residual risk (accepted): a NEW fabrication that copies an annotated
#   line verbatim (echo-receipt vector) would classify as ANNOTATED; the
#   echo-receipt detector covers the response vector, not this one.
#
# Usage: history-clock-audit.sh <agent> [file-basename] [future-tol] [stale-tol]
#   agent      aria | continuo
#   file       default HISTORY.log (also try USAGE.log)
#   future-tol default 1800s  (30 min)
#   stale-tol  default 21600s (6h; batch-commit lag beyond this is flagged)
#   GUARD_SINCE overrides the guard-install epoch (default: resolved from
#   commit 5594fe7d, the HISTORY-CLOCK guard install; fallback hardcoded).

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

# Guard-install epoch: the introducing commit of the HISTORY-CLOCK pre-commit
# guard. Ground truth for "post-guard" classification.
GUARD_SINCE="${GUARD_SINCE:-$(git -C "$PERS" log -1 --format=%ct 5594fe7d 2>/dev/null)}"
if [[ -z "$GUARD_SINCE" ]]; then
  GUARD_SINCE=$(date -u -d '2026-09-15 09:00:00 UTC' +%s)
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
new_flags=0
known_flags=0
checked=0
n=0
while IFS= read -r line; do
  n=$((n+1))
  commit_epoch="${LINE_TS[$n]:-}"
  [[ -z "$commit_epoch" ]] && continue
  commit_date=$(date -u -d "@$commit_epoch" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)

  # Classification helper: is this flag KNOWN (annotated or pre-guard)
  # or NEW (post-guard, unannotated)? Annotation markers are read from
  # the line BODY -- classification only, never detection (detection
  # stays anchored on the leading timestamp slot per GUARD-AUTHORING LAW).
  classify() {
    case "$line" in
      *"CLOCK FABRICATION --"*|*"CLOCK-NEVER-RAN --"*) echo "-ANNOTATED" ;;
      *)
        if (( commit_epoch < GUARD_SINCE )); then echo "-BASELINE"; else echo ""; fi ;;
    esac
  }

  # Unexpanded template: the clock never ran (anchored at line start).
  if [[ "$line" == '[$(date'* ]]; then
    suffix=$(classify)
    echo "UNEXPANDED$suffix  line $n  committed=$commit_date"
    echo "            $line"
    if [[ -z "$suffix" ]]; then new_flags=$((new_flags+1)); else known_flags=$((known_flags+1)); fi
    continue
  fi

  claimed=$(echo "$line" | grep -o '^\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\]' | tr -d '[]')
  [[ -z "$claimed" ]] && continue
  claimed_epoch=$(date -u -d "$claimed" +%s 2>/dev/null)
  if [[ -z "$claimed_epoch" ]]; then
    suffix=$(classify)
    echo "UNPARSED$suffix    line $n  claimed=[$claimed]  committed=$commit_date"
    if [[ -z "$suffix" ]]; then new_flags=$((new_flags+1)); else known_flags=$((known_flags+1)); fi
    continue
  fi
  checked=$((checked+1))
  delta=$((claimed_epoch - commit_epoch))
  if (( delta > FUTURE_TOL )); then
    suffix=$(classify)
    echo "FUTURE$suffix      line $n  claimed=$claimed  committed=$commit_date  delta=+${delta}s"
    echo "            $line"
    if [[ -z "$suffix" ]]; then new_flags=$((new_flags+1)); else known_flags=$((known_flags+1)); fi
  elif (( delta < -STALE_TOL )); then
    suffix=$(classify)
    echo "STALE$suffix       line $n  claimed=$claimed  committed=$commit_date  delta=${delta}s"
    echo "            $line"
    if [[ -z "$suffix" ]]; then new_flags=$((new_flags+1)); else known_flags=$((known_flags+1)); fi
  fi
done < "$FILE"

echo "== history-clock-audit: agent=$AGENT file=$BASENAME checked=$checked known=$known_flags NEW=$new_flags future_tol=${FUTURE_TOL}s stale_tol=${STALE_TOL}s guard_since=$(date -u -d "@$GUARD_SINCE" '+%Y-%m-%d %H:%M:%S') =="
[[ $new_flags -eq 0 ]] && exit 0 || exit 1