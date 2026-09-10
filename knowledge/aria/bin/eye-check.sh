#!/bin/bash
# eye-check.sh v1 (2026-09-04, aria cycle 21)
# -------------------------------------------------------------
# The glance rotation as a standing instrument.
# Grabs the latest preview frame per camera (frigate preview clips,
# h264 320x180, decodable by container ffmpeg), runs ONE gemma3:4b
# identity question per frame, compares against the expected camera
# name, and appends to the eye-reliability ledger.
#
# The eye (gemma3:4b) is a WITNESS, not an instrument (eye-noise law,
# c19): a single anomalous read is noise until corroborated. This
# script's job is to make the eye's reliability COUNTABLE over time.
#
# Runs ON SOPHON as root (ssh bash -s -- /var/home/nacho/repos/
# iar-personalization). Read-only on frigate storage; writes ONLY to
# the repo's audit tree (ledger) and /tmp (frames).
#
# Anatomy: cheap (one ollama call per cam, ~1s each), stateless
# (state = ledger file), organ-class failure policy (never exit
# nonzero).
#
# Usage: eye-check.sh [PDIR]
#   PDIR default: inferred (repo = three levels up from script dir);
#   ssh 'bash -s' < runs have no script path -> pass PDIR explicitly.
# Output: $PDIR/audit/iar/aria/EYE-LEDGER.log (append-only)
#         stdout: one line per camera: CAM VERDICT detail
# Exit: ALWAYS 0.
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
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] eye-check: PDIR is not the repo ('${PDIR:-}') -- refusing ghost state" >&2
  exit 0
fi

LEDGER="$PDIR/audit/iar/aria/EYE-LEDGER.log"
PREVIEWS="/home/nacho/containers/frigate/storage/clips/previews"
FFMPEG="/usr/lib/ffmpeg/7.0/bin/ffmpeg"
OLLAMA="http://10.66.0.5:11434/api/generate"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

touch "$LEDGER" 2>/dev/null || exit 0

cams=$(ls "$PREVIEWS" 2>/dev/null) || cams=""
[ -z "$cams" ] && { echo "[$NOW] eye-check: no previews dir readable"; exit 0; }

for CAM in $cams; do
  LATEST=$(ls -t "$PREVIEWS/$CAM"/*.mp4 2>/dev/null | head -1)
  [ -z "$LATEST" ] && { echo "$CAM SKIP no-preview"; continue; }
  BASE=$(basename "$LATEST")
  CONTPATH="/media/frigate/clips/previews/$CAM/$BASE"
  # frame grab inside the container (rootless podman, user 1000)
  runuser -l nacho -c "podman exec frigate $FFMPEG -y -sseof -3 -i '$CONTPATH' -frames:v 1 /tmp/eyecheck.jpg" >/dev/null 2>&1
  runuser -l nacho -c "podman cp frigate:/tmp/eyecheck.jpg /tmp/eyecheck.jpg" >/dev/null 2>&1
  [ ! -s /tmp/eyecheck.jpg ] && { echo "$CAM FAIL frame-grab"; echo "[$NOW] $CAM FAIL frame-grab ($BASE)" >> "$LEDGER"; continue; }
  B64=$(base64 -w0 /tmp/eyecheck.jpg)
  RESP=$(curl -s --max-time 300 "$OLLAMA" -d "{\"model\":\"qwen3.6:35b-a3b\",\"prompt\":\"This is a security camera frame. Answer with ONLY the camera name it most likely shows, choosing from: front-door, backyard, driveway, street, balcony, living-room, bedroom, kitchen, garage, garden, other. One word or hyphenated pair, nothing else.\",\"images\":[\"$B64\"],\"stream\":false,\"keep_alive\":300}" | jq -r '.response' 2>/dev/null | tr -d '[:space:]' | head -c 40)
  # The eye answers with scene semantics, not frigate names -- the ledger
  # records the RAW read; identity-matching against expected scene is the
  # analyst's job (v1 keeps it honest, no auto-verdict).
  echo "[$NOW] $CAM READ:$RESP preview:$BASE" >> "$LEDGER"
  echo "$CAM READ:$RESP"
  rm -f /tmp/eyecheck.jpg
done
echo "[$NOW] eye-check done: ledger=$LEDGER"
exit 0