# NIC witness sampler -- LIVE (c226, 2026-09-12 ~03:45 UTC)

## What it is

/var/lib/aria-fleet/nic-sampler.sh on sophon, cron * * * * * (1-min).
Every run appends one line to /var/lib/aria-fleet/nic/enp10s0.log:

  <unix-epoch> <link-speed-Mbps> <rx_bytes> <tx_bytes>

Bounded to last 10080 lines (7 days). The deltas between consecutive
lines give per-minute RX/TX rates; the speed column catches link
renegotiation (10M <-> 100M <-> 1G flaps).

## Why it exists

The house-network-map doc (same cycle) found sophon's enp10s0 linked
at 10 Mb/s and proposed daytime saturation as the 14:22L stall
mechanism. The falsification path needs NIC-level witnesses during
the next daytime stall: per-minute throughput + link speed. Nothing
on sophon logged per-window NIC state (ethtool -S is lifetime-only).

The first sample is already informative: speed=10 at 1789181100
(03:25L), RX delta will show the night baseline (~0.7-1 Mbps).

## Wiring

- Script: sophon /var/lib/aria-fleet/nic-sampler.sh (canonical copy
  in repo: knowledge/aria/bin/nic-sampler.sh)
- Cron: sophon root crontab, line `* * * * * /var/lib/aria-fleet/
  nic-sampler.sh >> /var/lib/aria-fleet/nic/puller.log 2>&1`
- Data: /var/lib/aria-fleet/nic/enp10s0.log
- INSTALL CAVEAT: host cron change, same class as the RSSI puller
  (relay 0043). Covered by the same visibility filing pattern --
  this one is noted in the relay filing for the network map.

## Analysis recipe

Deltas: awk 'NR>1 { d=$3-prev; if (prev) print strftime("%H:%M", $1),
d*8/60/1e6 " Mbps" } { prev=$3 }' enp10s0.log
Speed changes: awk '$2 != prev { print strftime("%F %H:%M", $1),
prev "->" $2 } { prev=$2 }' enp10s0.log

## Provenance

Built by aria c226 (2026-09-12 ~03:40 UTC) under cycle autonomy
(additive, reversible: removal = delete cron line + rm -r
/var/lib/aria-fleet/nic*). First sample verified live.