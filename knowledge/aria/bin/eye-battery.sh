# Eye benchmark battery v1 -- qwen3.6:35b-a3b vs gemma3:4b
# (2026-09-09 12:07 UTC, cycle 125; for relay aria-0019 item b)
#
# D-012 gate: eye stays gemma3:4b until a candidate BEATS it on the
# eye's ACTUAL job. This battery runs the eye's two real job shapes:
#   JOB A: screenshot description (frontend-eye-check.sh prompt)
#   JOB B: camera-name classification (eye-check.sh/fleet prompt)
#
# Design:
# - Same inputs to both models. JOB A: the two live screenshots the
#   daily eye-feed already takes (i.ar + aria.randazzo.ar). JOB B:
#   one fresh Frigate frame per camera class (2 frames is enough for
#   a first comparison; fleet-check uses 2).
# - Blind scoring: descriptions scored by a THIRD model that does
#   not know which model produced which text. Judge = nemotron-3-
#   super:cloud (resident-classified as cloud, no VRAM). Judge gets
#   the image + both texts (A/B randomized), picks the better one
#   per criterion: layout-detail, correctness-of-claims, usefulness.
# - Camera classification: scored against ground truth (the frame's
#   actual camera, known from the fetch path).
# - ttft measured per call (wall time of the request).
#
# NOT in this battery (deliberately): general VQA, OCR, coding --
# the gate is the eye's job, not the model's ceiling.

set -u
OLLAMA="http://10.66.0.5:11434/api/generate"
OUT=/tmp/eye-battery
mkdir -p $OUT
EYE_A="gemma3:4b"
EYE_B="qwen3.6:35b-a3b"

# ---------- gather inputs ----------
cd $OUT
# JOB A inputs: fresh screenshots (same loop as frontend-eye-check)
for i in iar aria; do
  case $i in
    iar) URL="https://i.ar/";;
    aria) URL="https://aria.randazzo.ar/";;
  esac
  timeout 45 firefox --headless --screenshot "shot-$i.png" --window-size=1280,800 "$URL" >/dev/null 2>&1
  if command -v magick >/dev/null 2>&1; then magick "shot-$i.png" "shot-$i.jpg" 2>/dev/null; else convert "shot-$i.png" "shot-$i.jpg" 2>/dev/null; fi
done
ls -la shot-*.jpg 2>/dev/null || echo "NO SCREENSHOTS"

# JOB B inputs: fresh Frigate frames (2 cameras, known ground truth)
for cam in driveway front-door; do
  curl -s --max-time 20 "http://10.66.0.5:5000/api/${cam}/latest.jpg" -o "frame-$cam.jpg"
done
ls -la frame-*.jpg 2>/dev/null || echo "NO FRAMES"

# ---------- run both models on both jobs ----------
DESC_PROMPT="Describe this webpage screenshot in 3-4 sentences. Note any layout problems: overlapping text, unreadable text, broken images, or misaligned elements."
CAM_PROMPT='This is a security camera frame. Answer with ONLY the camera name it most likely shows, choosing from: front-door, backyard, driveway, street, balcony, living-room, bedroom, kitchen, garage, garden, other. One word or hyphenated pair, nothing else.'

for img in shot-iar shot-aria; do
  for model in $EYE_A $EYE_B; do
    T0=$(date +%s.%N)
    python3 - "$img.jpg" "$model" "$DESC_PROMPT" > req.json <<'PYEOF'
import base64, json, sys
with open(sys.argv[1], "rb") as f: b = f.read()
json.dump({"model": sys.argv[2], "prompt": sys.argv[3],
           "images": [base64.b64encode(b).decode()], "stream": False}, sys.stdout)
PYEOF
    RESP=$(curl -s --max-time 180 "$OLLAMA" -d @req.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response') or ('ERR:'+str(d.get('error',''))))" 2>/dev/null)
    T1=$(date +%s.%N)
    echo "$T1-$T0" | python3 -c "import sys; a,b=sys.stdin.read().strip().split('-'); print(f'ttft={float(a)-float(b):.1f}s')"
    echo "=== $img $model ttft=$(python3 -c "print(f'{float('$T1')-float('$T0'):.1f}s')" 2>/dev/null)" > "desc-$img-$model.txt"
    echo "$RESP" >> "desc-$img-$model.txt"
  done
done

for img in frame-driveway frame-front-door; do
  for model in $EYE_A $EYE_B; do
    T0=$(date +%s.%N)
    python3 - "$img.jpg" "$model" "$CAM_PROMPT" > req.json <<'PYEOF'
import base64, json, sys
with open(sys.argv[1], "rb") as f: b = f.read()
json.dump({"model": sys.argv[2], "prompt": sys.argv[3],
           "images": [base64.b64encode(b).decode()], "stream": False}, sys.stdout)
PYEOF
    RESP=$(curl -s --max-time 120 "$OLLAMA" -d @req.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response') or ('ERR:'+str(d.get('error',''))))" 2>/dev/null)
    T1=$(date +%s.%N)
    echo "=== $img $model wall=$(python3 -c "print(f'{float('$T1')-float('$T0'):.1f}s')" 2>/dev/null) answer=$RESP" > "cam-$img-$model.txt"
  done
done

echo "BATTERY RUN COMPLETE"
ls -la desc-*.txt cam-*.txt