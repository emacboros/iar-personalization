# The daily camera reboot schedule (discovered 2026-09-21, c169)

## The find

Every camera reboots DAILY on a staggered cron. Source: the rssi
puller's third column (uptime seconds, recorded since 09-11) resets
to ~116s at fixed times:

| cam  | ip    | daily reboot (UTC) |
|------|-------|--------------------|
| ext1 | .101  | 22:02Z |
| ext2 | .102  | 23:02Z |
| ext3 | .103  | 00:02Z |
| ext4 | .104  | 01:02Z |
| ext5 | .105  | 02:02Z |
| int1 | .201  | 03:02Z |
| int2 | .202  | 04:02Z |
| int3 | .203  | 05:02Z |

Full ledger (from /var/lib/aria-fleet/rssi/*.log uptime resets):
daily rows for every cam from 09-11/12 onward, plus outliers:
- .105/.201/.202 extra reboots 09-12 10:38-10:39Z (mass-restart era)
- .103/.104 09-17 16:42Z (the power cycle, relay 0063)
- .102 09-14 13:43Z
- .202 skipped 09-19 04:02Z (power cycle 17:46Z instead)
- .203 STOPPED after 09-18 05:02Z (uptime now ~46h) -- WATCH

## Signatures it explains

- WRN minute-00 spike: 61 WRN lines at HH:00:0x vs ~25 mean for other
  minutes (whole log). Post-restart pattern: WRN i/o timeout at
  HH:00:05, retry ladder 0-3, stop producer, disconnect, new consumer,
  start producer at ~HH:01:14.
- Many HH:00 census FROZEN/ARTIFACT rows (e.g. ext4 13:00/16:00/18:00
  local watchdog events 09-20).
- Part of the camera-degradation-class history: watchdog storms and
  WRN storms have a mundane scheduled component.

## Debug-witness first fire (c169, interior_1 06:00-06:02Z)

The wedge was the scheduled 03:02Z reboot. go2rtc SAW everything at
debug level: WRN i/o timeout 03:00:05 local, retries, stop producer
03:00:21, disconnect, new consumer + start producer 03:00:23 (frigate
watchdog), second cycle 03:01:23-03:01:34. Census caught it
(1789970400 interior_1 11 31 40526). Recordings hour 03: NO gap
(00.02-00.52 all present, hevc+aac). Heal time ~70s.

The c166 SILENT-wedge question (video track dies while conn stays)
remains OPEN -- this onset was a reboot, not a track death. Need a
non-reboot wedge onset for the real experiment.

## Non-reboot real event (ext4 07:20Z 09-21)

Census row 1789963200 exterior_4 0 0 333. Recordings hour 04:
00.21/00.22/00.24 then gap to 01.13; audio missing at 00.22, present
at 01.13. No reboot (uptime continuous), no go2rtc events in podman
logs (TRUNCATED at 58396 lines, starts 09-19 13:07 local -- journald
-u frigate is the full source). Camera-side RTSP-server-level event.

## Walk-failure confirmations

- 09-20 19:05/19:15/19:20Z ARTIFACT cluster: all epoch%300==0, zero
  WRN/ERR/watchdog/reboots in window => census walk failure (c168
  confirmed a third time).
- interior_1 06:00Z row (11/31/40526) and ext4 07:20Z row (0/0/333)
  are LOW-BYTES rows -- the c168 v1.7 criterion (bytes>100k) misses
  real gaps; a bytes-floor variant is also needed.

## Implications for open threads

1. WRNRATE LEAD-LAG (5/6 at n=6) is CONTAMINATED: daily reboots
   manufacture WRN->remake sequences. Re-test must exclude
   HH:00:05 +-10min windows per cam.
2. Census walk-failure guard v1.7: add low-bytes variant.
3. .203 non-reboot watch: does its stability change its degradation
   profile? (It was the worst churn cam pre-ext4.)
4. Who set the crons? Presumably Nacho (thingino scheduled reboots).
   Not in my record before today. Ask at next session -- do NOT
   change them.
5. #2505 comment now unblocked (fresh PAT, 0081 closed): cite
   debug-witness + reboot-schedule caveat (WRN storms partially
   reboot-driven, dedup fix still justified).

## Method note (stimulus lesson)

The pattern was findable for weeks: the rssi puller has recorded
uptime since 09-11 and I never read the third column. Read every
column of your instruments.