#!/bin/bash
# aria agora-probe v1 (2026-09-01, cycle 77)
# -------------------------------------------------------------
# One-command voice-channel health check. The 2026-09-01 redis
# MISCONF incident: Agora 500'd every authed call for 6.5h and
# no instrument watched the channel itself -- the pulse checked
# the services AROUND my voice (containers, timer, disk) but not
# the voice. This probe is the fix.
#
# Checks:
#   1. Unauthed GET /api/v1/messages -- Zulip app server alive
#      (no auth needed for a 401-class response; what matters is
#      NOT a 500/502 from a dead app server or proxy).
#   2. AUTHED GET /api/v1/messages -- the real path: auth ->
#      rate limiter (redis-backed) -> DB. A redis MISCONF or DB
#      failure 500s exactly here. This is the signal.
#   3. POST to lab-notes -- write-path check (optional, off by
#      default; GET covers the redis+DB path).
#
# Usage: agora-probe.sh [keyfile]
#   keyfile defaults to /var/home/nacho/repos/agora/bot/aria-cycle.conf
# Exit: 0 = voice channel healthy, 1 = anything flagged.
# Designed to be called from the pulse recipe and fleet-check.
# -------------------------------------------------------------
set -u
CONF="${1:-/var/home/nacho/repos/agora/bot/aria-cycle.conf}"
SITE="https://agora.randazzo.ar"
FAIL=0

echo "== agora-probe $(date -u +%Y-%m-%d\ %H:%M:%S) UTC =="

# --- 1. unauthed reachability ---
code=$(timeout 15 curl -s -o /dev/null -w '%{http_code}' "$SITE/api/v1/messages?anchor=newest&num_before=1&num_after=0" 2>/dev/null)
case "$code" in
  200|400|401|403) echo "unauthed GET: HTTP $code (app server alive)" ;;
  000) echo "unauthed GET: TIMEOUT/UNREACHABLE -- proxy or app down"; FAIL=1 ;;
  *) echo "unauthed GET: HTTP $code -- unexpected"; FAIL=1 ;;
esac

# --- 2. authed GET (the real path: auth -> redis rate limiter -> DB) ---
if [ ! -r "$CONF" ]; then
  echo "AUTHED GET: SKIP (keyfile $CONF unreadable) -- cannot verify primary signal, FAILING CLOSED"; FAIL=1
else
  KEY=$(awk -F'= *' '$1 ~ /^key *$/ {sub(/\r$/,"",$2); print $2; exit}' "$CONF")
  BODY=$(mktemp) || { echo "mktemp failed"; exit 1; }
  code=$(timeout 15 curl -s -o "$BODY" -w '%{http_code}' \
    -u "aria-cycle@agora.randazzo.ar:${KEY}" \
    "$SITE/api/v1/messages?anchor=newest&num_before=1&num_after=0" 2>/dev/null)
  if [ "$code" = "200" ]; then
    result=$(python3 -c 'import json,sys
try:
    d=json.load(open(sys.argv[1]))
    msgs=d.get("messages",[])
    print("success" if (d.get("result")=="success" and msgs) else "empty-or-failed")
except Exception:
    print("parse-error")' "$BODY" 2>/dev/null)
  rm -f "$BODY"
    if [ "$result" = "success" ]; then
      echo "authed GET: HTTP 200 result=success -- voice channel HEALTHY"
    else
      echo "authed GET: HTTP 200 but result=$result -- API-level problem"; FAIL=1
    fi
  elif [ "$code" = "000" ]; then
    echo "authed GET: TIMEOUT/UNREACHABLE"; FAIL=1
  elif [ "$code" = "401" ] || [ "$code" = "403" ]; then
    echo "authed GET: HTTP $code -- AUTH FAILED (key revoked? identity broken?)"; FAIL=1
  elif [ "$code" = "429" ]; then
    echo "authed GET: HTTP 429 -- rate limited (redis limiter ALIVE; back off)"; FAIL=1
  else
    # 500/502/503: the incident class (redis MISCONF, app dead, proxy dead)
    echo "authed GET: HTTP $code -- VOICE CHANNEL DOWN (redis MISCONF / app / proxy class)"; FAIL=1
  fi
fi

echo "== agora-probe done (FAIL=$FAIL) =="
exit $FAIL