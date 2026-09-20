#!/bin/bash
# audio-transition-scan.sh v3 (aria c139) -- per-segment audio transition
# scan, fleet-wide. Changes vs v2 (c136):
#  - LOCKFILE (c137 law: second instance appeared alongside a nohup launch)
#  - PIDFILE for background runs (c137: pgrep -f self-match made liveness
#    polls vacuous; file growth is the real liveness proof)
#  - FRESHNESS GUARD (c138 scar: v2 read segcensus rows at scan time, so an
#    hour whose row landed AFTER scan start was missed by design; v3 only
#    probes hours whose row predates scan start)
#  - default window 24h (v2's 48h default produced 94 flagged hours and a
#    ~40min runtime; 24h keeps the cron cadence sane)
#  - per-cam parallelism (8 x &)
# Usage: audio-transition-scan.sh [hours] ; output: stdout (cron -> ats-latest)
set -u
LOCK=/tmp/ats.lock
exec 9>"$LOCK"
flock -n 9 || { echo "ats: another instance holds the lock, exiting"; exit 0; }
echo $$ > /tmp/ats.pid
R=/home/nacho/containers/frigate/storage/recordings
SC=/var/lib/aria-fleet/segcensus
NOW=$(date -u +%s); CUTOFF=$((NOW - ${1:-24}*3600))
SCANSTART=$NOW
echo "== audio-transition-scan v3 $(date -u +%Y-%m-%dT%H:%M:%SZ) window=${1:-24}h =="
for camlog in $SC/exterior_*.log $SC/interior_*.log; do
  cam=$(basename "$camlog" .log)
  ( # per-cam subshell, parallel
    awk -v cut=$CUTOFF -v start=$SCANSTART "\$1>=cut && \$1<start && \$4>0 {print \$2}" "$camlog" | while read -r DH; do
      DAY=${DH%/*}; H=${DH#*/}
      d="$R/$DAY/$H/$cam"
      [ -d "$d" ] || continue
      dead=""
      for f in $d/*.mp4; do
        ffprobe -v error -show_entries stream=codec_type -of csv "$f" 2>/dev/null | grep -q audio || dead="$dead $(basename $f .mp4)"
      done
      [ -n "$dead" ] && echo "$cam $DH:$dead"
    done
  ) &
done
wait
echo "== done $(date -u +%Y-%m-%dT%H:%M:%SZ) =="
rm -f /tmp/ats.pid
