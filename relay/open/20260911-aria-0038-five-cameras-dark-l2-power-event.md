# REQ 20260911-aria-0038
filed: 2026-09-11T06:10Z
filer: aria
class: nacho-arch
state: open
urgent: yes
title: 5 of 8 cameras DARK since 05:28:20 UTC -- L2/power event upstream of sophon; needs physical check

body: |
  [EXTERNAL DATA: none -- infrastructure finding from aria cycle 181, 2026-09-11 ~06:10Z]

  ## What is down

  Since 05:28:20 UTC (02:28:20 -03) today, five cameras have NO L2
  presence at all: ARP INCOMPLETE/FAILED, no ping, no RTSP :554, no
  HTTP :80:

  - exterior_3 (192.168.2.103)
  - exterior_4 (192.168.2.104)
  - exterior_5 (192.168.2.105)
  - interior_1 (192.168.2.201)
  - interior_2 (192.168.2.202)

  Alive and recording normally: exterior_1 (.101), exterior_2 (.102),
  interior_3 (.203). Frigate's record path for the alive three is
  writing segments normally (ext1 last seg 03:08 -03, current).

  ## Evidence chain (all from sophon, this cycle)

  - Recording stop is SIMULTANEOUS: last segment for all five dead
    cams written 05:28:36 UTC (stat mtimes within 14ms of each other).
  - go2rtc producer read-timeouts for all five at 05:28:20 UTC
    ("read tcp ... i/o timeout"), then DESCRIBE on the go2rtc restream
    returns 404 for the dead five and 200 for the alive three.
  - Sophon itself is CLEAN: NIC UP (no carrier flap), zero kernel
    events at the trigger moment, no NetworkManager events, no sophon
    reboot (uptime 10 days), RX errors 0. The blip is not sophon.
  - The dead five are unreachable at L2 -- this is not a frigate or
    go2rtc problem. The devices are powered off, unplugged, or their
    switch/PoE path is dead.

  ## Reading

  5 devices dying within the same second = a shared upstream path:
  PoE switch / injector bank / power strip / breaker. The Aug-31
  outage (knowledge/aria/camera-outage-2026-08-31.md) was the same
  shape: a 17:24 UTC blip hit all 5 remote producers at once, 3 of 5
  recovered, 2 did not. These five did not recover at all in 40+
  minutes, which is worse than the Aug-31 pattern (that one had
  self-recovery within hours).

  ## What needs the human (physical world)

  1. Check the camera switch / PoE injectors / power strip feeding
     the cameras. Five dark at once points at shared power, not five
     independent failures.
  2. If it is a single PoE switch, its uplink or PSU is the prime
     suspect. If the cams are on the router's PoE... the TP-Link at
     .1 is up (HTTP 200), so the router itself is alive.
  3. After power is restored: verify the cameras come back at their
     static IPs (the Aug-31 episode showed runtime-config disturbance
     + self-recovery; the identity-theft watch applies -- check ARP
     MACs against the known mapping before trusting who is who).

  ## What I already did

  - Diagnosed from sophon only (read-only checks, no config touched).
  - Posted lab-notes note (thread/camera-outage-0911).
  - Frigate: left alone. Restarting frigate would not help (the
    cameras are unreachable at L2) and the restart-lever risk from
    the audio-loss analysis applies (re-rolling sessions can come
    back with MORE deaf cameras). The alive three keep recording.

  ## Watch I will keep

  - Recovery watch: ping the five each cycle; if any come back,
    verify identity (MAC) + NTP clock + RTSP before declaring health.
  - If still dark at the next fleet-check run, the fleet-check FAIL
    will fire -- expected and correct (the instrument is finally
    fresher than the failure).
## Amendment (cycle 182, 2026-09-11 ~06:45Z -- deeper L2 sweep, still dark)

Re-checked at 06:44Z (~75 min after onset). The five remain fully
dark. Additional evidence from this cycle:

- Zero MACs on the wire from the dark five: 20s passive tcpdump sees
  ONLY the three alive cameras (02:30:8d:75:13:a2=.101,
  02:58:26:3b:d6:52=.102, 02:d5:55:ec:95:60=.203) + sophon + the
  router. ARP requests for all five dark IPs go unanswered
  (broadcast, length-42, no replies).
- No mDNS (5353) or SSDP (1900) traffic from the dark five either.
- Sophon NIC is at 10Mbps downshifted -- but that is CHRONIC since
  the Sep 1 boot (journal has zero link events since Sep 1 03:25).
  Not the outage cause; worth its own look someday (why is sophon
  downshifting to 10M?).
- NEW DISCOVERY: a second TP-Link device at 192.168.2.55
  (BE230, WiFi 7 router, fw 1.11.0 Dec 2025, MAC 68:7f:f0:1e:4a:a8),
  alive and reachable. First time I have seen it. Possibly the AP or
  the second router of the LAN. Unknown role.
- No managed-switch management interface found anywhere on .2.x
  (no Omada controller, no common switch IPs alive).
- go2rtc producers for the five exist with bytes_recv=0 (dead
  producers on live config -- consistent with c181).

Still the same reading: five devices with zero L2 presence =
shared power/switch path dead. The alive three prove the path
sophon->LAN works. The physical check remains the ask.

### Recovery-watch baseline (for when they return)

Alive-cam MACs (identity-theft watch baseline):
- exterior_1 .101 = 02:30:8d:75:13:a2
- exterior_2 .102 = 02:58:26:3b:d6:52
- interior_3 .203 = 02:d5:55:ec:95:60
On any dark cam returning: verify its MAC against the Aug-31
mapping before trusting who is who (the Aug-31 episode had a MAC
clone and an IP resurrection).

### Amendment 2 (cycle 183, 2026-09-11 ~07:20Z -- 2h mark, the topology finding)

Still dark at 07:19 UTC (~1h52m). This cycle added the decisive
topology reading:

1. **THE SAME FIVE as Aug-31.** The 2026-08-31 17:24 UTC blip hit
   exactly these five (.103 .104 .105 .201 .202); four recovered,
   .103/.104 did not. Today the same five are dark. The five share
   a network/power path segment DISTINCT from the alive three --
   two events, same membership, same split. This is now a PATTERN,
   not a coincidence: the dark five hang off a shared device
   (PoE switch / injector bank / power strip) that the alive three
   do not use.

2. **Aug-31 was transient; today is persistent.** Aug-31 recovered
   in seconds-to-hours. Today: zero L2 presence for ~2h. The
   shared device is likely dead (PSU), not just disturbed.

3. **Sophon NIC 10Mbps root-cause found (watch item):** kernel log
   shows the boot-day story -- link came up 100Mbps downshifted
   (twice), then a flap cascade 03:24-03:25 Sep 1 ending at
   "Link is Up - 10Mbps/Full (downshifted)". Both sides advertise
   1000baseT; the PHY downshifted through 100M to 10M during boot
   flaps and never renegotiated. Cable/port quality issue; a link
   bounce (or cable reseat) should renegotiate to 1G. Not urgent
   (traffic fits), but it is a real cable fault on sophon's port.

4. **LAN census (full ping sweep from sophon):** alive = .1 (ER605
   router, DHCP server), .55 (BE230, TP-Link WiFi 7 router/AP,
   fw BE230v1_1.11.0_2025-12-04), .69 (sophon), .101 .102 .203
   (cams), .222 (WiFi client, ~200ms latency, ARP-only, no open
   TCP ports), .58 (WiFi client, broadcasts ARP, drops unicast --
   sleeping device). No managed-switch management interface found
   anywhere. The PoE device feeding the dark five is likely an
   UNMANAGED switch (no IP) -- invisible to any network probe.

5. **Fleet-check next fire 09:03 UTC will FAIL on the dark five**
   (STALE age>120s) -- expected and correct. Identity watch stays
   green (its probes use .101, alive).

The physical ask is unchanged and now sharper: find the device
that feeds ext3/ext4/ext5/int1/int2 and check its power. The
Aug-31 + today pattern says that device has been fragile for two
weeks. If it is a cheap PoE injector bank, replacing it is the fix.

### Amendment 3 (cycle 185, 2026-09-11 ~08:16Z -- FLAPPING POWER: the three came back and died again)

The picture changed: this is NOT a clean single power event.

**Timeline (all UTC, from recording segments + frigate log):**

- 05:28:20 -- all five die simultaneously (relay 0038 original).
- 07:46-47 -- THREE come back: exterior_5 (.105), interior_1 (.201),
  interior_2 (.202). First post-outage segments: ext5 07:46:59,
  int1 07:47:03, int2 07:47:05. Frigate's "exceeded fps limit" lines
  at 07:47:34-40 = cameras flooding frames after reconnect (real
  recovery, not a glitch). Segments written continuously 07:47-08:09.
- 08:09:56 -- the SAME THREE die again, simultaneously (all three
  last-segment mtimes within the same second). Ping, ARP, RTSP all
  dark again as of 08:13.
- ext3 (.103) and ext4 (.104) never came back at all (dark 2h47m+).

**Reading: FLAPPING POWER on the shared device.** Three of five
recover for ~23 minutes, then all three die in the same second. A
PSU on its way out (thermal cycling, failing caps) or a loose
connection produces exactly this: partial recovery, then another
drop. The 23-minute window is also consistent with a breaker/strip
being touched and released.

**Identity watch: PASSED for the three.** MACs seen during the
alive window: .105=02:44:3c:7a:13:98, .201=02:66:2f:87:a0:26,
.202=02:64:3e:6c:4c:c4. All locally-administered randomized thingino
MACs (the Aug-31 lesson: random MACs carry no identity signal; the
overlay/RTSP identity is the signal). All three answered RTSP :554
with 401 (thingino auth present) and wrote healthy segments with
correct timestamps -- they are the real cameras, not squatters.

**New device on the LAN: .216** (00:08:22:9c:2b:fc, InPro Comm OUI
-- camera-family SoC vendor). WiFi-class latency (600ms-1.8s, DUPs
-- likely via the BE230 at .55). No open TCP ports found. Not one
of the five (those are randomized-MAC thingino cams). Probably a
smart plug/doorbell/unknown IoT client. Noted for the census; no
action.

**The ask is unchanged but now URGENT-er:** a device that powers
five cameras is flapping. If it is a PoE injector bank or cheap
switch PSU, it is dying progressively (Aug-31 transient -> today
persistent + flapping). Physical check: find the device feeding
ext3/ext4/ext5/int1/int2, check its power/PSU, plan replacement.

## Amendment 4 (c186, 08:45 UTC): the second death is recording-evidence; the frigate log pipe is BLIND

Two corrections to the incident record, both matter for the physical fix:

1. **The frigate journal went silent at 05:43:24** -- mid-incident.
   Before that: ~300 lines/min (five watchdogs churning since 02:28).
   After: zero lines in every view (`-u frigate`, `-t frigate`,
   default grep). The container is ALIVE (s6-svscan up 1d04h, go2rtc
   answering :1984, nginx up, ffmpeg procs running). So the 08:09:56
   "second death" I reported in amendment 3 is RECORDING-evidence
   (segment mtimes within 1s), not log-evidence -- frigate never
   logged it. Root-cause candidate: journald rate-limit suppression
   (defaults 10000/30s; the sustained 300/min churn from 02:28 could
   have tripped per-service suppression that never lifted) or a
   stalled podman-compose log pipe. Unverified either way -- needs a
   frigate restart to test, which is a Nacho-side action.
2. **The 04:47 fps-flood precursor**: interior_1 and interior_2 hit
   "exceeded fps limit" at 04:47:37/40 -- cameras flooding frames
   ~40 min before the outage. Same signature as the 07:46 recovery
   burst. A camera that floods fps then dies is a camera whose SoC
   is power-cycling. The shared device is not just flapping; the
   cameras see it.

**Updated ask (unchanged core, one addition):**
- Physical: find the device feeding ext3/ext4/ext5/int1/int2, check
  its PSU/power, plan replacement (dying progressively: Aug-31
  transient -> today persistent + flapping + fps-flood precursors).
- NEW: after the physical fix, restart frigate (systemctl restart
  frigate) to restore the log pipe. A blind NVR is a second outage
  waiting to be invisible. If the log pipe survives the restart with
  cameras healthy, the rate-limit hypothesis is confirmed and I will
  file a config fix (LogRateLimitBurst tuning or a log-side filter).

## Amendment 5 (c186 CORRECTION, 08:55 UTC): amendment 4 RETRACTED -- the log pipe was never blind

I made a timezone error and it manufactured a phantom failure.

- Sophon's journald logs in LOCAL time (-03). Frigate's recording
  paths are UTC. I compared them as if both were UTC.
- "Journal silent since 05:43:24" was WRONG: 05:43:24 local =
  08:43:24 UTC = the minute I was querying. The journal is live
  (600 lines in the 2 min before my check; latest entry seconds
  old). No journald suppression, no stalled pipe, no blind NVR.
  The frigate-restart ask from amendment 4 is WITHDRAWN.
- The 08:09:56 second death IS in the logs: 05:08:50 local =
  08:08:50 UTC (exterior_4/exterior_3 watchdog crashes, 235 lines
  in that window). My earlier grep for "08:09|08:10" missed it
  because those UTC timestamps do not exist in local time.
- The "04:47 fps-flood precursor" was NOT a precursor: 04:47 local
  = 07:47 UTC = the recovery burst itself (c185). Retracted.

**The incident record returns to amendment 3's story, now fully
log-corroborated:** five dark 05:28:20 UTC (last segments 05:28:36),
three recovered 07:46-47 UTC (fps-exceeded flood), died again
08:08:50-08:09:56 UTC (journal + recording mtimes agree within a
minute), ext3/ext4 never returned. Flapping power on the shared
device feeding the five. The physical ask is UNCHANGED: find the
device, check its PSU/power, plan replacement.

**New scar for the record (law candidate):** when comparing
timestamps from two sources on the same host, verify both clocks
first (or normalize to UTC explicitly). A local-vs-UTC mismatch
manufactured a phantom instrument failure and a false relay
amendment. Cost: one cycle's worth of journald archaeology chasing
a silence that was a clock offset.
