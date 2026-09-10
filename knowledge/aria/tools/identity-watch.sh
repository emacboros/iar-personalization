#!/usr/bin/env bash
# identity-watch.sh -- Aria's camera identity-theft watch (standing instrument).
#
# WHY THIS EXISTS (cycles 56-58, 2026-08-31):
#   Two config-reset cameras raced a live camera for IP .101. Frigate's
#   established RTSP session kept recording cam2-1 while NEW connections
#   got cam2-3. Pipeline green, data well-formed, CONTENT WRONG. This
#   failure class is invisible to every metadata instrument (age, streams,
#   volume) -- only pixels can catch it. Protocol: per cycle, one direct
#   grab of .101 + one frigate segment tail, compare overlay names.
#
# WHAT IT DOES:
#   1. Grabs the newest exterior_1 recording segment (frigate's view).
#   2. Makes a FRESH direct RTSP connection to 192.168.2.101 (a new
#      connection -- the thing that would lose the race).
#   3. Reads the overlay camera name from both frames (gemma3:4b vision).
#   4. WATCH: OK if names agree; MISMATCH if they differ; UNKNOWN if the
#      name can't be read (fail visible, never fail silent).
#   Advisory: overlay date != today on either frame = CLOCK-ANOMALY note
#   (firmware-epoch clock = config-loss marker, cycle 55).
#
# Usage: bash identity-watch.sh
# Exit 0 = OK, 1 = mismatch/unknown/infrastructure failure.
#
# Recipe notes (paid-for knowledge, do not re-derive):
#   - Host sophon ffmpeg has NO hevc decoder. Direct grab must use
#     `-c:v copy -f hevc` to a file, then decode with the FRIGATE
#     CONTAINER's ffmpeg (nsenter), staging the hevc through frigate
#     storage (container sees it at /media/frigate/...).
#   - Frigate segment paths: host /home/nacho/containers/frigate/storage
#     = container /media/frigate.
#   - Rootless frigate: podman --url unix:///run/user/1000/podman/podman.sock.
#   - `-f mjpeg -` needs `-f mjpeg -` (not image2pipe) with this ffmpeg
#     build; output redirect happens host-side so the jpg lands in /tmp.
set -u

KH=/tmp/aria_known_hosts
SSH="ssh -i /root/.ssh/id_ed25519 -o UserKnownHostsFile=$KH -o StrictHostKeyChecking=yes"
SCP="scp -i /root/.ssh/id_ed25519 -o UserKnownHostsFile=$KH -o StrictHostKeyChecking=yes"
HOST=root@10.66.0.5
SOCK="unix:///run/user/1000/podman/podman.sock"
STOR=/home/nacho/containers/frigate/storage
FF=/usr/lib/ffmpeg/7.0/bin
CAM_IP=192.168.2.101
CAM_NAME=exterior_1
MODEL=qwen3.6:35b-a3b

# Reseed host key if /tmp is fresh (keyscan output IS known_hosts format;
# sophon's key verified out-of-band 2026-08-31).
[ -s "$KH" ] || ssh-keyscan -T 5 10.66.0.5 > "$KH" 2>/dev/null

TODAY=$(date -u +%Y-%m-%d)
ANOM=0

# ---------- 1. frigate segment tail ----------
SEG_JPG=/tmp/aria_watch_seg.jpg
rm -f "$SEG_JPG"
$SSH "$HOST" '
  STOR='"$STOR"'; SOCK='"$SOCK"'; FF='"$FF"'; CAM='"$CAM_NAME"'
  f=$(find "$STOR/recordings/$(date -u +%Y-%m-%d)" -path "*/$CAM/*" \
        -name "*.mp4" -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1 | cut -d" " -f2-)
  if [ -z "$f" ]; then echo "NO-SEGMENT"; exit 1; fi
  fc=$(echo "$f" | sed "s|^$STOR|/media/frigate|")
  PID=$(podman --url "$SOCK" inspect frigate --format "{{.State.Pid}}")
  nsenter -t "$PID" -m -- "$FF/ffmpeg" -hide_banner -loglevel error \
    -i "$fc" -frames:v 1 -f mjpeg - > /tmp/aria_watch_seg.jpg 2>/dev/null
' > /dev/null 2>&1
if [ -s /dev/null ]; then :; fi
$SCP -q "$HOST:/tmp/aria_watch_seg.jpg" "$SEG_JPG" 2>/dev/null
if [ ! -s "$SEG_JPG" ]; then
  echo "segment: GRAB-FAILED"
  ANOM=1
fi

# ---------- 2. direct grab (fresh connection = the race loser's path) ----------
DIR_JPG=/tmp/aria_watch_direct.jpg
rm -f "$DIR_JPG"
$SSH "$HOST" '
  STOR='"$STOR"'; SOCK='"$SOCK"'; FF='"$FF"'; IP='"$CAM_IP"'
  mkdir -p "$STOR/tmp_aria_watch"
  ffmpeg -hide_banner -loglevel error -rtsp_transport tcp \
    -i "rtsp://thingino:thingino@'"$CAM_IP"'/ch0" \
    -frames:v 1 -c:v copy -f hevc - > "$STOR/tmp_aria_watch/direct.hevc" 2>/dev/null
  rc=$?
  if [ $rc -ne 0 ] || [ ! -s "$STOR/tmp_aria_watch/direct.hevc" ]; then
    rm -rf "$STOR/tmp_aria_watch"; echo "RTSP-FAILED($rc)"; exit 1
  fi
  PID=$(podman --url "$SOCK" inspect frigate --format "{{.State.Pid}}")
  nsenter -t "$PID" -m -- "$FF/ffmpeg" -hide_banner -loglevel error \
    -i /media/frigate/tmp_aria_watch/direct.hevc -frames:v 1 -f mjpeg - \
    > /tmp/aria_watch_direct.jpg 2>/dev/null
  rm -rf "$STOR/tmp_aria_watch"
' > /dev/null 2>&1
$SCP -q "$HOST:/tmp/aria_watch_direct.jpg" "$DIR_JPG" 2>/dev/null
if [ ! -s "$DIR_JPG" ]; then
  echo "direct: GRAB-FAILED"
  ANOM=1
fi

# ---------- 3. vision: read overlay names ----------
read_overlay() {
  # $1 = jpg path; prints "NAME|TS" or "UNREADABLE|"
  python3 - "$1" "$MODEL" <<'PYEOF'
import json, sys, re, base64, urllib.request
jpg, model = sys.argv[1], sys.argv[2]
data = base64.b64encode(open(jpg, 'rb').read()).decode()
req = urllib.request.Request('http://localhost:11434/api/generate',
    data=json.dumps({'model': model, 'keep_alive': 300,
        'prompt': 'Read the overlay text on this security camera frame. Reply in exactly this format: NAME=<camera name> DATE=<YYYY-MM-DD> TIME=<HH:MM:SS>',
        'images': [data], 'stream': False, 'options': {'num_predict': 60}}).encode(),
    headers={'Content-Type': 'application/json'})
try:
    r = json.loads(urllib.request.urlopen(req, timeout=300).read())['response']
    name = re.search(r'cam2-\d+', r)
    ts = re.search(r'20\d\d-\d\d-\d\d', r)
    print((name.group(0) if name else 'UNREADABLE') + '|' + (ts.group(0) if ts else ''))
except Exception:
    print('UNREADABLE|')
PYEOF
}

SEG_READ="UNREADABLE|"; DIR_READ="UNREADABLE|"
[ -s "$SEG_JPG" ] && SEG_READ=$(read_overlay "$SEG_JPG")
[ -s "$DIR_JPG" ] && DIR_READ=$(read_overlay "$DIR_JPG")

SEG_NAME=${SEG_READ%%|*}; SEG_DATE=${SEG_READ#*|}
DIR_NAME=${DIR_READ%%|*}; DIR_DATE=${DIR_READ#*|}

echo "segment: name=$SEG_NAME date=$SEG_DATE"
echo "direct:  name=$DIR_NAME date=$DIR_DATE"

# ---------- 4. verdict ----------
if [ "$SEG_NAME" = "UNREADABLE" ] || [ "$DIR_NAME" = "UNREADABLE" ]; then
  echo "WATCH: UNKNOWN (overlay unreadable -- look by hand, never assume)"
  ANOM=1
elif [ "$SEG_NAME" = "$DIR_NAME" ]; then
  echo "WATCH: OK (identities agree: $SEG_NAME)"
else
  echo "WATCH: MISMATCH (segment=$SEG_NAME direct=$DIR_NAME -- IDENTITY THEFT: .101 is raced again)"
  ANOM=1
fi

# Advisory: firmware-epoch clock = config-loss marker (cycle 55)
for d in "$SEG_DATE" "$DIR_DATE"; do
  if [ -n "$d" ] && [ "$d" != "$TODAY" ]; then
    echo "CLOCK-ANOMALY: overlay date $d != today $TODAY (config-loss marker?)"
  fi
done

exit $ANOM