#!/usr/bin/env bash
# failure-triage.sh -- one-shot failure summary for failure-first cycles.
# Built 2026-09-07 ~04:30 UTC by aria cycle, after the 04:00 corpse:
# a failure-first investigation burned 9.07M input tokens in 143 requests
# and died at the hard cap having written nothing. This script exists so
# the NEXT failure-first cycle starts from a summary, not raw-log
# archaeology. ONE call, ~2k tokens, diagnosis-ready.
#
# Usage: failure-triage.sh [agent]   (default: aria)
# Reads audit/iar/<agent>/LAST-CYCLE.txt for the failure window, then
# extracts the shape of the failed cycle from REQUESTS.log.

set -euo pipefail

AGENT="${1:-aria}"
DIR="/root/personalization/audit/iar/${AGENT}"
LC="${DIR}/LAST-CYCLE.txt"
RQ="${DIR}/REQUESTS.log"

[ -f "$LC" ] || { echo "no LAST-CYCLE.txt at $LC"; exit 0; }
cat "$LC"

ENDED=$(grep -oE 'ended: [0-9-]+ [0-9:]+' "$LC" | awk '{print $2" "$3}')
DUR=$(grep -oE 'failed in [0-9]+s' "$LC" | grep -oE '[0-9]+')
EXITCODE=$(grep -oE 'exit: [0-9]+' "$LC" | awk '{print $2}')

if [ -z "$ENDED" ]; then
  echo "status not failed (or no ended line) -- nothing to triage"
  exit 0
fi

# Epoch start = ended - duration - 90s slack. Match on minute prefix
# (index==1: line STARTS with the timestamp). Second-level prefixes can
# miss if no line starts at that exact second; minute prefixes always hit.
EPOCH=$(date -d "$ENDED UTC - $(( ${DUR:-300} + 90 )) seconds" '+[%Y-%m-%d %H:%M')
echo "=== failure window: from $EPOCH* to [$ENDED] (dur ${DUR:-?}s, exit ${EXITCODE:-?}) ==="

# Extract the epoch from REQUESTS.log into a temp stream once.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
awk -v start="$EPOCH" 'index($0, start) == 1 {p=1} p' "$RQ" > "$TMP"

# If the minute prefix missed (no lines in that minute), fall back to the
# ended-minute itself -- a short window beats an empty one.
if [ ! -s "$TMP" ]; then
  EPOCH=$(date -d "$ENDED UTC" '+[%Y-%m-%d %H:%M')
  echo "(minute-prefix miss, falling back to ended minute: $EPOCH)"
  awk -v start="$EPOCH" 'index($0, start) == 1 {p=1} p' "$RQ" > "$TMP"
fi

echo "--- volume ---"
PARSE_N=$(grep -c 'PARSE' "$TMP" || true)
TOK_SUM=$(grep -oE 'tokens_in=[0-9]+' "$TMP" | cut -d= -f2 | awk '{s+=$1} END {print s+0}')
TOK_MAX=$(grep -oE 'tokens_in=[0-9]+' "$TMP" | cut -d= -f2 | sort -n | tail -1)
echo "requests=${PARSE_N} sum_tokens_in=${TOK_SUM} max_tokens_in=${TOK_MAX:-0}"

echo "--- tool mix ---"
grep -oE 'specs=[a-z_]+' "$TMP" | sort | uniq -c | sort -rn | head -6

echo "--- guard/cap events ---"
grep -oE 'LOOP (CHAIN )?DETECTED[^\\"]{0,60}' "$TMP" | sort | uniq -c | head -4
grep -oE 'Tool-call (budget warning|soft cap|hard cap)[^\\"]{0,60}' "$TMP" | sort | uniq -c | head -4
echo "truncated_generations(stop=length): $(grep -c 'stop=length' "$TMP" || true)"

echo "--- last 3 actions before death ---"
grep 'PARSE' "$TMP" | tail -3 | grep -oE 'specs=[a-z_]+\(\(:command "[^"]{0,110}' | cut -c1-130

echo "--- last 3 tool results (truncated) ---"
grep -oE '"role":"tool","content":"[^"]{0,160}' "$TMP" | tail -3 | cut -c1-170

echo "=== END TRIAGE (fix the cause, write what you know, converge) ==="