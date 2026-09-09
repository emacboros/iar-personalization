#!/bin/bash
# eye-battery v2 -- runs the eye's two job shapes against both models.
# Inputs are pre-fetched (v1 learned: no firefox/ffmpeg in the aria
# container; frames+screenshots come from sophon via ssh).
# Usage: bash eye-battery-v2.sh <dir-with-inputs>
# Outputs: desc-<img>-<model>.txt and cam-<img>-<model>.txt with wall time.
set -u
OLLAMA="http://10.66.0.5:11434/api/generate"
EYE_A="gemma3:4b"
EYE_B="qwen3.6:35b-a3b"
DIR="${1:-/tmp/eye-battery}"
cd "$DIR" || exit 1

DESC_PROMPT="Describe this webpage screenshot in 3-4 sentences. Note any layout problems: overlapping text, unreadable text, broken images, or misaligned elements."
CAM_PROMPT='This is a security camera frame. Answer with ONLY the camera name it most likely shows, choosing from: front-door, backyard, driveway, street, balcony, living-room, bedroom, kitchen, garage, garden, other. One word or hyphenated pair, nothing else.'

run_one() {  # img model prompt outfile
  local img="$1" model="$2" prompt="$3" outfile="$4"
  local T0 T1 RESP
  T0=$(date +%s.%N)
  python3 - "$img" "$model" "$prompt" > /tmp/eye-bat-req.json <<'PYEOF'
import base64, json, sys
with open(sys.argv[1], "rb") as f: b = f.read()
json.dump({"model": sys.argv[2], "prompt": sys.argv[3],
           "images": [base64.b64encode(b).decode()], "stream": False}, sys.stdout)
PYEOF
  RESP=$(curl -s --max-time 240 "$OLLAMA" -d @/tmp/eye-bat-req.json \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response') or ('ERR:'+str(d.get('error',''))))" 2>/dev/null)
  T1=$(date +%s.%N)
  local WALL=$(python3 -c "print(f'{$T1-$T0:.1f}')")
  {
    echo "=== img=$img model=$model wall=${WALL}s"
    echo "$RESP"
  } > "$outfile"
  echo "done: $outfile (${WALL}s)"
}

# JOB A: screenshot description (both shots x both models)
for img in eye-bat-shot-iar.jpg eye-bat-shot-aria.jpg; do
  base="${img%.jpg}"
  run_one "$img" "$EYE_A" "$DESC_PROMPT" "desc-$base-gemma3.txt"
  run_one "$img" "$EYE_B" "$DESC_PROMPT" "desc-$base-qwen.txt"
done

# JOB B: camera classification (ground truth in filename)
for img in eye-bat-exterior_1.jpg eye-bat-interior_1.jpg; do
  base="${img%.jpg}"
  run_one "$img" "$EYE_A" "$CAM_PROMPT" "cam-$base-gemma3.txt"
  run_one "$img" "$EYE_B" "$CAM_PROMPT" "cam-$base-qwen.txt"
done

echo "BATTERY V2 COMPLETE"