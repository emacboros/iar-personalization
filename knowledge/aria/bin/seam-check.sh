#!/usr/bin/env bash
# seam-check.sh -- scan RSSI series for reboot seams.
#
# Built 2026-09-11 (aria c216) BEFORE the 09-11/12 reboot window
# (01:00-06:00 -03) so the post-reboot read is one command, not an
# improvised investigation (law: instruments before perishable events).
#
# Input: directory of <ip>.log files. Each line: <epoch> <rssi> <uptime_s>
#   epoch/rssi/uptime are written by the camera (thingino cron, c202),
#   appended to sophon by the puller every 15 min (c209).
#
# Signal classes:
#   SEAM      uptime_new < uptime_prev - 60   -> camera rebooted between
#                                                samples (uptime reset).
#   GAP       epoch_new - epoch_prev > 2400   -> samples missing (camera
#                                                or puller down >= 2
#                                                intervals). Legit but
#                                                reported.
#   CLOCKJUMP epoch_new < epoch_prev - 300    -> camera clock jumped back
#                                                (boot-disparity line,
#                                                c196: exactly one per
#                                                reboot, then ntpd syncs).
#
# Expected post-reboot pattern per rebooted camera:
#   /var/rssi.log PERSISTED on camera -> CLOCKJUMP + SEAM, no gap.
#   /var/rssi.log WIPED (tmpfs)       -> GAP + fresh low uptimes (which
#                                        also reads as a SEAM at the
#                                        first post-gap sample).
# Distinguishing which: check camera-side first line via thingino API
# (recipe in ROADMAP RECIPES) -- this script is the sophon-side half.
#
# Usage: seam-check.sh [rssi_dir] [gap_threshold_s]
# Exit: 0 = clean (no seams/clockjumps), 1 = any seam or clockjump.
#       Gaps alone do not set exit 1.
# All timestamps printed in UTC (c186 law: normalize before comparing).

set -u
DIR="${1:-/var/lib/aria-fleet/rssi}"
GAP_THRESH="${2:-2400}"

if [ ! -d "$DIR" ]; then
    echo "seam-check: no such directory: $DIR" >&2
    exit 2
fi

total_seams=0
total_jumps=0
total_gaps=0
files_scanned=0

for f in "$DIR"/*.log; do
    [ -f "$f" ] || continue
    files_scanned=$((files_scanned + 1))
    ip=$(basename "$f" .log)

    # Single awk pass: seams, gaps, clockjumps. pu/pe = prev uptime/epoch.
    report=$(awk -v gapthresh="$GAP_THRESH" '
        NR == 1 { pe = $1; pu = $3; next }
        {
            de = $1 - pe
            if ($3 + 0 < pu - 60) {
                seams++
                printf "  SEAM line %d: uptime %d -> %d (epoch %s = %s UTC)\n", \
                    NR, pu, $3, $1, strftime("%Y-%m-%d %H:%M:%S", $1, 1)
            }
            if (de > gapthresh) {
                gaps++
                printf "  GAP line %d: %d s between samples (epoch %s = %s UTC)\n", \
                    NR, de, $1, strftime("%Y-%m-%d %H:%M:%S", $1, 1)
            }
            if ($1 + 0 < pe - 300) {
                jumps++
                printf "  CLOCKJUMP line %d: epoch %s -> %s (clock went back %d s)\n", \
                    NR, pe, $1, pe - $1
            }
            pe = $1; pu = $3
        }
        END { printf "%d %d %d %d\n", NR, seams, gaps, jumps }
    ' "$f")

    summary=$(echo "$report" | tail -1)
    detail=$(echo "$report" | sed '$d')
    samples=$(echo "$summary" | awk '{print $1}')
    seams=$(echo "$summary" | awk '{print $2}')
    gaps=$(echo "$summary" | awk '{print $3}')
    jumps=$(echo "$summary" | awk '{print $4}')

    total_seams=$((total_seams + seams))
    total_gaps=$((total_gaps + gaps))
    total_jumps=$((total_jumps + jumps))

    printf '%s: samples=%s seams=%s gaps=%s clockjumps=%s\n' \
        "$ip" "$samples" "$seams" "$gaps" "$jumps"
    [ -n "$detail" ] && printf '%s\n' "$detail"
done

echo "---"
printf 'seam-check: %d files, seams=%d gaps=%d clockjumps=%d\n' \
    "$files_scanned" "$total_seams" "$total_gaps" "$total_jumps"

if [ "$total_seams" -gt 0 ] || [ "$total_jumps" -gt 0 ]; then
    exit 1
fi
exit 0