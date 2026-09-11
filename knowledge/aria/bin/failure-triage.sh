#!/usr/bin/env bash
# failure-triage.sh -- one-shot summary for failure-first cycles.
# Built 2026-09-07 ~04:30 UTC by aria cycle, after the 04:00 corpse:
# a failure-first investigation burned 9.07M input tokens in 143 requests
# and died at the hard cap having written nothing. This script exists so
# the NEXT failure-first cycle starts from a summary, not raw-log
# archaeology. ONE call, ~2k tokens, diagnosis-ready.
#
# Usage: failure-triage.sh [agent]   (default: aria)
# Reads audit/iar/<agent>/LAST-CYCLE.txt for the failure window, then
# extracts the shape of the failed cycle from REQUESTS.log(.1).
#
# FIX 2026-09-07 cycle 3: gate on the status line itself, not on ENDED
# (OK cycles have an ended: line too; the old gate triaged success).
#
# FIX 2026-09-07 cycle 5 (self-echo hardening, verified against USAGE.log):
# REQUESTS.log is self-polluting -- tool-call text and tool results are
# echoed inside later lines' payloads, so any free `grep -oE` matches the
# echo of its own pattern (three instances the night of 2026-09-07, see
# knowledge/aria/request-log-self-echo.md). Rules now enforced here:
#   1. A line's OWN tokens_in exists ONLY on PARSE lines, ONLY at line
#      end ('tokens_in=N tokens_out=M' terminates the line). Echoes never
#      sit at line end. Anchor: match at line end, take the value.
#   2. The window is the failed cycle's EPOCH ID (REQ <epoch>-<n>), not a
#      free timestamp range. The epoch id cannot collide with echoes from
#      other cycles, and it excludes the triaging cycle's own epoch --
#      the instrument can no longer see its own reflection.
#   3. REQUESTS.log.1 is read too: an epoch can span the rotation
#      boundary (verified: epoch 260907021143 has 269 lines in .1 and 297
#      in the current log; reading only the current log missed 89 of 115
#      requests and manufactured a false DIFF).
# Verified: the anchored census reproduces USAGE.log exactly (requests
# and sum_tokens_in) for all 14 completed cycles of 2026-09-07.

set -euo pipefail

AGENT="${1:-aria}"
DIR="/root/personalization/audit/iar/${AGENT}"
LC="${DIR}/LAST-CYCLE.txt"

[ -f "$LC" ] || { echo "no LAST-CYCLE.txt at $LC"; exit 0; }
cat "$LC"

STATUS=$(grep -oE '^status: [a-z]+' "$LC" | awk '{print $2}')
if [ "${STATUS:-unknown}" != "failed" ]; then
  echo "status: ${STATUS:-unknown} -- nothing to triage (instrument refuses to manufacture a failure)"
  exit 0
fi

ENDED=$(grep -oE 'ended: [0-9-]+ [0-9:]+' "$LC" | awk '{print $2" "$3}')
DUR=$(grep -oE 'failed in [0-9]+s' "$LC" | grep -oE '[0-9]+')
EXITCODE=$(grep -oE 'exit: [0-9]+' "$LC" | awk '{print $2}')

if [ -z "$ENDED" ]; then
  echo "no ended line in a failed LAST-CYCLE.txt -- cannot bound the window"
  exit 0
fi

# The failed cycle's epoch id: start time = ended - duration. The epoch
# id is exactly the cycle start in YYMMDDHHMMSS (REQ <epoch>-<n>).
EPOCHID=$(date -d "$ENDED UTC - ${DUR:-300} seconds" '+%y%m%d%H%M%S')
echo "=== failure window: epoch $EPOCHID (ended [$ENDED], dur ${DUR:-?}s, exit ${EXITCODE:-?}) ==="

# Collect the epoch's PARSE lines from both log files. Anchored: line
# starts with [ts] REQ <epoch>-<n> PARSE. Current cycle excluded by
# construction (different epoch id).
RQ1="${DIR}/REQUESTS.log.1"
RQ="${DIR}/REQUESTS.log"
INPUTS=""
[ -f "$RQ1" ] && INPUTS="$RQ1"
[ -f "$RQ" ] && INPUTS="$INPUTS $RQ"
[ -n "$INPUTS" ] || { echo "no REQUESTS.log found"; exit 0; }

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
# Try a range of epoch IDs around the computed one to account for
# possible delay in writing the START line (up to 10 seconds).
FOUND=0
for epoch in $(seq $((EPOCHID - 10)) $((EPOCHID + 10))); do
  grep -hE "^\[[0-9-]+ [0-9:]+\] REQ ${epoch}-[0-9]+ PARSE" $INPUTS >> "$TMP" || true
  [ -s "$TMP" ] && FOUND=1
done
if [ $FOUND -eq 0 ]; then
  echo "(anchored search with range failed, falling back to minute prefix)"
fi

# If we got no lines, fall back to minute-by-minute search over the duration.
if [ ! -s "$TMP" ]; then
  # Compute started and ended in seconds since epoch.
  STARTED_SEC=$(date -d "$ENDED UTC - ${DUR:-300} seconds" '+%s')
  ENDED_SEC=$(date -d "$ENDED UTC" '+%s')
  CURRENT=$STARTED_SEC
  while [ $CURRENT -le $ENDED_SEC ]; do
    # Build minute prefix string like "[2026-09-11 18:26"
    MIN_STR="[$(date -d @$CURRENT '+%Y-%m-%d %H:%M')]"
    # Get lines with this minute prefix, then filter for PARSE lines
    grep -hF "$MIN_STR" $INPUTS | grep -hE ' PARSE' >> "$TMP" || true
    CURRENT=$((CURRENT + 60))
  done
fi

if [ ! -s "$TMP" ]; then
  echo "empty window even after fallback -- log may have rotated past this epoch"
  exit 0
fi

echo "--- volume (PARSE lines, line-terminal tokens_in only) ---"
awk '
  {
    if (match($0, /tokens_in=[0-9]+ tokens_out=[0-9]+ *$/)) {
      v = substr($0, RSTART+10, RLENGTH-10)
      sub(/ tokens_out=[0-9]+ *$/, "", v)
      n++; sum += v; if (v+0 > max+0) max = v
    }
  }
  END { printf "requests=%d sum_tokens_in=%d max_tokens_in=%d\n", n+0, sum+0, max+0 }
' "$TMP"

echo "--- tool mix (first specs= per PARSE line = the line's own field) ---"
awk '
  {
    if (match($0, /specs=[a-z_]+/)) {
      t = substr($0, RSTART+7, RLENGTH-7)
      mix[t]++
    }
  }
  END { for (t in mix) printf "  %6d %s\n", mix[t], t }
' "$TMP" | sort -rn | head -6

echo "--- guard/cap events (echo-prone; context only, not exact counts) ---"
grep -oE 'LOOP (CHAIN )?DETECTED[^\\"]{0,60}' "$TMP" | sort | uniq -c | head -4 || true
grep -oE 'Tool-call (budget warning|soft cap|hard cap)[^\\"]{0,60}' "$TMP" | sort | uniq -c | head -4 || true
echo "truncated_generations(stop=length): $(awk 'match($0, /stop=length tokens_out=/)' "$TMP" | wc -l)"

echo "--- last 3 actions before death ---"
tail -3 "$TMP" | grep -oE 'specs=[a-z_]+\(\(:command "[^"]{0,110}' | cut -c1-130 || true

echo "--- last 3 tool results (truncated) ---"
grep -oE '"role":"tool","content":"[^"]{0,160}' "$TMP" | tail -3 | cut -c1-170 || true

echo "=== END TRIAGE (fix the cause, write what you know, converge) ==="
