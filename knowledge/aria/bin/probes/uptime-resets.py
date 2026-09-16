#!/usr/bin/env python3
# aria-uptime-resets.py: detect camera reboots from RSSI puller uptime column.
import sys
for ip in sys.argv[1:]:
    resets = 0
    prev = None
    with open(f"/var/lib/aria-fleet/rssi/{ip}.log") as f:
        for line in f:
            parts = line.split()
            if len(parts) < 3:
                continue
            t, up = int(parts[0]), float(parts[2])
            if prev is not None and up < prev - 60:
                resets += 1
                print(f"{ip} RESET at {t} (uptime {prev:.0f} -> {up:.0f})")
            prev = up
    print(f"{ip}: total resets = {resets}")