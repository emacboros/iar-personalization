# RSSI longitudinal series -- the camera WiFi signal dataset (started 2026-09-11)

## What this is

Every camera now appends one line per minute to /var/rssi.log (local
flash, survives until reboot -- see Persistence below):

    <unix-epoch> <RSSI-dBm> <uptime-seconds>

Collector (per camera, in /etc/cron/crontabs/root):

    * * * * * { echo "$(date '+%s') $(wpa_cli -i wlan0 signal_poll 2>/dev/null | grep '^RSSI=' | cut -d= -f2) $(cat /proc/uptime | cut -d' ' -f1)" >> /var/rssi.log; } 2>/dev/null

signal_poll gives RSSI + AVG_RSSI + LINKSPEED; I record RSSI (the
instantaneous value) and uptime (so gaps = reboots are self-evident).
Installed on ALL 8 cameras (192.168.2.{101..105,201..203}); crond
restarted after crontab edit; verified: cron entry present + crond
running on all 8 (census 2026-09-11 ~17:59 UTC), first line written
on .104 at 17:58:00Z (1789149480 -68 29621.98).

## Why (the question it answers)

The ext4 RTSP-stall storm (12:12-13:41 -03, 86 restarts, one camera)
is attributed to the weak-RF repeater-edge class, but the MECHANISM
is hypothesis: "WiFi degradation stalls TCP RTSP -> watchdog churn".
To prove or kill it we need RF-side evidence DURING an episode. This
series is that instrument. Predictions it can falsify:

1. Storm-correlation: if the class is real, RSSI on .104 should dip
   (or the link should bounce) during RTSP-stall storms, and NOT
   during viewer-storms (c198 class) or clean hours.
2. bgscan trigger: .104 sits at -69/-70, exactly on the configured
   bgscan threshold ("simple:30:-70:3600"). The series shows how
   often it CROSSES -70 and whether crossings precede instability.
3. Diurnal/seasonal drift: repeater-edge signal vs time of day
   (interference, foliage, weather). Weeks of data answer whether
   the edge is fixed (RF shadow) or moving (environment).
4. Reboot-gap detection: uptime in each line makes every reboot
   visible as a gap -- correlates the series with the nightly
   reboot crons and any unplanned reboots.

## Baseline snapshot (2026-09-11 ~17:59 UTC, wpa_cli bss level)

    .101 -27  nacho_guest   (BSSID 72:7f:f0:1e:4a:a8 = .55 BE230)
    .102 -28  nacho_guest
    .103 -56  nacho_camaras (BSSID 08:8a:f1:6a:62:56 = .2 Mercury)
    .104 -69  nacho_camaras   <-- the fragile one
    .105 -57  nacho_guest
    .201 -49  nacho_guest
    .202 -41  nacho_guest
    .203 -41  nacho_guest

Consistent with c197's census (.103 -57 / .104 -70). .104 rides the
bgscan threshold; .103 has 13dB of headroom.

## Persistence (the honest limit)

/var is tmpfs-or-flash on thingino; the nightly reboot crons
(01:00-06:00 local) will TRUNCATE each camera's series daily unless
the file survives. Unknown whether /var persists across reboot on
this firmware. If the log resets each night, the dataset is
still usable (each day's series is continuous within the day) but
longitudinal drift needs a collector on sophon. NEXT STEP if the
series proves valuable: sophon-side puller (cron scp/cat of
/var/rssi.log from all 8 into /var/lib/aria-fleet/rssi/) -- NOT
built yet; one-cycle observation first (does /var/rssi.log survive
tonight's reboots?).

## Reading the series (recipe)

    ssh root@192.168.2.104 'tail -20 /var/rssi.log'
    # or fleet-wide: for ip in 192.168.2.{101..105,201..203}; do
    #   echo "$ip: $(ssh root@$ip 'tail -1 /var/rssi.log')"; done

During the next ext4 storm: pull .104's series around the window
FIRST (before any other probe -- the series is the perishable
evidence), correlate RSSI dips vs the go2rtc timeout timestamps.

## Provenance

- Installed by aria c202 (2026-09-11 ~17:57-17:59 UTC) under the
  aria-0028 camera-ownership grant (session XV: "Full camera
  autonomy granted -- investigation, config, cron changes included").
- Additive, reversible: one cron line + one log file per camera;
  removal = delete the two lines + rm /var/rssi.log.
- No camera config otherwise touched. All 8 verified post-install.