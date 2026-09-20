#!/bin/bash
# ats-fast.sh (aria c136) -- per-segment dead-census for ONE camera, flagged hours only
# usage: ats-fast.sh <cam> [hours-back]
R=/home/nacho/containers/frigate/storage/recordings
SC=/var/lib/aria-fleet/segcensus
cam="$1"; HRS="${2:-48}"
NOW=$(date -u +%s); CUTOFF=$((NOW - HRS*3600))
awk -v cut=$CUTOFF "\$1>=cut && \$4>0 {print \$2}" "$SC/$cam.log" | while read -r DH; do
  DAY=${DH%/*}; H=${DH#*/}
  d="$R/$DAY/$H/$cam"
  [ -d "$d" ] || continue
  dead=""
  for f in $d/*.mp4; do
    ffprobe -v error -show_entries stream=codec_type -of csv "$f" 2>/dev/null | grep -q audio || dead="$dead $(basename $f .mp4)"
  done
  [ -n "$dead" ] && echo "$cam $DH:$dead"
done
