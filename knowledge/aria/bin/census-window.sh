#!/bin/bash
# census-window.sh -- one-call census of the early-morning failure window.
# Built c70 (2026-09-08) after c69's census cost ~10 tool calls of journald
# archaeology. Instrument-tax law: investigations need cheaper calls.
#
# Usage (on sophon, or via ssh 'bash -s' < census-window.sh):
#   census-window.sh [YYYY-MM-DD] [agent]
# Defaults: today (UTC), agent=aria.
#
# Reads:
#   journald -u aria-cycle.service  -> per-run exits, timeouts, grace outcomes
#   audit/iar/<agent>/REQUESTS.log  -> request counts, per-request latency
#
# Output: per-run table + H1/H2 verdict line. Exits 0 always (census never
# fails loud enough to kill anything; a bad input prints usage).

set -u
DAY="${1:-$(date -u +%Y-%m-%d)}"
AGENT="${2:-aria}"
PERS="${PERS:-/var/home/nacho/repos/iar-personalization}"
REQ="$PERS/audit/iar/$AGENT/REQUESTS.log"

# Window: 00:00-06:30 UTC of $DAY (the observed failure window is 00:30-06:00;
# pad 30 min both sides so run boundaries are visible).
SINCE="$DAY 00:00:00"
UNTIL="$DAY 06:30:00"

echo "== census-window: agent=$AGENT day=$DAY window=00:00-06:30 UTC =="

# --- journald census -------------------------------------------------------
# Rotate lines of interest:
#   [INF] ... Cycle 1 succeeded in Ns (exit 0)
#   [INF] ... Cycle 1 FAILED ...
#   [aria] Cycle timed out after 1800s -- requesting summary (grace 120s)
#   [aria] Cycle complete. Turns: N, Tool calls: N, Exit: N
# Runs are aria-only: filter on the [aria] tag + the INF lines between
# aria start/end pairs. Simpler honest approach: pull all lines, keep
# aria-tagged + INF exit lines, and let the reader pair them by proximity.
JOUT=$(journalctl -u aria-cycle.service --no-pager --since "$SINCE" --until "$UNTIL" 2>/dev/null \
  | grep -E "\[$AGENT\] Cycle (complete|timed out)|Cycle 1 (succeeded|FAILED)|\[$AGENT\] Starting cycle")

if [ -z "$JOUT" ]; then
  echo "no journald lines for $AGENT in window (clean or unit not logging)"
  exit 0
fi

# Pair start/end per run: walk lines in order.
RUNS=$(echo "$JOUT" | awk -v ag="$AGENT" '
  /\] Starting cycle/ { start=$1" "$2" "$3; turns=""; tools=""; exit_=""; to=0; grace=""; next }
  /timed out after/   { to=1 }
  /Cycle complete/ {
    for (i=1;i<=NF;i++) {
      if ($i=="Turns:") turns=$(i+1)
      if ($i=="Tool") tools=$(i+2)
      if ($i=="Exit:") exit_=$(i+1)
    }
    if (to==1) grace=(exit_=="0" ? "grace-saved" : "grace-killed")
    print start" | to="to" | turns="turns" tools="tools" exit="exit_" "grace
    to=0
  }
')
echo "--- runs (start UTC | timeout? turns tools exit fate):"
echo "$RUNS"

# Aggregate counts.
NTIMEOUT=$(echo "$RUNS" | grep -c "to=1" || true)
NEXIT1=$(echo "$RUNS" | grep -c "exit=1" || true)
NRUNS=$(echo "$RUNS" | wc -l)
echo "--- aggregate: runs=$NRUNS timeouts=$NTIMEOUT exit1=$NEXIT1"

# --- REQUESTS.log latency for the window -----------------------------------
if [ ! -f "$REQ" ]; then
  echo "REQUESTS.log missing at $REQ -- no latency census"
  exit 0
fi
# START lines in window; pair with the next RESPONSE line's timestamp.
AW=$(awk -v s="$DAY 00" -v u="$DAY 06" '
  /^\[[0-9-]+ [0-9:]+\] REQ .* START/ {
    ts=substr($1" "$2,2,19)
    if (ts >= s && ts <= u) { start_ts=ts; msgs=""; if (match($0,/msgs=[0-9]+/)) msgs=substr($0,RSTART+5,RLENGTH-5); print "START "ts" msgs="msgs }
  }
  /^\[[0-9-]+ [0-9:]+\] REQ .* RESPONSE/ {
    ts=substr($1" "$2,2,19)
    if (start_ts != "" && ts >= s && ts <= u) {
      cmd="date -u -d \""ts"\" +%s 2>/dev/null"; cmd | getline t2; close(cmd)
      cmd2="date -u -d \""start_ts"\" +%s 2>/dev/null"; cmd2 | getline t1; close(cmd2)
      if (t1>0 && t2>t1) lat=t2-t1; else lat=-1
      print "LAT "lat
      start_ts=""
    }
  }
' "$REQ")
NREQ=$(echo "$AW" | grep -c "^START" || true)
if [ "$NREQ" -gt 0 ]; then
  # Latency stats: median-ish (sort, take middle), max, count>60s.
  echo "$AW" | grep "^LAT" | awk '{print $2}' | sort -n > /tmp/census_lat.$$
  NLAT=$(wc -l < /tmp/census_lat.$$)
  MED=$(sed -n "$((NLAT/2+1))p" /tmp/census_lat.$$ 2>/dev/null || echo "?")
  MAX=$(tail -1 /tmp/census_lat.$$ 2>/dev/null || echo "?")
  SLOW=$(awk -v m=60 '$1>m' /tmp/census_lat.$$ | wc -l)
  echo "--- requests in window: n=$NREQ latency: median=${MED}s max=${MAX}s over60s=$SLOW"
  rm -f /tmp/census_lat.$$
else
  echo "--- requests in window: 0 (log rotated past window or clean window)"
fi

# --- verdict ----------------------------------------------------------------
# H1 (workload): timeouts show turns flowing (turns>=10) and requests flowing;
#   post-fix windows convert to fast closes (timeouts drop to ~0).
# H2 (model): timeouts recur with low turn counts + high per-request latency.
if [ "$NTIMEOUT" -eq 0 ] && [ "$NEXIT1" -eq 0 ]; then
  echo "VERDICT: clean window -- H1 supported (workload converted to fast closes)"
elif [ "$NTIMEOUT" -gt 0 ] && [ -n "$MED" ] && [ "$MED" -gt 0 ] && [ "$MED" -ge 60 ]; then
  echo "VERDICT: timeouts recur with median latency ${MED}s >= 60s -- H2 gains (slow turns under load)"
elif [ "$NTIMEOUT" -gt 0 ]; then
  echo "VERDICT: timeouts recur, latency median ${MED}s -- inspect runs above; shape decides H1/H2"
else
  echo "VERDICT: exit1 without timeout -- different shape, read runs above"
fi
exit 0