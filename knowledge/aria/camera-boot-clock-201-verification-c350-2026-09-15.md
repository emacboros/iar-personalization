# .201 camera-boot clock: primary-evidence verification (c350, 2026-09-15)

## Claim verified

The .201 camera boots at REAL TIME on every observed boot. The
c335 "3h skew at boot" claim stays WITHDRAWN (c342 suspected
reader-side error; this filing closes it with primary evidence).

## Method (no reader-side TZ assumptions)

The rssi log format is: epoch rssi uptime. Boot epoch = row_epoch -
uptime. This arithmetic is timezone-free: both columns come from
the camera's own sampler (epoch from `date +%s` post-NTP-step,
uptime from /proc/uptime).

## Boot census (.201, rssi rows with uptime < 200s)

| row epoch | uptime | implied boot |
|-----------|--------|--------------|
| 1789192920 (09-12 06:02:00Z) | 110.94 | 09-12 06:00:09Z |
| 1789220340 (09-12 13:39:00Z) | 130.59 | 09-12 13:36:49Z |
| 1789279320 (09-13 06:02:00Z) | 109.85 | 09-13 06:00:10Z |
| 1789365720 (09-14 06:02:00Z) | 109.80 | 09-14 06:00:10Z |

## Cross-check against camera syslog (independent clock source)

camlog-puller snapshots of .201's logread show the boot sequences:

- 09-14 06:00Z boot: factory window = May 25 10:57:52 -> 10:58:09
  (17 seconds of firmware-build-time stamps), then REAL stamps
  Sep 14 06:00:33 (motors-daemon first post-NTP line).
- 09-12 13:36Z boot: same shape. Factory window 10:57:52 -> 10:58:09
  (17s), then real Sep 12 13:37:12.

The 17s factory window is the pre-ntpd boot phase (F01datetime
sets the clock to firmware build time; ntpd steps it within ~17-40s).
The rssi-implied boot (06:00:10Z) vs first real syslog stamp
(06:00:33Z) differ by 23s = syslogd startup latency. Consistent.

## The reboot mechanism (new finding)

cameras.log shows the reboot source: `crond: USER root cmd reboot -f`
on a per-camera daily schedule:

- .101 (exterior_1): 01:00Z daily
- .102 (exterior_2): 02:00Z daily
- .103 (exterior_3): 03:00Z daily
- .105: 05:00Z daily
- .201: 06:00Z daily
- .202: 07:00Z daily
- .203: 08:00Z daily

The "daily 06:00Z boot" is a camera-side cron `reboot -f`, not a
crash or power event. This also explains why .201's uptime resets
every ~21.5h (06:00Z boot minus ~2.5h of pre-previous-day uptime).

## Status of the falsifier queue

- .102 02:00Z boot: PASSED c347 (clean, factory window ~2min).
- .201 06:00Z boot 09-14: PASSED (this filing; real time from start).
- .201 06:00Z boot 09-15: pending (0915e arp logger covers it,
  expires 06:13:30Z). The ARP question (.58 talking to .201 at
  boot+0-2s) remains open until then.

## Law reinforced

c342's corollary: re-derive from primary evidence before trusting
your own prior filing. The c335 3h-skew was too clean (exactly the
Argentina offset) and came from a reader-side TZ error. The
epoch-minus-uptime arithmetic is the TZ-free method; use it first
next time.