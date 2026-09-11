#!/bin/bash
# eye-canvas-check.sh v1 (2026-09-11, aria cycle 180)
# -------------------------------------------------------------
# Canvas witness for the dashboard eye (session X known limitation).
# Complements frontend-eye-check.sh: same eye organ (qwen3.6:35b-a3b),
# same ledger, but captures AFTER the rAF paint via Firefox WebDriver
# BiDi -- so the canvas graph (the dashboard's main visual) is seen
# for the first time.
#
# WHY A SEPARATE SCRIPT (not a frontend-eye-check.sh edit):
# - different capture mechanism (BiDi ws vs --screenshot), different
#   failure modes, needs a firefox profile dir + port management.
# - frontend-eye-check.sh is the artifact contract for relay watch
#   0000; its LIVE: line semantics should not change silently.
# - If this stabilizes, merging into one script with --bidi flag is
#   the follow-up (noted in the as-built doc).
#
# Runs ON SOPHON as root. Writes ONLY to the repo's audit tree,
# tasks tree, and /tmp. Exit ALWAYS 0 (organ-class failure policy).
#
# Usage: eye-canvas-check.sh [PDIR]
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
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] eye-canvas-check: PDIR is not the repo ('${PDIR:-}') -- refusing ghost state" >&2
  exit 0
fi

LEDGER="$PDIR/audit/iar/aria/EYE-CANVAS-LEDGER.log"
REPORT="$PDIR/tasks/iar/agora/embodiment/eye-check/CANVAS-REPORT.md"
BIDI_SCRIPT="$PDIR/knowledge/aria/bin/bidi-screenshot.py"
OLLAMA="http://127.0.0.1:11434/api/generate"
EYE="qwen3.6:35b-a3b"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
URL="https://aria.randazzo.ar/"
PORT=9355
PROF="/tmp/aria-eye-bidi-profile"
PNG="/tmp/eye-canvas-dash.png"
JPG="/tmp/eye-canvas-dash.jpg"

mkdir -p "$(dirname "$LEDGER")" "$(dirname "$REPORT")" "$PROF" 2>/dev/null
touch "$LEDGER" 2>/dev/null || exit 0

# BiDi profile prefs: without these the remote port never opens (c180 scar)
cat > "$PROF/user.js" <<'EOF'
user_pref("devtools.debugger.remote-enabled", true);
user_pref("devtools.debugger.force-local", true);
user_pref("remote.active-protocols", 3);
user_pref("remote.force-local", true);
EOF

# Kill any stale eye firefox from a previous run (port collision)
pkill -f "remote-debugging-port $PORT" 2>/dev/null && sleep 1

# Launch firefox headless with BiDi
setsid firefox --headless --remote-debugging-port "$PORT" --profile "$PROF" -no-remote about:blank > /tmp/eye-canvas-ff.log 2>&1 &
FF_PID=$!
sleep 8
if ! grep -q "listening" /tmp/eye-canvas-ff.log 2>/dev/null; then
  echo "[$NOW] $URL FAIL bidi-port (firefox did not open BiDi port)" >> "$LEDGER"
  kill "$FF_PID" 2>/dev/null
  exit 0
fi

# Capture (6s settle = several rAF frames + poll cycle)
if ! python3 "$BIDI_SCRIPT" "$PORT" "$URL" "$PNG" 6000 >> /tmp/eye-canvas-ff.log 2>&1 || [ ! -s "$PNG" ]; then
  echo "[$NOW] $URL FAIL bidi-capture" >> "$LEDGER"
  pkill -f "remote-debugging-port $PORT" 2>/dev/null
  exit 0
fi
pkill -f "remote-debugging-port $PORT" 2>/dev/null

# png -> jpg (proven ollama path)
if command -v magick >/dev/null 2>&1; then magick "$PNG" "$JPG" 2>/dev/null; else convert "$PNG" "$JPG" 2>/dev/null; fi
[ ! -s "$JPG" ] && JPG="$PNG"

# Canvas-presence pre-check (cheap, deterministic -- the eye's claims
# about the canvas are eye-noise-prone; the pixel census is not).
TEAL=$(python3 - "$PNG" <<'PYEOF'
import sys
from PIL import Image
img = Image.open(sys.argv[1]).convert("RGB")
n = sum(1 for p in img.getdata() if p[1] > 150 and p[2] > 150 and p[0] < 100)
print(n)
PYEOF
)

# Eye read. Payload built with python3 -- jq @base64 corrupts binary (c74 scar).
python3 - "$JPG" > /tmp/eye-canvas-req.json <<'PYEOF'
import base64, json, sys
with open(sys.argv[1], "rb") as f: b = f.read()
req = {"model": "qwen3.6:35b-a3b", "keep_alive": -1,
       "prompt": "This is a screenshot of a dashboard with an animated node-graph canvas at its center. Describe the graph: how many nodes, what they are labeled, how they are connected, and the overall visual state. Note any layout problems.",
       "images": [base64.b64encode(b).decode()], "stream": False}
json.dump(req, sys.stdout)
PYEOF
RESP=$(curl -s --max-time 300 "$OLLAMA" -d @/tmp/eye-canvas-req.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response') or d.get('error',''))" 2>/dev/null)
rm -f /tmp/eye-canvas-req.json "$PNG" "$JPG"

ONELINE=$(echo "$RESP" | tr '\n' ' ' | tr -s ' ')
if [ -z "$ONELINE" ]; then
  echo "[$NOW] $URL FAIL eye-empty (teal_px=$TEAL)" >> "$LEDGER"
  exit 0
fi
echo "[$NOW] $URL CANVAS-READ (teal_px=$TEAL): $ONELINE" >> "$LEDGER"

cat > "$REPORT" <<EOF
LIVE: canvas eye-check loop demonstrated end-to-end ($NOW)
generated: $NOW
loop: firefox BiDi (remote-debugging-port, profile prefs) -> navigate+6s settle -> captureScreenshot -> png->jpg -> qwen3.6:35b-a3b -> this report
target: https://aria.randazzo.ar/ (canvas witness -- the rAF-painted graph)
canvas-pixels: teal_px=$TEAL (deterministic pre-check; 0 = canvas absent)
ledger: audit/iar/aria/EYE-CANVAS-LEDGER.log (append-only)
caveat: the eye is a WITNESS, not an instrument -- graph descriptions below are
UNVERIFIED until human or higher-res corroboration (eye-noise law).

Latest read:
- $URL: read at $NOW --
  $ONELINE
EOF
echo "[$NOW] canvas report refreshed: $REPORT" >> "$LEDGER"
echo "[$NOW] eye-canvas-check done (teal_px=$TEAL)"
exit 0