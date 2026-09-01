#!/bin/bash
# aria fleet-check v2.2 (2026-09-01, interactive session)
# -------------------------------------------------------------
# One-command per-cycle patrol: /dev/null canary + ear check v2 +
# identity watch. Runs ON sophon as root. Executed from the i.ar
# container via:
#   ssh root@10.66.0.5 'bash -s' < fleet-check.sh
# The version in git IS the running version -- no copy on sophon.
#
# v2.2: (a) /dev/null canary -- the 2026-09-01 incident: /dev/null
# became a regular file (tclass=file, ino 2495) during boot -2;
# sshd, podman/pasta, systemd, nft all degraded silently for
# hours. A stat is cheaper than the outage it detects. (b) eye
# model downgraded gemma4:31b -> gemma3:4b: the frigate GPU
# detector (cycle 64) permanently took ~3.4 GiB; 31B (19.1 GiB)
# no longer fits and every first-load after eviction segfaulted
# llama-server (13 SIGSEGV cores, cycle 66). gemma3:4b loads in
# ~4s into the remaining slack and reads overlays. Organs share
# a body now; the eye sized itself to the space that exists.
#
# v2.1: vision call retries on HTTP 5xx (kept for the 4b too --
# eviction can still happen if ollama loads something big).
#
# Checks:
#   0. /dev/null CANARY: must be char device 1:3. Anything else
#      = the incident class; flag loudly.
#   1. EAR CHECK v2: per camera, newest recording segment ->
#      age (STALE if >120s) + audio track presence + volume.
#   2. IDENTITY WATCH: direct RTSP grab of .101 vs frigate's own
#      newest exterior_1 segment tail -> vision-read both overlays
#      (gemma3:4b, think off) -> MATCH / RACE / VISION-UNCLEAR.
#      This failure class (same IP, two cameras, session-age
#      decides) is invisible to metadata instruments. Pixels only.
#   3. ARP: are .103/.104 reachable (cameras staying home)?
#
# Exit: 0 = all green, 1 = anything flagged. Output is compact,
# one line per camera + verdict lines. Cleanup: temp jpgs removed
# same-run (container /tmp and storage bind).
# ------------------------------------------------------------
set -u
R=/home/nacho/containers/frigate/storage/recordings
P="podman --url unix:///run/user/1000/podman/podman.sock"
TODAY=$(date -u +%Y-%m-%d)
FAIL=0
CAMERAS="exterior_1 exterior_2 exterior_3 exterior_4 exterior_5 interior_1 interior_2 interior_3"

echo "== fleet-check $TODAY $(date -u +%H:%M:%S) UTC =="

# --- 0. /dev/null canary (2026-09-01 incident class) ---
echo "-- /dev/null canary --"
nulf=$(stat -c '%F' /dev/null 2>/dev/null)
nudev=$(stat -c '%t:%T' /dev/null 2>/dev/null)
if [ "$nulf" != "character special file" ] || [ "$nudev" != "1:3" ]; then
  echo "/dev/null BROKEN: ${nulf:-missing} dev=${nudev:-none} -- sshd/podman/systemd degrade silently when this is wrong"
  FAIL=1
else
  echo "/dev/null ok (char 1:3)"
fi

# --- 1. EAR CHECK v2 (age + audio) ---
echo "-- ear check --"
for cam in $CAMERAS; do
  n=$(find $R/$TODAY -path "*$cam*" -name "*.mp4" 2>/dev/null | sort | tail -1)
  if [ -z "$n" ]; then echo "$cam NO-SEGMENT"; FAIL=1; continue; fi
  age=$(( $(date +%s) - $(stat -c %Y "$n") ))
  if [ "$age" -gt 120 ]; then echo "$cam STALE(${age}s)"; FAIL=1; fi
  # audio: map 0:a fails on video-only segments -> NO-AUDIO
  aout=$(timeout 30 ffmpeg -hide_banner -i "$n" -map 0:a -af volumedetect -f null - 2>&1)
  if echo "$aout" | grep -q "matches no streams"; then
    echo "$cam age=${age}s NO-AUDIO"; FAIL=1
  else
    v=$(echo "$aout" | grep -oE "\-?[0-9.]+ dB" | head -2 | tr '\n' ' ')
    echo "$cam age=${age}s mean/max: $v"
  fi
done

# --- 2. IDENTITY WATCH (pixels, not metadata) ---
echo "-- identity watch --"
WDIR=/tmp/aria-watch
$P exec frigate sh -c "mkdir -p $WDIR && rm -f $WDIR/*.jpg /media/frigate/aria_watch_*.jpg 2>/dev/null" 2>/dev/null

# 2a. direct grab of .101 (container ffmpeg: host ffmpeg lacks hevc)
grab=$($P exec frigate sh -c "timeout 25 /usr/lib/ffmpeg/7.0/bin/ffmpeg -y -loglevel error -rtsp_transport tcp -i 'rtsp://thingino:thingino@192.168.2.101/ch0' -frames:v 1 $WDIR/direct.jpg && cp $WDIR/direct.jpg /media/frigate/aria_watch_direct.jpg && echo OK" 2>/dev/null)
if [ "$grab" != "OK" ]; then echo "DIRECT-GRAB FAIL (is .101 up?)"; FAIL=1; fi

# 2b. ext1 newest segment tail (host path -> container path)
n=$(find $R/$TODAY -path "*exterior_1*" -name "*.mp4" 2>/dev/null | sort | tail -1)
if [ -n "$n" ]; then
  nc="${n/\/home\/nacho\/containers\/frigate\/storage//media/frigate}"
  tail=$($P exec frigate sh -c "timeout 25 /usr/lib/ffmpeg/7.0/bin/ffmpeg -y -loglevel error -sseof -2 -i '$nc' -frames:v 1 $WDIR/seg.jpg && cp $WDIR/seg.jpg /media/frigate/aria_watch_seg.jpg && echo OK" 2>/dev/null)
  [ "$tail" != "OK" ] && { echo "SEG-TAIL FAIL"; FAIL=1; }
else
  echo "SEG-TAIL FAIL (no ext1 segment)"; FAIL=1
fi

# 2c. vision read both frames, compare overlay cam names
if [ "$grab" = "OK" ] && [ "${tail:-}" = "OK" ]; then
  python3 - <<'EOF'
import base64, json, re, sys, time, urllib.request, urllib.error
def look(path):
    img = base64.b64encode(open(path, "rb").read()).decode()
    req = urllib.request.Request("http://127.0.0.1:11434/api/chat",
        data=json.dumps({"model": "gemma3:4b", "stream": False, "think": False,
            "options": {"num_predict": 120},
            "messages": [{"role": "user",
              "content": "Security camera frame. Quote the overlay text exactly (camera name and timestamp). Then one sentence of scene.",
              "images": [img]}]}).encode(),
        headers={"Content-Type": "application/json"})
    r = json.load(urllib.request.urlopen(req, timeout=300))
    return r["message"]["content"]
def look_retry(path, tries=3):
    last = None
    for i in range(tries):
        try:
            return look(path)
        except urllib.error.HTTPError as e:
            last = e
            time.sleep(10)  # ollama reload after eviction takes ~10-20s
    raise last
try:
    d = look_retry("/home/nacho/containers/frigate/storage/aria_watch_direct.jpg")
    s = look_retry("/home/nacho/containers/frigate/storage/aria_watch_seg.jpg")
    dc = re.findall(r"cam\d+-\d+", d, re.I)
    sc = re.findall(r"cam\d+-\d+", s, re.I)
    print("direct overlay:", d.replace("\n", " ")[:120])
    print("segment overlay:", s.replace("\n", " ")[:120])
    if dc and sc:
        if dc[0].lower() == sc[0].lower():
            print(f"VERDICT: MATCH ({dc[0]}) -- no race")
        else:
            print(f"VERDICT: RACE -- direct={dc[0]} frigate={sc[0]}")
            sys.exit(1)
    else:
        print("VERDICT: VISION-UNCLEAR (no overlay name parsed)")
        sys.exit(1)
except Exception as e:
    print(f"VERDICT: VISION-FAIL ({e})")
    sys.exit(1)
EOF
  [ $? -ne 0 ] && FAIL=1
fi

# cleanup: same-run, both sides
$P exec frigate sh -c "rm -f $WDIR/*.jpg /media/frigate/aria_watch_*.jpg" 2>/dev/null

# --- 3. ARP: are the resurrected cameras staying? ---
echo "-- arp --"
ip neigh show | grep -E "192\.168\.2\.10[034]" || echo "no ARP entries for .100/.103/.104"

echo "== fleet-check done (FAIL=$FAIL) =="
exit $FAIL