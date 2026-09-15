# The two factory-clock mechanisms -- .102 boot-hang (c343) and .103 NTP-path failure (c343)

## What c342 got wrong

c342 filed: "ntpd steps real ~30-40s post-boot (up to ~20 min if NTP slow)."
Both observed factory-clock windows contradict that. The real law:

**The NTP step happens WHEN NTP SUCCEEDS. That can be seconds, hours, or
14.7 hours after boot. The factory clock (F01datetime TIME_STAMP) is the
default state, not a transient.**

## Mechanism 1: .102 boot-hang + WiFi-down (09-14, 14.7h)

Timeline (all UTC, verified from primary evidence):

- 02:00:02Z -- nightly cron `reboot -f` fires (by design; crontab:
  `0 2 * * * reboot -f`). Boot starts, clock = factory (May 25 11:20).
- Boot HANGS between S50crond and S94rc.local. Evidence:
  - rssi cron rows continue every 60s through the whole window (crond up,
    /proc/uptime counter continuous 72s -> 52872s = 14.68h).
  - rssi rows have EMPTY RSSI field (verified with cat -A: `1779708000  72.72`
    -- two spaces, no dBm). wpa_cli signal_poll fails => wlan0 never associated.
  - rssi puller on sophon: 59 failures 02:00Z -> 16:30Z (4/hour x 14.75h).
  - Frigate: go2rtc "connection refused" 02:00:04Z, ffmpeg DESCRIBE 404,
    recordings stop 02:00Z (last segment 01:59:52Z), zero ext2 segments 02-16Z.
- 16:41:42Z -- self-heal. WiFi associated, ntpd daemon stepped the clock,
  and the hung boot RESUMED: telegrambot (S93) logs "Missing token" at
  16:41:42, rc.local (S94) "Ciao" at 16:41:42, onvif_notify (S97) listening
  at 16:41:43 -- all stamped with REAL time because the clock had just
  stepped. The boot-end services ran 14.7h after power-on.
- 16:42:49Z -- Frigate events resume (74 events in the first 3 minutes:
  motion burst, person at the camera).
- 16:43:00Z -- rssi rows resume with real epochs + RSSI values.

Init order (from /etc/init.d/ on .102): S38wpa_supplicant -> S40network ->
S49ntpd -> S50crond -> ... -> S93telegrambot -> S94rc.local -> S97onvif_notify.
The hang sits between S50crond and S93telegrambot; the exact script is not
identified (candidates: S56ircut, S60uhttpd, S91mqttsub, S93ha). The
Sep-14-stamped S93/S94/S97 lines prove the boot script chain was BLOCKED,
not finished -- crond had been running for 14.7h while rc.local had not run
at all.

Why the hang cleared at 16:41Z: unknown. Candidates: wpa_supplicant
association finally succeeded (14.7h of retries), AP-side change, driver
reset. Router-side logs would settle it -- Nacho's device.

## Mechanism 2: .103 NTP-path failure with WiFi UP (09-12, 4.5h)

- .103 rssi: last real row 09-12 11:10Z, then factory-stamped rows
  (May 25 11:20 -> 13:22 = 2h02m of rows... wait: factory rows run
  1779708000-1779715320 = 11:20->13:22 factory, which at 60s cadence is
  122 rows; resume at real 09-12 15:41Z). Factory window ~4.5h of wall time.
- CRITICAL DIFFERENCE: .103's factory rows HAVE RSSI values (-54 dBm).
  WiFi was UP the whole window. NTP still failed.
- .103 is on a different BSSID (08:8a:f1:6a:62:56) than .101/.102
  (72:7f:f0:1e:4a:a8) -- a different AP. NTP failure with association up
  points at the network path: DNS (192.168.2.1), upstream internet, or
  AP-specific isolation.
- The 11:10Z reboot was NOT the nightly cron (.103 crontab: `0 3 * * *`).
  Cause unknown (power blip? manual?).

## Corollary: the SEG-TAIL timestamp poison

The ext1 SEG-TAIL sawtooth (fleet-check watch state) is almost certainly
CAUSED by these factory-clock windows: segments written while the camera
clock is at factory time carry May-25 timestamps into the recording tree.
Every factory-clock window is a poison window. .103's watch state and
.102's 14.7h gap are the same disease at different severities.

## Instrument notes

- The rssi log is the factory-clock detector: EMPTY rssi field = WiFi down;
  factory-epoch rows = clock not stepped. One file, two failure signatures.
- The uptime counter (3rd field) distinguishes "camera rebooted" from
  "camera hung": continuous counter + factory epochs = hung boot with crond
  alive.
- The camlog puller's `tail -100` non-crond window means a hung boot shows
  as: boot lines (factory stamps) + post-step lines (real stamps) with a
  TIME GAP between them equal to the hang duration.

## Falsifiers queued

- .201 boot tonight 06:00Z (cron `0 6 * * *`): first post-boot rssi epoch
  should be factory (May 25) or 06:01-06:02Z real if NTP succeeds fast.
  If 03:02 appears: third clock state, reopen.
- .101 boot tonight 01:00Z (cron `0 1 * * *`): same read. .101 has
  re-associated within ~2min on 09-12/09-13/09-14 (rssi resets at 01:02
  with RSSI values present) -- the NORMAL case.
- If .102's nightly 02:00Z boot hangs again, the rssi log will show it
  within one minute (empty RSSI field at 02:01Z).

## What this changes

- c342's "30-40s" claim: withdrawn. The mechanism doc's falsifier
  prediction ("first post-boot rssi epoch = May-25 or 06:01-06:02Z, NEVER
  03:02") SURVIVES for .201 but the mechanism behind it changes: the
  factory window is not bounded by boot time, it is bounded by NTP success.
- The nightly reboots are BY DESIGN (staggered 01:00/.101, 02:00/.102,
  03:00/.103, 06:00/.201). A factory-clock window after each reboot is
  EXPECTED until NTP succeeds. The fleet-check NO-SEGMENT/STALE states
  during those windows are consequences, not new faults.
- .102's 14.7h outage was: cron reboot (by design) + boot hang (anomaly)
  + WiFi non-association (anomaly) + self-heal (lucky). If it recurs,
  the fix is on the camera/AP side -- Nacho's call (0062-class).