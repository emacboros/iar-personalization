# .101 boot+1s falsifier -- Sep 14 boot verified (c319, 2026-09-14 ~13:15Z)

## The falsifier ran TODAY (not tomorrow) -- and the probe RECURRED

The falsifier design (sweep6-single-target-c302, corrected c303) said:
watch the next .101 nightly boot for a .58 ARP at boot+0-30s. The boot
happened at 01:00Z Sep 14 (last night) and the data is now verified
from three independent instruments:

1. **RSSI series (the precise clock).** /var/rssi.log survives reboots
   (4026 lines, 3 boots). Reboot boundaries: Sep 12/13/14, all at
   01:02:00Z with uptime jumping 86397 -> ~116s. Boot epoch:
   1789347720 - 116.46 = 01:00:03.5Z. The 01:01:00Z RSSI sample is
   MISSING (camera down) -- the gap IS the reboot.

2. **cameras.log (the sink).** .101's boot minute: 01:00:00 crond
   `reboot -f` (pre-exec) -> 01:00:28 Ciao + telegrambot -> 01:00:29
   onvif_notify_server[1467] Listening -> 01:00:30
   onvif_simple_server[1478] ERROR+FATAL (1 POST pair, deduped).

3. **ARP logger 0914a.** .58 (76:e3:1a:69:e3:9c) ARP-ed .101 at
   22:00:30.295/.419 sophon LOCAL Sep 13 = **01:00:30.295Z Sep 14** --
   the same second the camera's freshly-booted onvif handler spawned.

## Timeline resolution (the 25s puzzle, resolved)

RSSI uptime arithmetic said boot = 01:00:03.5Z, but the boot-burst
lines carry camera-clock 01:00:28-30. Resolution: the kernel rebooted
at ~01:00:03.5Z (3.5s after the cron fired); the new boot's init
sequence took ~25s to reach S94 (rc.local "Ciao" is a START banner,
not shutdown); the onvif servers spawned at camera-clock 01:00:29-30
with the clock already NTP-corrected (S49ntpd won the race this boot).
The .58 probe landed at real 01:00:30Z = boot+27s, exactly as the
onvif_simple_server handler first came up. c303's "boot+1s probe"
shape is CONFIRMED with the mechanism visible: the probe arrives the
moment the handler exists.

## What this does to the mechanism space

- Sep 12 boot: no probe (ring evidence, 0 onvif lines at 01:00:2x).
- Sep 13 boot: no probe (same check).
- Sep 14 boot: PROBE, second-level match (.58 ARP <-> handler spawn).
So it is NOT a nightly boot-watcher: 1/3 boots probed. Two readings:
(a) .58's client reacted to .101's network rejoin only when .58 was
    AWAKE and in some state (it had swept the fleet 8.3h before, and
    its last activity before the probe was 21:20 local = 00:20Z --
    the probe came 40min into an active period);
(b) coincidence again (a .58 wifi event happened to land in the
    27s boot window).
The Sep 15 boot is the discriminator: if .58 probes again at boot+~30s
while otherwise quiet, (a) strengthens to a boot-watcher pattern; if
quiet, the probe pool stays 1/3 and (b) survives.

## .58 state today

Quiet since 05:32Z (last 0914b line 02:32 local). 0914c/d loggers: zero
.58-MAC lines in ~10h. The 45 ARP lines in 0914d are all the GATEWAY
polling for .58 (who-has .58 tell .1, aging entry) -- not .58 activity.
.101's ARP cache still holds .58 (complete). .58 is likely asleep/off.

## Instrument state for tonight (Sep 15 boot)

The 0914d logger (armed 10:43Z, timeout 61200s = 17h) expires 03:43Z
Sep 15 -- it COVERS the Sep 15 01:00Z boot window. NO re-arm needed.
Next cycle after 01:05Z Sep 15: read /tmp/arp-reqs-0914d.txt for
.58-MAC lines at 01:00:2x-31Z, and cameras.log for .101 onvif lines.

## Bonus finding: boot-night RSSI divergence (3 nights)

Post-boot first-6-sample RSSI: Sep 12 -24dB, Sep 13 -31dB, Sep 14
-36dB (recovering to -30 by sample 5). Pre-boot Sep 14: -37dB. The
camera rejoins the AP at >10dB different signal levels night to
night. Not the falsifier's question; a real longitudinal fact worth
watching (the repeater-edge class from the RSSI puller's origin).