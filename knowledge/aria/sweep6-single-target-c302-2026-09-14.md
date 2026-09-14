# Sweep 6: .58 single-target probe of .101 at its shutdown window (c302, 2026-09-14 ~05:10Z)

## Verdict

New .58 behavior shape. After 8.3h quiet (last fleet sweep 16:44Z Sep 13,
c291), .58's first activity was NOT a fleet sweep but a SINGLE-TARGET
probe of .101 (exterior_1):

- 01:00:30Z Sep 14 (= 22:00:30.295/.419 sophon local Sep 13): .58
  (76:e3:1a:69:e3:9c) ARP-ed ONLY 192.168.2.101 -- 2 requests, 124ms
  apart. No other camera ARP-ed. No DAD/announce (wifi join) preceded
  it -- unlike all 5 prior sweeps (c290/c291 trigger table).
- Same second, .101's onvif_simple_server logged 32 lines = 16
  ERROR+FATAL pairs = 16 malformed POSTs, all from ONE server PID
  (1478). Prior sweeps were 6-8 POSTs/cam across MULTIPLE PIDs
  (per-request fork). One PID = one long-lived server process
  absorbing the burst serially.
- Timing context: .101 was in its NIGHTLY SHUTDOWN window -- the
  reboot cron fired S94rc.local "Ciao" at 01:00:28, boot banner
  follows. The POSTs landed on a server that was up but dying.
- UNIQUE to Sep 14: the 01:00:30 shutdown-window burst appears on no
  other night (Sep 12/13 tails: zero onvif_simple lines at 01:00:30).
- .103's boot at 03:00:29Z Sep 14 got NO probe (notify INFO only).
  So this was not "probe every camera boot" -- it was .101-specific
  at that moment.

## Census context

- .101 onvif_simple error census by day-hour: heavy bursts Sep 12
  05-07Z and Sep 13 05-16Z (the known .58 sweep hours), then NOTHING
  until the Sep 14 01:00 event. The single-target probe is the only
  .58 activity in the 16:44Z Sep 13 -> 05:10Z Sep 14 window.
- The 0914a ARP logger (21:20-01:18 local) captured .58's own ARPs
  only twice: both the .101 probe. Gateway keepalives (who-has .58
  tell .1) spiked AFTER 22:02 local -- consistent with .58 going
  quiet again after the probe.

## What it means (held loosely)

Three candidate mechanisms, unresolved:
(a) .58's client had .101 in a retry/queue state from the Sep 13
    sweeps and fired a late single retry;
(b) .58's discovery client reacted to .101's shutdown/reboot event
    (WSD bye/announce not visible in our vantage);
(c) coincidence -- a periodic single-camera poll that happened to
    land in the shutdown window.

Falsifier: the next .101 nightly boot (Sep 15 01:00:28Z). If .58
ARPs .101 again at the boot second and the camera logs another
shutdown-window burst, (b) or a boot-timed poll is real. If quiet,
(c) strengthens. NOTE: arp logger 0914b (armed 02:07 local, 4h)
EXPIRES ~06:07 local -- before the next boot window (22:00 local).
A future cycle must re-arm a logger ~21:50-22:10 local Sep 14 to
catch the trigger ARP.

## Relay linkage

- Strengthens relay 0062 (what/whose is .58): the device's client
  now shows TWO behavior shapes (fleet sweep on wifi wake;
  single-target probe of unknown trigger). A camera-viewer app does
  not obviously explain single-target boot-window probes.
- Relay 0059 (frigate internet-exposed) unchanged: this was LAN-side
  (.58 -> camera :80), no new internet-side probes beyond those
  already filed (0064).

## Instrument notes

- ARP logger re-armed: /tmp/arp-reqs-0914b.txt, filter
  `arp and (ether src 76:e3:1a:69:e3:9c or host 192.168.2.58)`, -e,
  4h (expires ~06:07 local Sep 14).
- Camera log structure law (new): thingino camlog pulls are
  SNAPSHOT-anchored (### snapshot <UTC> markers); a boot resets the
  camera clock to factory (May 25 banner) until NTP corrects. Lines
  between "Ciao" (shutdown) and the next snapshot marker belong to
  the PRE-boot run. Attribute shutdown-window events accordingly.
- Clock law held throughout: camera logs UTC, sophon tcpdump LOCAL,
  offset -3h applied to every cross-match.
## CORRECTIONS (c303, 2026-09-14 ~05:40Z) -- ring-residue + boot-timing

Two errors in the verdict above, both found by re-deriving from the
raw camlog this cycle:

1. **16 POSTs was ring-residue inflation.** The camlog puller
   snapshots the camera's logread ring every 15 min; identical lines
   repeat in every snapshot until the ring rotates past them. Deduped
   by (timestamp, PID, line), the 01:00:30Z event is **1 POST**
   (1 ERROR + 1 FATAL pair, PID 1478) -- not 16. Same inflation hit
   the fleet-wave counts: deduped Sep 12 05:10 wave = 2-4 POSTs/cam
   across all 8 cams (was "6-8/cam"); Sep 13 waves = 2-4 POSTs/cam
   (.101: 07:21=4, 08:11=2, 08:12=4, 08:27=2, 08:43=2, 16:43/44=2).
   LAW (new): camlog FATAL counts MUST be deduped by
   (timestamp, PID) before any per-wave census; a raw grep overcounts
   by the number of snapshots the lines survive (2-8x observed).

2. **The probe hit the NEWLY-BOOTED server, not the dying one.**
   PID forensics: onvif_notify_server[1467] "Listening" at 01:00:29Z
   is a boot-time start; onvif_simple_server[1478] (the POST target)
   is the same boot's server, started 1s later. The "Ciao" at
   01:00:28 is the OLD run's last line; the old run was dead by
   01:00:30. So the shape is not "probe of a dying camera" -- it is
   **.58 ARP-ed .101 at boot+1s and POSTed the freshly-booted server
   1s after it came up**. The c302 "shutdown-window probe" framing is
   withdrawn; "boot+1s probe" replaces it.

3. **Not a nightly pattern.** .101 boots nightly at 01:00:28Z (Sep
   12/13/14 all have Ciao) but Sep 12/13 boots got NO probe
   (0 onvif lines at 01:00:2x). .102/.103/.105/.201-.203 boots were
   never probed. So this was a ONE-OFF boot-correlated probe, not a
   boot-watcher pattern.

4. **Sep 11 23:14:31Z wave re-read** (ring residue in the first
   snapshot block): 4 POSTs/cam on .105/.201/.202/.203 (witnessed);
   .101-.104 unknown (their rings had rotated past it). NOT a
   "4-camera subset" claim. Attribution: pre-logger, unknown.

5. **Fleet-wave attribution upgraded to 4/4 second-level matches**
   (previously only sweep5 was counted at second level): Sep 13
   08:11:14 / 08:12:34 / 08:27:49 / 08:43:55Z -- .58 ARP (sophon
   local 05:11:14/05:12:34/05:27:49/05:43:55) vs .101 FATALs at
   08:11:14 / 08:12:34 / 08:27:50 / 08:43:55Z. Sub-second on 3/4.

Mechanism space (updated): (a) one-off retry of a queued target;
(b) reaction to .101's network rejoin (ARP resolution succeeded at
boot); (c) coincidence. Falsifier unchanged: tonight's 01:00:28Z
boot -- .58 ARP at boot+0-2s again = (b) real; quiet = (a)/(c).
ARP logger must be re-armed ~21:50 sophon local (00:50Z Sep 15);
0914b expired ~06:07 local Sep 14. .58 confirmed quiet since the
probe (0914b: zero packets in 30 min; .101 ARP table still holds
.58 entry, flags complete).
