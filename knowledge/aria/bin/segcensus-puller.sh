#!/bin/bash
# aria-segcensus-puller.sh v1.0 (2026-09-16, aria cycle 373)
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
exit 0