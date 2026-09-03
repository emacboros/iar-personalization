#!/bin/bash
# segment-scan.sh -- one-ssh segment composition scan for a camera's day.
# Prints the audio/video boundary in ONE pass (binary walk per hour, one ssh).
# Usage: ssh root@10.66.0.5 'bash -s' < segment-scan.sh <camera> <date>
#   camera: frigate camera name (e.g. exterior_3)
#   date:   YYYY-MM-DD (default: today)
# Output: per-hour first/last segment audio state + pinned boundary when found.
# Scar 46 instrument: silent track loss is witnessed only by output artifacts.
# This script is the batched version of the per-segment ffprobe walk that
# burned the cycle-33 tool cap.
CAM="${1:-exterior_3}"
DATE="${2:-$(date -u +%Y-%m-%d)}"
BASE=/home/nacho/containers/frigate/storage/recordings/$DATE
HOURS=$(ls $BASE 2>/dev/null | sort -n)
if [ -z "$HOURS" ]; then echo "no recordings for $DATE"; exit 1; fi
for h in $HOURS; do
  D=$BASE/$h/$CAM
  [ -d "$D" ] || { echo "hour $h: no dir"; continue; }
  files=($(ls $D 2>/dev/null | sort -n))
  n=${#files[@]}
  [ $n -eq 0 ] && { echo "hour $h: empty"; continue; }
  # probe first and last segment of the hour
  first=$(timeout 10 ffprobe -v error -select_streams a -show_entries stream=codec_name -of csv=p=0 "$D/${files[0]}" 2>/dev/null)
  last=$(timeout 10 ffprobe -v error -select_streams a -show_entries stream=codec_name -of csv=p=0 "$D/${files[$((n-1))]}" 2>/dev/null)
  if [ "$first" = "$last" ]; then
    echo "hour $h: uniform audio=$first ($n segs)"
  else
    # binary walk inside the hour to pin the boundary
    lo=0; hi=$n
    while [ $lo -lt $hi ]; do
      mid=$(( (lo+hi)/2 ))
      N=$(timeout 10 ffprobe -v error -select_streams a -show_entries stream=codec_name -of csv=p=0 "$D/${files[$mid]}" 2>/dev/null)
      if [ "$N" = "aac" ]; then lo=$((mid+1)); else hi=$mid; fi
    done
    if [ $lo -eq 0 ]; then
      echo "hour $h: MIXED start video-only, first audio at ${files[0]}..? ($n segs)"
    elif [ $lo -ge $n ]; then
      echo "hour $h: MIXED start audio, no video-only ($n segs)"
    else
      echo "hour $h: BOUNDARY last-audio=${files[$((lo-1))]} first-video-only=${files[$lo]} ($n segs)"
    fi
  fi
done