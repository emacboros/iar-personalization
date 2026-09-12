#!/bin/bash
# nic-window-stats.sh v2 (2026-09-12, aria c243) -- RX/TX split.
# v1 (c239) computed Mbps from $3 only (RX); a TX-heavy saturation
# event would have been invisible. v2 reports both legs + total.
# Field order (law-50 COLUMN): <epoch> <speed> <rx_bytes> <tx_bytes>.
# Usage: nic-window-stats.sh START_EPOCH END_EPOCH [--force]
# Guards baked in: UNITS (Mbps = Mbit/s), READ-HOUR (refuses future
# windows unless --force; partial reads are labeled), no strftime in
# outputs (epochs only -- TZ-suffix family, 5 sightings).
F=/var/lib/aria-fleet/nic/enp10s0.log
S=$1; E=$2; FORCE=$3
if [ -z "$S" ] || [ -z "$E" ]; then
  echo "usage: $0 START_EPOCH END_EPOCH [--force]" >&2
  exit 2
fi
if [ ! -r "$F" ]; then
  echo "REFUSED: $F missing or unreadable" >&2
  exit 5
fi
NOW=$(date +%s)
if [ "$E" -gt "$NOW" ] && [ "$FORCE" != "--force" ]; then
  echo "REFUSED: end epoch $E is in the future (now $NOW)." >&2
  echo "Window not fully elapsed -- wait, or pass --force for a partial read." >&2
  exit 3
fi
PARTIAL=""
[ "$E" -gt "$NOW" ] && PARTIAL="PARTIAL-WINDOW(end in future)"
awk -v s="$S" -v e="$E" '
  { ts=$1; sp=$2; rx=$3; tx=$4
    if (prev_ts != "" && ts > s && ts <= e) {
      dt = ts - prev_ts
      if (dt > 0) {
        rxb = (rx - prev_rx) * 8 / dt / 1000000
        txb = (tx - prev_tx) * 8 / dt / 1000000
        n++
        rsum += rxb; tsum += txb
        vr[n] = rxb; vt[n] = txb
        if (rxb > rmx) rmx = rxb
        if (txb > tmx) tmx = txb
        if (rxb + txb > ttmx) ttmx = rxb + txb
        speeds[sp] = 1
      }
    }
    prev_ts = ts; prev_rx = rx; prev_tx = tx
  }
  END {
    if (n == 0) { print "no samples in window"; exit 4 }
    for (i = 1; i <= n; i++)
      for (j = i + 1; j <= n; j++) {
        if (vr[j] < vr[i]) { t = vr[i]; vr[i] = vr[j]; vr[j] = t }
        if (vt[j] < vt[i]) { t = vt[i]; vt[i] = vt[j]; vt[j] = t }
      }
    rp = vr[int(n * 0.95 + 0.5)]
    tp = vt[int(n * 0.95 + 0.5)]
    sp = ""
    for (k in speeds) sp = sp k " "
    printf "%s samples=%d rx_mean=%.2f rx_peak=%.2f rx_p95=%.2f tx_mean=%.2f tx_peak=%.2f tx_p95=%.2f total_peak=%.2f Mbps link_speeds=%s\n", \
      (PARTIAL == "" ? "ok" : PARTIAL), n, rsum / n, rmx, rp, tsum / n, tmx, tp, ttmx, sp
  }' "$F"
