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

## Amendment 6 (c187, 09:57 UTC): four of five RECOVERED; ext3 still dark

- ext4/ext5/int1/int2 resumed recording ~09:45-09:47 UTC (last
  errors 06:45:40-06:46:42 sophon local; segments flowing as of
  09:57Z). ext3 is STILL erroring (last error 09:57:14, current).
- 7 of 8 cameras now recording. The flapping device came back on
  its own (or was power-cycled) -- the physical check ask STANDS:
  this device has now flapped across two incidents (Aug-31 blip,
  today's 4.5h outage) and dropped four cameras for 4.5 hours.
  Find it, check its PSU/power, plan replacement.
- ext3: if it stays dark past ~1h after the other four recovered,
  it may have its own fault (the Aug-31 pattern: 3 of 5 recovered,
  2 did not -- ext3 was one of the two). Watch continues.

## Amendment 7 (c188, 10:22 UTC): recording-truth timeline + the .2 bridge discovery

Two corrections and one new device. All times UTC; all recording
evidence epoch-based (law 18 applied: `-newermt` date strings are
parsed in sophon LOCAL time, so every date-string probe this cycle
was re-run with epoch cutoffs -- the first pass of this cycle
manufactured a second phantom "all dark" before the correction).

### Corrected timeline (recording mtimes, epoch-verified)

- 05:28:20-36 -- all five die (unchanged).
- 07:46-47 -- ext5/int1/int2 recover (unchanged).
- 08:09:50 -- ext5/int1/int2 die again (hour-08 segments end at
  minute 09; amendment 3's 08:08:50-08:09:56 stands).
- 09:40:53-09:45:38 -- the FOUR recover (int1 09:40:53, int2
  09:40:56, ext5 09:42:06, ext4 09:45:38). Amendment 6's
  "09:45-47" was approximate; the true window is 09:40-09:45.
  ext4 was dark 4h17m (05:28 -> 09:45) -- it never joined the
  07:46 partial recovery.
- ext3: last segment ever 05:28:36. Dark 4h54m+ and counting.

Current state: 7/8 recording (segment ages 2-12s). ext3 (.103) is
network-dead: zero packets on the wire in a 20s tcpdump, ARP
FAILED, no ping, no RTSP, no HTTP. It is crash-looping in frigate
(~6 restarts/min) -- frigate-side noise only, the camera is gone.

### NEW DEVICE: Mercury/TP-Link bridge at 192.168.2.2

- MAC 0a:8a:f1:0a:62:56, web UI = "mercury" theme + tpEncrypt.js
  (TP-Link budget line, v202310110933). HTTP 200.
- NOT present in the c183 census (07:20 UTC) -- it appeared on the
  LAN between 07:20 and 10:18 UTC. OR it was there but unreachable
  during the outage window and came back with the recovery.
- MAC-LEVEL PROOF it bridges ext4: every .104 packet on the wire
  carries src MAC 0a:8a:f1:0a:62:56 (tcpdump -e). The camera at
  .104 answers RTSP 401 (real thingino) but ALL its traffic flows
  through the .2 device. .105/.201/.202 answer with their true
  MACs (direct); only .104 rides the bridge.
- It proxy-ARPs: answers who-has .101/.104 with its own MAC
  (winning some races -- kernel cache flips between the camera's
  true MAC and the bridge MAC). This is the Aug-31 MAC-collision
  mechanism, LIVE: Aug-31 the same MAC (0a:8a) was seen answering
  for .100 (where cam2-4 resurrected). One bridge, multiple ghost
  IPs (.100 .215 stale entries, .2 now).

### Reading (revised)

- The five-cam shared-device theory needs a REVISION: only .104 is
  proven to hang off the .2 bridge. The other four answer directly.
  What the five still share is unknown -- possibly a WiFi AP
  (the BE230 at .55 is a candidate) or a PoE path. The
  simultaneous death + staggered recovery pattern still says
  shared upstream, but the shared device is NOT identified yet.
- .103 is a CHRONIC camera: dead in both incidents, never
  self-recovers, no proxy path, zero packets. It needs a power
  cycle at minimum, likely replacement (two incidents, same
  total failure).
- The .2 bridge is a new witness and a new suspect: it appeared
  (or returned) during this incident window, it carries ext4's
  traffic, and it proxy-ARPs camera IPs (cache pollution that can
  break other hosts' view of the cameras). If Nacho knows what
  this device is, that answers part of the topology.

### Physical ask (sharpened)

1. Identify the Mercury/TP-Link device now at 192.168.2.2 (MAC
   0a:8a:f1:0a:62:56). Is it a WiFi extender/CPE? What feeds it?
2. .103 (cam2-3): power cycle. Two incidents, never self-recovered.
3. The shared-path question for .103/.104/.105/.201/.202 remains
   open: find what they share (AP? PoE bank?) that .101/.102/.203
   do not use.
4. The MAC-cache race (0a:8a proxy-ARP winning races for camera
   IPs) is worth killing at the source once .2 is identified --
   a wrong-MAC cache entry on sophon makes cameras look dead or
   misattributed (the Aug-31 identity-theft class).

## Amendment 8 (c189, 10:55 UTC): device identification + the .2 SSH door

Deep-probe cycle on the two chronic unknowns. Findings:

- CAMERA IDENTITY MAP COMPLETE (runtime-config.js, all 8):
  .101=cam2-3, .102=cam2-2, .103=cam2-?(dark), .104=cam2-4,
  .105=cam2-5, .201=ptz-1, .202=ptz-2, .203=ptz-3. All same
  firmware (personal_cam2_t31x_gc2053_atbm6031, stable+12445a6,
  2026-05-25; ptz build 10:57:50). So the five dark = cam2-3 (.103),
  cam2-4 (.104), cam2-5 (.105), ptz-1 (.201), ptz-2 (.202) -- and
  the alive three = cam2-2 (.102), cam2-3 (.101), ptz-3 (.203).
  NOTE the hostname numbering vs IP numbering is offset by one for
  the .10x block (cam2-3 is at .101, cam2-2 at .102) -- worth
  knowing before anyone renumbers.
- .103 (cam2-3): CONFIRMED network-dead, not just RTSP-dead. ARP
  broadcast gets ZERO replies (arping 0/2, 0/3; tcpdump sees the
  requests leave, nothing answers -- not even the .2 bridge
  proxy-ARPs for it). HTTP 000, ICMP 100% loss. It is powered off,
  bricked, or fully isolated. Power cycle + likely replacement
  stands.
- .2 Mercury device: web UI is a JS shell (all app paths 403/405
  without a session; version meta v202310110933; tpEncrypt.js).
  BUT it also runs SSH on :22 -- legacy crypto only
  (diffie-hellman-group1-sha1, ssh-dss host key). OpenSSH 10
  refuses both by default; the offer pattern (group1-sha1 + dss) is
  the classic **Dropbear-on-embedded-TP-Link** signature. I could
  not complete a handshake with modern ssh flags (HostKeyAlgorithms
  ssh-dss is rejected outright by OpenSSH 10 -- DSA removed). If
  Nacho wants in: `ssh -oKexAlgorithms=+diffie-hellman-group1-sha1
  -oHostKeyAlgorithms=+ssh-dss` from a host with an older OpenSSH
  (or a yoga-side attempt), or the web UI with a browser session.
- The .2 device is NOT a camera (no RTSP, no thingino UI). Its
  proxy-ARP of camera IPs (.101/.104 answers) + carrying ALL of
  .104's traffic says: it is a WiFi extender/CPE in bridge mode
  with cam2-4 (.104) as its wireless client. The atbm6031 in the
  cam2 build string is a WiFi chip -- consistent.
- .215/.100 remain dead (no ARP replies from anything now).

### Revised physical ask (unchanged in substance, sharpened)

1. .103/cam2-3: power cycle. If it stays dead, replace -- two
   incidents, zero self-recovery, zero L2 presence.
2. Identify the .2 Mercury device physically (which room, what
   feeds it). It carries ext4's traffic; if it flaps, ext4 flaps.
3. The shared-path question for the five stands (AP candidate:
   BE230 .55).
4. Optional: legacy-SSH into .2 (Dropbear signature) to read its
   config -- would settle what it bridges and whether its
   proxy-ARP can be disabled.

## AMENDMENT 8 (2026-09-11 ~12:35Z, aria c191 -- flapping ONGOING; c189 "chronic/network-dead" verdict CORRECTED)

Full flap timeline (UTC, epoch/journal-verified):
- 05:28:20 all five dark
- 07:46-47 ext5/int1/int2 up
- 08:08:50-09:56 those three down again
- 09:40:53-09:45:38 int1/int2/ext5/ext4 up (ext3 STAYS dark)
- 12:08-12:11 all five down again (3-4 min window)
- ~12:12 all five up INCLUDING ext3
- 12:31 verified: all 8 cameras recording, fresh segments, ext3
  HTTP 200, arping answered (via .2 bridge MAC as always)

CORRECTIONS to my own record:
1. c189's ".103 network-dead, chronic, never self-recovered" was a
   DOWN-WINDOW snapshot. ext3 self-recovered at the 12:12 flap-up
   after 6h44m dark. The camera is not dead; the shared device
   flaps and ext3 is the slowest to re-associate (missed the
   09:40 recovery wave, caught the 12:12 one).
2. The physical ask is SHARPENED, not resolved: 6+ power
   transitions today (2h18m, 22m, 1h31m, 2h28m dark windows;
   up-windows 22m-2h28m). Irregular timing = dying PSU / loose
   connection / thermal cycling on the shared device. Every up
   window is borrowed until the device is found.
3. fleet-feed FAIL=1 (09:03Z run) was mid-outage; the 15:02Z run
   should show FAIL=0 if the flap holds. Fear-organ watch state
   continues until then.

Status: ACUTE incident closed for now; CHRONIC flapping confirmed
as the real failure. Everything else in this filing stands.



## Amendment 9 (2026-09-11 13:32 UTC, c193, aria)

Flap timeline CLOSED for the acute incident: all 8 cameras recording
since ~12:12Z (verified again 13:19Z pulse: frigate active, segments
fresh). Chronic flapping ask unchanged: 6+ power transitions today,
irregular timing = dying PSU / loose connection / thermal on the
shared device feeding the five. Physical ask (find device, check
PSU, plan replacement) remains OPEN under this filing.

Also noted this cycle: 45.148.10.62 (TECHOFF SRV, AD/GB) scanning
camaras.randazzo.ar since Sep 8, ~34 req/24h, all vuln-path probes.
All 200s are the Frigate SPA catch-all serving the app shell -- NOT
file disclosure; /api/* verified 401 from outside. Auth posture OK.
Minor gap: fail2ban does not watch the frigate/Caddy log path.
PROPOSED (aria, session XV -- NOT A NACHO RULING; pending, 2026-09-11 ~14:35 UTC, interactive w/ Nacho):
(1) Acute incident: CLOSED (all 8 recording since 12:12Z).
(2) Chronic flapping: the shared device feeding the five is likely
dying PSU / loose connection / thermal. Nacho will do the physical
walk (find device, check PSU) this evening; aria supports with
timing data. Replacement plan if it flaps again.
(3) .2 Mercury device: leave for now (identity + legacy-SSH read
optional, later).
(4) fail2ban gap on frigate/Caddy log path: noted, low priority.
ANSWER (session XV, 2026-09-11 ~14:50 UTC, Nacho ruling):
(1) PSU/HARDWARE RULED OUT by Nacho's own pre-aria debugging: when
cameras went dark he walked up to them -- POWER LIGHT ON. The feed
is a plain wall charger (nothing to fail). The dark state is
NETWORK-level, not power.
(2) WORKING HYPOTHESIS (Nacho): firmware/software. Candidates: the
atbm6031 WiFi driver/firmware hanging (chip is in the build string
personal_cam2_t31x_gc2053_atbm6031; cheap IoT WiFi silicon, hang-
prone), AP-side flap (.2 Mercury bridge carries ext4; .55 BE230
candidate shared AP), or thingino network-stack wedge. The .2
proxy-ARP going silent for dark cameras fits WiFi disassociation
(bridge only answers for reachable clients).
(3) METHOD MANDATE: investigate via SSH (keys installed on all 8).
Cameras run linux. No more L2-only inference chains -- read the
cameras' own logs/state.
(4) Daily reboot cron: evaluate with data (does it clear WiFi driver
state? does the flap correlate with reboot times? it does NOT --
flaps hit 05:28Z, reboots are 01:00-06:00 staggered local).
INVESTIGATION (session XV, 2026-09-11 ~15:00 UTC, aria -- first SSH
camera walk, per Nacho's method mandate):

## Topology map (verified, all 8 cameras)

ALL EIGHT CAMERAS ARE WIFI (wlan0, atbm6031 driver, no ethernet).
Two SSIDs, two APs:
- nacho_guest -> BSSID 72:7f:f0:1e:4a:a8 = the .55 BE230 (wlan
  virtual MAC of 68:7f:f0:1e:4a:a8). Cameras: .101, .102, .105,
  .201, .202, .203.
- nacho_camaras -> BSSID 08:8a:f1:6a:62:56 = the .2 Mercury box
  (wlan virtual MAC of 0a:8a:f1:0a:62:56 -- same OUI 8a:f1).
  Cameras: .103, .104 ONLY.

## The flap correlation (fits the dark-five timeline)

The five dark cameras (ext3/ext4/ext5/int1/int2 = .103/.104/.105/
.201/.202) span BOTH APs. But: .103/.104 ride the .2 Mercury box;
.105/.201/.202 ride .55. Two failure modes fit:
(a) .55 BE230 flapping (drops 3 of 5) + .2 Mercury flapping
    (drops the other 2) -- two devices, similar timing;
(b) ONE upstream common point (router .1 / ISP) resetting WiFi
    radios or DHCP, hitting both APs' clients at once.
Simultaneous 05:28:20 stop across both APs' clients leans (b):
a single upstream event (router reboot/ISP DHCP renewal) would
deauth every STA at once; recovery timing then varies per camera
by re-association speed (ext3 slowest -- 6h44m, missed the 09:40
wave, caught 12:12).

## Camera-side evidence (dmesg, atbm6031)

- Boot-time association is CLEAN (join -> associated -> keys ->
  connecting done, ~55s after boot on every camera).
- ZERO deauth/disassoc lines in the CURRENT uptime on all five
  dark-capable cameras (dmesg ring only holds this boot -- 5.1h
  for all five, bounded by the staggered reboots).
- wpa_supplicant bgscan="simple:30:-70:3600" on every camera.
- .103/.104/.105/.201/.202 all booted 5.1h ago = the 12:12Z flap-up
  recovery was NOT self-reassociation -- it was the REBOOT CRON
  wave (reboots 3:00-7:00 local = 5.1h before 14:50). Correction to
  amendment 8: "ext3 caught the 12:12 wave" -- the 12:12 recovery
  IS the cron wave, not a flap-up. All five rebooted within their
  3:00-7:00 local staggered window and came back clean.

## Key inference

The cameras do NOT deauth on their own (zero deauth lines while
up). The dark windows are either AP-side or upstream-side
disconnections where the camera's supplicant sits in scan/retry
silence (dmesg ring buffer may also wrap during long dark windows).
Next instrument: persistent wifi-event logging on one camera
(logread -> a file that survives dmesg wrap) + sophon-side flap
correlation with .55/.2 reachability. Also: .2 Mercury carries
nacho_camaras ONLY (2 cameras) -- if .2 is the flapper, moving
.103/.104 to nacho_guest (.55) is a one-line wpa_supplicant.conf
change per camera (reversible, would isolate the variable).

Standing watch: sophon-side pings to .55 and .2 every cycle,
correlated with camera dark events.
ANSWER (session XV, 2026-09-11 ~15:05 UTC, Nacho ruling -- SUPERSEDES
the move experiment):
(1) NO CAMERA MOVES. nacho_camaras (.2 Mercury) is a REPEATER Nacho
installed precisely because nacho_guest (main AP) has LOW SIGNAL in
those areas. Moving .103/.104 to nacho_guest would make them fail
MORE, not less. Experiment withdrawn.
(2) WORKING HYPOTHESIS UPDATED: signal strength at the repeater edge
is the likely flap driver (weak-RF disassociation storms), possibly
aggravated by upstream events. May be something we ACCEPT.
(3) STANCE: these cameras are non-critical -- family check-in on
alarm events when away from the house. Some downtime is acceptable.
No heroic remediation. Watch downgraded to: existing fleet-check +
fear-organ monitoring (already live), plus the persistent wifi-event
logger on ONE camera as a cheap passive instrument if I want the
data. No config changes without a new ask.
