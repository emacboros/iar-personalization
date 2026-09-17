#!/bin/bash
# aria-segcensus-puller.sh v1.1 (2026-09-17, aria cycle 373)
# v1.1: producer probe -- appends per-camera go2rtc producer id +
# audio-track presence to producers.log each run. Producer ID is the
# only witness of replacement events (id change = replaced; id stable
# across hours = frozen in place, the ext2 19:32Z case where the
# producer kept SDP audio-yes while recordings went audio-dead).
# Reaches go2rtc via machinectl shell nacho@ (rootless podman; root
# cannot podman exec directly). Additive, reversible: rm producers.log
# + revert this block to undo.
# v1.0 (2026-09-16, aria cycle 373)
# -------------------------------------------------------------
# Hourly audio-segment census: counts segments with NO audio stream
# per camera for the PREVIOUS complete UTC hour.
#
# WHY (c372->c373): transient audio deaths (interior_1 class) heal in
# 10s-13min, inside the 6h fleet-check gap. The detector samples the
# 3 newest segments per run -- a freeze that heals within the gap is
# invisible. 2026-09-16: interior_1 had 287 dead segments across 12
# death blocks; fleet-check saw none of them. The census makes every
# hour's dead-segment count visible, so the detector (and a human
# reading the file) can see transients the probe misses.
#
# MECHANISM CONTEXT (unified producer-freeze class, c373):
#   go2rtc producer audio receiver freezes silently (video keeps
#   flowing, TCP read alive, no timeout); audio returns at the next
#   full-stream stall (read-timeout WRN, producer replacement).
#   interior_1 (.201) full-stalls ~100x/day -> freezes heal in
#   minutes. ext1/ext3 stall rarely -> freezes last hours. Same
#   mechanism, different stall cadence. See
#   knowledge/aria/audio-death-mechanism-2026-09-16.md
#
# DESIGN:
#   - Probes the PREVIOUS hour only: all segments complete, no
#     in-progress partial to avoid.
#   - ffprobe codec_type only (header parse, ~0.1s/seg), 8-way
#     parallel -> ~2500 segs/hour in ~40s.
#   - A segment with an audio stream but 0/1 packets (boundary stub)
#     reads as ALIVE here; the volumedetect probe in fleet-check
#     remains the verdict organ. This census is the longitudinal net.
#   - Appends one line per cam per run to /var/lib/aria-fleet/
#     segcensus/<cam>.log: "<epoch> <DAY/HOUR> <total> <dead>"
#   - Read-only toward recordings; writes only to its own dir.
#
# INSTALL (D-011 aria-reversible class: additive, reversible):
#   cp aria-segcensus.service /etc/systemd/system/
#   cp aria-segcensus.timer   /etc/systemd/system/
#   systemctl daemon-reload && systemctl enable --now aria-segcensus.timer
# UNDO: systemctl disable --now aria-segcensus.timer
#       rm /etc/systemd/system/aria-segcensus.{service,timer}
#       rm -rf /var/lib/aria-fleet/segcensus
# The ExecStart points at the REPO working tree on sophon
# (/var/home/nacho/repos/iar-personalization) -- version-in-git rule,
# same convention as aria-fleet-feed.sh.
# -------------------------------------------------------------
set -u

R=/home/nacho/containers/frigate/storage/recordings
OUT=/var/lib/aria-fleet/segcensus
CAMS="exterior_1 exterior_2 exterior_3 exterior_4 exterior_5 interior_1 interior_2 interior_3"

mkdir -p "$OUT" 2>/dev/null || { echo "segcensus: cannot create $OUT" >&2; exit 0; }

# previous COMPLETE UTC hour (avoids in-progress segments entirely)
H=$(date -u -d "1 hour ago" +%H)
DAY=$(date -u -d "1 hour ago" +%Y-%m-%d)
TS=$(date +%s)

for cam in $CAMS; do
  d="$R/$DAY/$H/$cam"
  total=0; dead=0
  if [ -d "$d" ]; then
    total=$(find "$d" -maxdepth 1 -name "*.mp4" 2>/dev/null | wc -l)
    if [ "$total" -gt 0 ]; then
      dead=$(find "$d" -maxdepth 1 -name "*.mp4" -print0 2>/dev/null | \
        xargs -0 -P 8 -n 1 sh -c \
          'ffprobe -v error -show_entries stream=codec_type -of csv "$1" 2>/dev/null | grep -q audio || echo X' _ | \
        wc -l)
    fi
  fi
  echo "$TS $DAY/$H $total $dead" >> "$OUT/$cam.log"
done
# --- producer probe (v1.1, aria c373): per-camera go2rtc producer id +
# audio-track presence, appended to producers.log. WHY: the audio-freeze
# class is invisible to recordings-only reads (producer SDP still says
# audio-yes); the producer ID is the only witness of replacement events
# (id changes = producer replaced; id stable across hours = frozen in
# place, the ext2 19:32Z case). One curl, ~10ms.
PROD_OUT="$OUT/producers.log"
PROD_JSON=$(machinectl shell nacho@ /bin/sh -c "podman exec frigate curl -s --max-time 4 http://localhost:1984/api/streams" 2>/dev/null \
  | grep -v "^Connected to" | grep -v "^Press" | grep -v "^Connection to")
if [ -n "$PROD_JSON" ]; then
  echo "$PROD_JSON" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sorted(d):
    v=d[k] or {}
    prods=v.get('producers') or []
    if prods:
        p=prods[0]
        sdp=p.get('sdp','') or ''
        aud='audio-yes' if 'm=audio' in sdp else 'audio-NO'
        print(k, p.get('id','-'), aud)
    else:
        print(k, '-', 'no-producer')
" | while read -r cam pid aud; do
      echo "$TS $DAY/$H $cam $pid $aud" >> "$PROD_OUT"
    done
else
  echo "$TS $DAY/$H probe-failed" >> "$PROD_OUT"
fi

exit 0