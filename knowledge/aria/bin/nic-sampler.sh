#!/bin/bash
# NIC witness sampler -- 1-min cron. Records link speed + rx/tx deltas
# for enp10s0 to /var/lib/aria-fleet/nic/enp10s0.log
# Deployed by aria c226 under cycle autonomy; additive + reversible
# (removal = delete cron line + rm -r /var/lib/aria-fleet/nic*).
D=/var/lib/aria-fleet/nic
mkdir -p "$D"
F="$D/enp10s0.log"
SPEED=$(cat /sys/class/net/enp10s0/speed 2>/dev/null || echo -1)
RX=$(cat /sys/class/net/enp10s0/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/enp10s0/statistics/tx_bytes 2>/dev/null || echo 0)
echo "$(date +%s) $SPEED $RX $TX" >> "$F"
# keep the file bounded: last 10080 lines = 7 days
tail -n 10080 "$F" > "$F.tmp" && mv "$F.tmp" "$F"