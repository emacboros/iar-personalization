#!/bin/bash
# frontend-eye-check.sh v1 (2026-09-08, aria cycle 74)
# -------------------------------------------------------------
# The 7.1 frontend eye-check loop (agora-v2-architecture.md sec 8
# item 1): headless browser screenshot -> eye organ -> report.
# Converts the "cycles don't touch frontend" ban into a gate.
#
# Targets: https://i.ar/ (static landing) and https://aria.randazzo.ar/
# (dashboard). Per target: firefox --headless --screenshot at VIEWPORT
# size (1280x800 -- full-page windows degrade eye reads; c74 finding:
# 1280x2400 produced hallucinated text, 1280x800 read the same page
# correctly), png->jpg (proven path), ONE gemma3:4b read, append to
# the frontend eye ledger, and on success write/refresh the REPORT.md
# artifact that relay watch 20260908-0000 fires on.
#
# SCARS BAKED IN (c74):
# - jq @base64 CORRUPTS BINARY (UTF-8 replacement chars). Image
#   payloads are built with python3 json.dumps + base64, never jq.
# - The eye is a WITNESS, not an instrument (eye-noise law, c19):
#   reads are recorded verbatim; overlap claims are UNVERIFIED until
#   a human or higher-res pass corroborates.
#
# Runs ON SOPHON as root (ssh 'bash -s' -- PDIR). Writes ONLY to the
# repo's audit tree, tasks tree, and /tmp. Exit ALWAYS 0 (organ-class
# failure policy).
#
# Usage: frontend-eye-check.sh [PDIR]
# -------------------------------------------------------------
set -u

SCRIPT_SRC="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SRC" ] && [ "$SCRIPT_SRC" != "bash" ] && [ -f "$SCRIPT_SRC" ]; then
  ABS="$(readlink -f "$SCRIPT_SRC" 2>/dev/null)"
  PDIR="${1:-$(cd "$(dirname "$ABS")/../../.." && pwd)}"
else
  PDIR="${1:-}"
fi
# CONTEXT GUARD (c18 law): an organ outside its body must not invent one.
if [ -z "$PDIR" ] || [ ! -d "$PDIR/.git" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] frontend-eye-check: PDIR is not the repo ('${PDIR:-}') -- refusing ghost state" >&2
  exit 0
fi

LEDGER="$PDIR/audit/iar/aria/EYE-FRONTEND-LEDGER.log"
REPORT="$PDIR/tasks/iar/agora/embodiment/eye-check/REPORT.md"
OLLAMA="http://10.66.0.5:11434/api/generate"
EYE="qwen3.6:35b-a3b"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TARGETS="https://i.ar/ https://aria.randazzo.ar/"

mkdir -p "$(dirname "$LEDGER")" "$(dirname "$REPORT")" 2>/dev/null
touch "$LEDGER" 2>/dev/null || exit 0

OVERALL="ok"
REPORT_BODY=""
for URL in $TARGETS; do
  TAG=$(echo "$URL" | sed 's#https://##; s#[/.]#_#g')
  PNG="/tmp/eyefront-$TAG.png"
  JPG="/tmp/eyefront-$TAG.jpg"
  # Viewport-size screenshot (NOT full-page -- see c74 eye-noise finding)
  timeout 45 firefox --headless --screenshot "$PNG" --window-size=1280,800 "$URL" >/dev/null 2>&1
  if [ ! -s "$PNG" ]; then
    echo "[$NOW] $URL FAIL screenshot" >> "$LEDGER"
    echo "$URL FAIL screenshot"
    OVERALL="degraded"
    REPORT_BODY="$REPORT_BODY
- $URL: FAIL (screenshot failed at $NOW)"
    continue
  fi
  # png -> jpg (smaller, proven ollama path)
  if command -v magick >/dev/null 2>&1; then magick "$PNG" "$JPG" 2>/dev/null; else convert "$PNG" "$JPG" 2>/dev/null; fi
  [ ! -s "$JPG" ] && JPG="$PNG"  # fall back to png if conversion unavailable
  # Eye read. Payload built with python3 -- jq @base64 corrupts binary (c74 scar).
  python3 - "$JPG" > /tmp/eyefront-req.json <<'PYEOF'
import base64, json, sys
with open(sys.argv[1], "rb") as f: b = f.read()
req = {"model": "qwen3.6:35b-a3b", "keep_alive": 300,
       "prompt": "Describe this webpage screenshot in 3-4 sentences. Note any layout problems: overlapping text, unreadable text, broken images, or misaligned elements.",
       "images": [base64.b64encode(b).decode()], "stream": False}
json.dump(req, sys.stdout)
PYEOF
  RESP=$(curl -s --max-time 300 "$OLLAMA" -d @/tmp/eyefront-req.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response') or d.get('error',''))" 2>/dev/null)
  rm -f /tmp/eyefront-req.json "$PNG" "$JPG"
  if [ -z "$RESP" ]; then
    echo "[$NOW] $URL FAIL eye-empty" >> "$LEDGER"
    echo "$URL FAIL eye-empty"
    OVERALL="degraded"
    REPORT_BODY="$REPORT_BODY
- $URL: FAIL (eye returned nothing at $NOW)"
    continue
  fi
  ONELINE=$(echo "$RESP" | tr '\n' ' ' | tr -s ' ')
  echo "[$NOW] $URL READ: $ONELINE" >> "$LEDGER"
  echo "$URL READ: $ONELINE"
  REPORT_BODY="$REPORT_BODY
- $URL: read at $NOW --
  $ONELINE"
done

# REPORT.md: the artifact contract (relay watch 0000 greps '^LIVE:').
# Written/refreshed on every run that had at least one successful read.
if [ -n "$REPORT_BODY" ] && [ "$OVERALL" != "degraded" ]; then
  cat > "$REPORT" <<EOF
LIVE: frontend eye-check loop demonstrated end-to-end ($NOW)
generated: $NOW
loop: firefox --headless --screenshot (viewport 1280x800) -> png->jpg -> qwen3.6:35b-a3b -> this report
targets: https://i.ar/ https://aria.randazzo.ar/
ledger: audit/iar/aria/EYE-FRONTEND-LEDGER.log (append-only)
caveat: the eye is a WITNESS, not an instrument -- overlap/unreadable claims
below are UNVERIFIED until human or higher-res corroboration (eye-noise law).

Latest reads:$REPORT_BODY
EOF
  echo "[$NOW] report refreshed: $REPORT" >> "$LEDGER"
fi
echo "[$NOW] frontend-eye-check done: overall=$OVERALL"
exit 0