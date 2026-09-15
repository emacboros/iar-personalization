# .101 boot+2s malformed-SOAP burst + the router's .58 refresh loop (c359, 2026-09-15)

## What this cycle found

Two findings from the standing ARP captures (0915c/d/e + 0916a, sophon
enp10s0, ARP-only, camera-subnet):

### 1. The router's .58 refresh loop (NEW, benign, router-side)

bc:07:1d:ab:a1:11 (the gateway, 192.168.2.1) probes 192.168.2.58
CONTINUOUSLY: ~0.5 probes/min (74 in 7h in 0916a; ~30/hour across all
captures), 1-2 packets per burst, median burst gap ~94-222s. It probes
NOBODY else at this rate (only .201, which was rebooting -- cache
invalidation). .58 NEVER answers any of them (asleep; c341 deep-sleep
model: ignores broadcasts, answers direct unicast only).

Interpretation: the router holds a STALE ARP entry for .58 and keeps
trying to refresh it, forever. This is router-side background noise,
NOT .58 activity. It does NOT correlate with sweeps (probes ran all
night Sep 14-15; zero sweeps in that window).

Corollary for 0062: the sweep trigger is NOT the gateway probes. The
c288 trigger model (sweep fires on .58 wifi rejoin / gratuitous ARP)
stands. Sep 14-15: no .58 rejoins (zero .58-source packets except the
22:12:16 sophon direct contact), zero sweeps. Consistent.

### 2. .58 awake-window confirmed with cleaner data

22:12:16 local Sep 14: sophon direct unicast -> .58 replied in 0.65s +
counter-ARP (who-has .69 tell .58). Then ZERO .58 packets through
05:45 (0915d/e + 0916a). Router probes before contact: 22 in 29min
(0.76/min); after: 49 in 107min (0.46/min) -- roughly constant, not
event-correlated. Deep-sleep model holds a 7th time.

### 3. The Sep 14 01:00:30Z .101 boot+2s event -- REINTERPRETED

c302/c344 called the Sep 14 01:00:30Z sweep "one-off" and closed the
boot-timed hypothesis. This cycle found the event is NOT the fleet
sweep class at all:

- Fleet sweep signature: 8-16 XML-parse errors per camera, serial
  across ALL 7 cameras over ~8s.
- Sep 14 01:00:30Z: 19 malformed-SOAP errors on .101 ALONE, in <1s.
  Other 6 cameras: ZERO errors that day. (.101 camlog, verified.)
- .101 booted 01:00:28Z (camlog "Ciao"; rssi uptime reset between
  epochs 1789347600 -> 1789347720). onvif_simple_server started
  01:00:29-30. The burst arrived the MOMENT its HTTP server came up.
- Same second: .101 sent who-has 192.168.2.58 (broadcast, tell .101)
  x3 -- resolving .58 from a fresh boot. Something in .101's config
  references .58. (Camera ssh is key-locked from sophon root; could
  not inspect config this cycle -- BatchMode law blocks nested hops
  without the camera key.)
- No ARP capture covers that window (0915a/b/c/d all START after it;
  the pcap starts 23:36 local). No fleet sweep Sep 14-15 anywhere.

So the boot+2s event is a DIFFERENT class: a single-camera,
boot-timed malformed-SOAP burst, source unknown, seen exactly once.
Falsifier armed: 0916b logger (sophon, pid 999271, expires ~23:20Z
Sep 16) covers tonight's .101 01:00:28Z boot (Sep 15 22:00:28 local).
If the burst recurs at boot+0-2s: boot-timed class real, and the
0916b capture may catch the source (ARP layer at least). If quiet:
one-off stands, file stays closed.

### 4. 401-burst class (c346): no recurrence

.101 x1 + .102 x5 at 00:34:05Z Sep 15 remains the only sighting.
No new 401s Sep 14-15 on any camera. Watch continues passively.

## Instruments

- ext1-freeze-check.sh (knowledge/aria/bin/, committed ea3babf4):
  direct go2rtc producer receiver delta probe via machinectl ->
  frigate container. Verified live: ext1 audio receiver STILL frozen
  (video +136KB/6s, audio +0/6s). Detector class B stands; the
  01:03Z Sep 16 heal falsifier (0073) is next.
- 0916b ARP logger armed (covers .101 boot + .58 + .201).

## Open questions

- What in .101's boot references .58? (needs camera config access;
  Nacho holds the camera key path)
- Who POSTs malformed SOAP to a camera the second its HTTP server
  exists? (WiFi-side, unicast to .101 -- sophon cannot see it; only
  a camera-side tcpdump or the 0916b ARP correlation can help)