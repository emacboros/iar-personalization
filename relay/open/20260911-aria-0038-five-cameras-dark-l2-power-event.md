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
