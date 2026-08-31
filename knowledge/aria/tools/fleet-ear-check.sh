#!/usr/bin/env bash
# fleet-ear-check.sh -- Aria's camera fleet health check.
# Checks AGE + CONTENT + AUDIO for all 8 frigate cameras.
#
# Usage (from anywhere with ssh to sophon):
#   ssh root@10.66.0.5 'bash -s' < fleet-ear-check.sh
#
# Exit 0 = all green, 1 = any anomaly.
#
# History:
#   v1 (2026-08-31, cycles 49-52): content check only (streams + volume).
#   v2 (2026-08-31, cycle 54): AGE check added. Cycle 53's false green:
#      newest-segment content was valid but 30 min old (cams dead).
#      Stale-but-valid data reads healthy forever. Age > 2 min = event.
set -u

SOCK="unix:///run/user/1000/podman/podman.sock"
STOR=/home/nacho/containers/frigate/storage/recordings
FF=/usr/lib/ffmpeg/7.0/bin
AGE_LIMIT=2   # minutes; anything older is itself an event (cycle 53)

PID=$(podman --url "$SOCK" inspect frigate --format '{{.State.Pid}}' 2>/dev/null)
if [ -z "$PID" ]; then echo "frigate container not found"; exit 1; fi

NOW=$(date +%s)
TODAY=$(date -u +%Y-%m-%d)
YDAY=$(date -u -d yesterday +%Y-%m-%d)
ANOM=0

for cam in exterior_1 exterior_2 exterior_3 exterior_4 exterior_5 \
           interior_1 interior_2 interior_3; do
  f=$(find "$STOR/$TODAY" "$STOR/$YDAY" -path "*/$cam/*" -name '*.mp4' \
        -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -z "$f" ]; then
    echo "$cam: NO-SEGMENTS (last 48h)"
    ANOM=1
    continue
  fi

  mt=$(stat -c %Y "$f")
  age=$(( (NOW - mt) / 60 ))
  fc=$(echo "$f" | sed 's|^/home/nacho/containers/frigate/storage|/media/frigate|')

  streams=$(nsenter -t "$PID" -m -- "$FF/ffprobe" -v error \
              -show_entries stream=codec_type -of csv=p=0 "$fc" 2>/dev/null \
              | tr '\n' ',' | sed 's/,$//')

  vol=$(nsenter -t "$PID" -m -- "$FF/ffmpeg" -hide_banner -t 2 -i "$fc" \
          -af volumedetect -f null - 2>&1 \
          | grep -E 'mean_volume|max_volume' | awk '{print $5}' | tr '\n' '/')

  status="OK"
  if [ "$age" -gt "$AGE_LIMIT" ]; then
    status="STALE(${age}m>$(printf '%02d' $AGE_LIMIT)m)"
    ANOM=1
  fi
  case "$streams" in
    *audio*) : ;;
    *) status="$status NO-AUDIO"; ANOM=1 ;;
  esac

  echo "$cam: $status | streams=$streams | vol=$vol | age=${age}m"
done

echo "ANOMALIES=$ANOM"
exit $ANOM