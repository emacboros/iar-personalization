#!/bin/bash
# audio-transition-scan.sh v2 (aria c136) -- per-segment transition timing
# within segcensus-FLAGGED hours only (dead>0). v1 scanned all 48h per-segment
# and blew a 280s timeout; v2 reads /var/lib/aria-fleet/segcensus/*.log to find
# flagged hours, then ffprobes only those segments. Fast (~15 flagged hours).
R=/home/nacho/containers/frigate/storage/recordings
SC=/var/lib/aria-fleet/segcensus
NOW=$(date -u +%s); CUTOFF=$((NOW - ${1:-48}*3600))
echo "== audio-transition-scan v2 $(date -u +%Y-%m-%dT%H:%M:%SZ) =="
for camlog in $SC/exterior_*.log $SC/interior_*.log; do
  cam=$(basename "$camlog" .log)
  awk -v cut=$CUTOFF "\$1>=cut && \$4>0 {print \$2}" "$camlog" | while read -r DH; do
    DAY=${DH%/*}; H=${DH#*/}
    d="$R/$DAY/$H/$cam"
    [ -d "$d" ] || continue
    dead=""
    for f in $d/*.mp4; do
      ffprobe -v error -show_entries stream=codec_type -of csv "$f" 2>/dev/null | grep -q audio || dead="$dead $(basename $f .mp4)"
    done
    [ -n "$dead" ] && echo "$cam $DH:$dead"
  done
done
echo "== done =="
