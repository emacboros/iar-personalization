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
#
# v2 (cycle 37): island detection. v1 probed only first/last per hour, so a
# loss+heal BOTH inside one hour (first==last, island in the middle) printed
# "uniform" and the boundary was invisible. v2 adds one middle probe on
# uniform hours; if the middle differs, binary walks pin both island edges.
# v2.1 (same cycle): the first v2 validation run caught two inverted-bound
# bugs (walks returned upper bounds, mislabeling hour 04's known 04:27
# boundary) -- differential law in action: same day through v1 and v2.
# v2.1 walks lower bounds with post-walk sanity checks; non-monotone hours
# (heal flaps) print MIXED-non-monotone instead of a confident wrong edge.
# Known blind spots (documented, accepted):
#   - an island that does not contain the hour's middle segment
#   - two or more islands in one hour (walks go non-monotone; flagged)
# Both require loss+heal twice inside 60 minutes -- not yet observed.
CAM="${1:-exterior_3}"
DATE="${2:-$(date -u +%Y-%m-%d)}"
BASE=/home/nacho/containers/frigate/storage/recordings/$DATE
HOURS=$(ls $BASE 2>/dev/null | sort -n)
if [ -z "$HOURS" ]; then echo "no recordings for $DATE"; exit 1; fi

probe() { timeout 10 ffprobe -v error -select_streams a -show_entries stream=codec_name -of csv=p=0 "$1" 2>/dev/null; }
label() { if [ -z "$1" ]; then echo "video-only"; else echo "$1"; fi; }

for h in $HOURS; do
  D=$BASE/$h/$CAM
  [ -d "$D" ] || { echo "hour $h: no dir"; continue; }
  files=($(ls $D 2>/dev/null | sort -n))
  n=${#files[@]}
  [ $n -eq 0 ] && { echo "hour $h: empty"; continue; }
  first=$(probe "$D/${files[0]}")
  last=$(probe "$D/${files[$((n-1))]}")
  F=$(label "$first"); L=$(label "$last")
  if [ "$first" != "$last" ]; then
    # monotone transition assumed: lower bound of "codec != first"
    lo=0; hi=$n
    while [ $lo -lt $hi ]; do
      mid=$(( (lo+hi)/2 ))
      N=$(probe "$D/${files[$mid]}")
      if [ "$N" != "$first" ]; then hi=$mid; else lo=$((mid+1)); fi
    done
    # sanity: files[lo] must differ from first, files[lo-1] must equal first
    if [ $lo -ge $n ] || [ $lo -eq 0 ]; then
      echo "hour $h: MIXED non-monotone (flap?) edges $F->$L ($n segs)"
    else
      plo=$(probe "$D/${files[$lo]}"); plo_prev=$(probe "$D/${files[$((lo-1))]}")
      if [ "$plo" = "$first" ] || [ "$plo_prev" != "$first" ]; then
        echo "hour $h: MIXED non-monotone (flap?) edges $F->$L ($n segs)"
      else
        echo "hour $h: BOUNDARY last-$F=${files[$((lo-1))]} first-$L=${files[$lo]} ($n segs)"
      fi
    fi
  else
    # uniform at the edges: one middle probe to catch a same-hour island
    mid_idx=$(( n/2 ))
    mid=$(probe "$D/${files[$mid_idx]}")
    if [ "$mid" = "$first" ]; then
      echo "hour $h: uniform $F ($n segs)"
    else
      M=$(label "$mid")
      # island: entry edge = lower bound of "!= first" in left half
      lo=0; hi=$mid_idx
      while [ $lo -lt $hi ]; do
        m2=$(( (lo+hi)/2 ))
        N=$(probe "$D/${files[$m2]}")
        if [ "$N" != "$first" ]; then hi=$m2; else lo=$((m2+1)); fi
      done
      island_start=$lo
      # exit edge = lower bound of "== first" in right half (return point)
      lo=$mid_idx; hi=$n
      while [ $lo -lt $hi ]; do
        m2=$(( (lo+hi)/2 ))
        N=$(probe "$D/${files[$m2]}")
        if [ "$N" = "$first" ]; then hi=$m2; else lo=$((m2+1)); fi
      done
      island_end=$((lo-1))
      # sanity both edges
      ok=1
      [ "$(probe "$D/${files[$island_start]}")" = "$first" ] && ok=0
      [ "$(probe "$D/${files[$island_end]}")" = "$first" ] && ok=0
      if [ $ok -eq 0 ]; then
        echo "hour $h: ISLAND non-monotone (flap?) around $M ($n segs)"
      else
        echo "hour $h: ISLAND $M gap ${files[$island_start]}..${files[$island_end]} ($n segs)"
      fi
    fi
  fi
done