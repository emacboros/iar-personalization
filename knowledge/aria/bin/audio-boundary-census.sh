#!/bin/bash
# audio-boundary-census.sh v1.0 (2026-09-22, aria cycle 206)
# -------------------------------------------------------------
# Batched per-hour-dir audio census: ONE ssh -> ONE podman exec per
# hour-dir -> inner ffprobe loop -> boundary map. Replaces the per-seg
# interactive probe walk that cost c200 150+ tool calls and manufactured
# a false dead wave (c205 PROBE-NONEXISTENT-FILE scar).
#
# WHY: the per-seg ffprobe loop is the primary instrument for the
# EPISODES lens (stall falsifier v3 field d) but was run interactively,
# one tool call per probe. This script batches the whole walk into one
# call and adds the existence check the scar demands: a segment that
# does not exist is MISSING, never "audio dead" (ffprobe on a missing
# file exits rc=0 with empty output).
#
# USAGE (from the cycle container):
#   ssh root@10.66.0.5 'bash -s' < audio-boundary-census.sh -- <cam> <date> <hour> [hour...]
#   or: bash audio-boundary-census.sh <cam> <date> <hour> [hour...]   (on sophon)
#
# OUTPUT per hour-dir:
#   == <cam> <date>/<hour>: total=N dead=D missing=M gaps=G longest=Ls ==
#   DEAD <first_seg>..<last_seg> (<n> segs, <secs>s)     one line per dead run
#   BLIP <seg> (<secs>)                                  alive seg inside a dead run
#   GAP  <prev_seg> -> <next_seg> (<secs>)               missing-file holes (recorder gap)
#   state lines: <seg> A|D|M                             (A=audio, D=dead-audio, M=missing)
#
# Ground truth (c205 ledger, must reproduce):
#   ext3 2026-09-21 h21: 78 dead (E1 00.12-15.55, E2 21.31-26.03), audio from 26.19
#   ext4 2026-09-21 h21: 8 dead (45.01-46.39), audio from 46.54
#   ext4 2026-09-22 h00: 0 dead, ONE recorder gap 51.17 -> 52.37 (80s)
#
# Read-only toward recordings; prints to stdout only. Reversible: delete file.
# -------------------------------------------------------------
set -u
R=/home/nacho/containers/frigate/storage/recordings
FFPROBE=/usr/lib/ffmpeg/7.0/bin/ffprobe
P=""

# detect podman socket (rootless frigate; c197 scar: runuser fails under
# root ssh, use --url). Only needed when ffprobe is not on the host PATH.
if ! command -v ffprobe >/dev/null 2>&1; then
  P="podman --url unix:///run/user/1000/podman/podman.sock"
fi

if [ "${1:-}" = "--" ]; then shift; fi
CAM="${1:-}"; DAY="${2:-}"; shift 2 2>/dev/null || { echo "usage: audio-boundary-census.sh [--] <cam> <date> <hour>..." >&2; exit 2; }
[ -n "$CAM" ] && [ -n "$DAY" ] || { echo "usage: audio-boundary-census.sh [--] <cam> <date> <hour>..." >&2; exit 2; }

probe_one() {
  # $1 = container path. Prints "A" (audio stream present), "D" (no audio
  # stream), or "M" (file missing -- PROBE-NONEXISTENT-FILE guard).
  local cp="$1" out rc
  if [ -n "$P" ]; then
    out=$($P exec frigate sh -c "test -f '$cp' || { echo MISSING; exit 0; }; $FFPROBE -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 '$cp'" 2>/dev/null)
  else
    [ -f "$cp" ] || { echo "M"; return; }
    out=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$cp" 2>/dev/null)
  fi
  case "$out" in
    MISSING) echo "M" ;;
    *audio*) echo "A" ;;
    *)       echo "D" ;;
  esac
}

seg_secs() {
  # MM.SS -> seconds
  local m=${1%%.*} s=${1#*.}
  echo $(( 10#$m * 60 + 10#$s ))
}

for H in "$@"; do
  d="$R/$DAY/$H/$CAM"
  echo "== $CAM $DAY/$H =="
  if [ ! -d "$d" ]; then echo "no dir $d"; continue; fi
  segs=(); states=""
  for f in $(ls "$d" 2>/dev/null | grep '\.mp4$' | sort); do
    segs+=("${f%.mp4}")
  done
  total=${#segs[@]}
  [ "$total" -eq 0 ] && { echo "no segments"; continue; }
  # probe all segs (inside the container when P is set: one exec per seg,
  # but the whole loop is ONE ssh call -- the batching that matters)
  i=0
  mapfile=""
  for s in "${segs[@]}"; do
    st=$(probe_one "$d/$s.mp4")
    echo "$s $st"
    mapfile="$mapfile$s $st\n"
    i=$((i+1))
  done
  # boundary analysis from the state lines just printed
  echo "$total segs; boundary analysis:"
  awk -v cam="$CAM" -v day="$DAY" -v hour="$H" '
    NF==2 && ($2=="A"||$2=="D"||$2=="M") { seg[++n]=$1; st[n]=$2 }
    END {
      dead=0; miss=0; gaps=0; runs=0; inrun=0; runstart=0; runend=0; runlen=0;
      longest=0; longstart=""; longend=""; blips=0; gapstart=""; gapend=""; gaplen=0; longestgap=0; longgapstart=""; longgapend="";
      for (i=1;i<=n;i++) {
        if (st[i]!="A") {
          if (st[i]=="D") dead++; else miss++;
          if (!inrun) { inrun=1; runstart=i; runlen=0; runs++ }
          runend=i; runlen++
        } else {
          if (inrun) {
            inrun=0
            if (runlen>longest) { longest=runlen; longstart=seg[runstart]; longend=seg[runend] }
          }
        }
      }
      if (inrun && runlen>longest) { longest=runlen; longstart=seg[runstart]; longend=seg[runend] }
      # blips: alive segs strictly inside a dead run
      inrun=0
      for (i=1;i<=n;i++) {
        if (st[i]!="A") { inrun=1; continue }
        if (inrun) { blips++; inrun=0 }
      }
      # missing-file gaps (recorder gaps): consecutive-name holes
      for (i=2;i<=n;i++) {
        split(seg[i-1],a,"."); split(seg[i],b,".")
        pa=a[1]*60+a[2]; pb=b[1]*60+b[2]
        dsec=pb-pa
        if (dsec>45) { gaps++; if (dsec>longestgap) { longestgap=dsec; longgapstart=seg[i-1]; longgapend=seg[i] } }
      }
      printf "summary: total=%d dead=%d missing=%d dead_runs>0=%d blips=%d name_gaps=%d longest_gap=%ds (%s->%s)\n", n, dead, miss, runs, blips, gaps, longestgap, longgapstart, longgapend
      if (longest>0) printf "longest_dead_run=%d segs (%s..%s)\n", longest, longstart, longend
    }' <<< "$(printf "$mapfile")" 
done
echo "== census done $(date -u +%Y-%m-%dT%H:%M:%SZ) =="