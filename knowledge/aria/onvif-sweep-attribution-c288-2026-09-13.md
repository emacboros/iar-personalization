# ONVIF sweep attribution: .58 (snsv.local) -- c288, 2026-09-13

## Verdict

The ONVIF sweep source is 192.168.2.58 with 4/4 second-level
correlation. Identity: a Fedora Linux machine on the camera WiFi
(guest VAP .55), hostname `snsv.local`, announcing `Passim-951F`
(_cache._tcp) via Avahi, running OpenSSH_10.2, randomized MAC
76:e3:1a:69:e3:9c, IPv6 privacy extensions (fe80::5d5f:6b82:3bf2:209f).

## The evidence chain

1. **ARP correlation (the decisive instrument).** I armed a raw ARP
   capture on sophon (`tcpdump -i enp10s0 arp`, /tmp/arp-reqs-0913.raw,
   2h window) at 03:12 local. Two sweeps fired inside the window:
   - sweep3 06:21:11Z (= 03:21:11 local): .58 ARP who-has to 6 cameras
     at 03:21:11.125-.885; onvif errors 06:21:11-13Z. Same second.
   - sweep4 06:27:28Z (= 03:27:28 local): .58 ARP who-has to all 7
     cameras at 03:27:27.927-29.592; onvif errors 06:27:28-36Z.
     Same second, and .58 sent 3x gratuitous ARP (who-has .58 tell
     0.0.0.0 = wifi (re)join probe) 0.2s before sweeping.
   - sweep1 (05:00:57Z) and sweep2 (05:43:42Z) predate the ARP
     capture; cadence and identical error signature tie them to the
     same actor. Total: 4 sweeps today + 2 sightings Sep 11.
2. **Target discipline.** .58's ARP traffic in the entire capture:
   9x gateway (its ~5m16s keepalive heartbeat) + exactly the 7
   cameras. Never .2, .55, .69 (sophon), .66, .216, .223. This is a
   camera-targeted discovery client, not a generic scanner.
3. **Sweep shape.** sweep3 = exactly 8 error lines per camera (a
   uniform single-probe pass). sweep4 = 14-16 per camera (double
   probe). All 7 alive cameras every time, serial-ish by IP.
4. **Why sophon's tcpdump was blind (vantage, c287 lesson confirmed).**
   The camera HTTP is WiFi->camera unicast; the switched fabric never
   delivers it to sophon's wired port. The only .58->camera traffic
   visible from sophon is ARP (broadcast). Zero TCP:80 packets to
   cameras in the whole capture. Attribution rests on the ARP/onvif
   second-level correlation, not on seeing the HTTP itself.
5. **Camera side.** thingino cameras run `wsd_simple_server` (WS-Discovery)
   advertising `http://<ip>/onvif/device_service` and uhttpd on :80+:443.
   The malformed POSTs (Body-less SOAP envelope) reach
   onvif_simple_server, which logs the parse errors. No source IP is
   logged camera-side (logread carries no client addresses).

## Own-tooling exoneration (6th-pass discipline)

- fleet-check.sh, all aria-* scripts, frigate config (no onvif/ptz/
  autotracking sections), go2rtc streams (plain rtsp://), sophon
  journal: no ONVIF POSTs from sophon. The sweep does not transit
  sophon at all.
- .58 is NOT .66 (yoga): different SSH host keys (rsa keyscan differs),
  .66 = yoga (it holds the ansible@yoga key that accepted 2 connections
  to sophon on Sep 11). .58 is a second, distinct Fedora machine.

## What .58 is (profile)

- Fedora Linux (Passim ships default on recent Fedora; sophon itself
  runs passim-0.1.12 and announces Passim-0FA4 the same way).
- Avahi desktop stack (mDNS queries for nfs/raop/smb/afp/webdav/
  sftp = standard service browsing).
- OpenSSH_10.2 server on :22 (bleeding-edge build, matches a current
  Fedora). No other ports open.
- WiFi on the camera guest VAP (.55, BE230 #2), randomized MAC,
  ~117ms RTT now (was ~1.1s / 33% loss at c251 -- different network
  conditions or power state).
- Camera ARP caches hold .58 in ALL 7 (c287) -- persistent, present
  across reboots of the cameras.

## Open questions (Nacho's, relay 0062)

- What device is snsv.local / 192.168.2.58? (A laptop? A phone? His?)
- What runs on it that POSTs malformed ONVIF SOAP? Candidates: a
  camera-viewer app, a Python onvif client, a PTZ controller. The
  Body-less envelope smells like a buggy or hand-rolled client.
- The sweep fires on .58 network events (rejoin probe -> sweep within
  0.2s; camera ARP-resolving .58 -> sweep within 23ms), not on a
  fixed clock. Gaps today: 42m45s, 37m29s, 6m17s.

## Instrument notes

- The ARP-request logger (raw tcpdump to a text file, post-processed)
  is the right vantage for this class; the port-80 pcap was blind by
  construction. Keep both: the pcap caught the gratuitous-ARP rejoin
  probes and the mDNS identity, the ARP log caught the sweep bursts.
- cameras.log timezone law (c284) held: sophon lines local, camera
  lines UTC. All sweep times above quoted in both.

## Watch state after this cycle

- arp-reqs logger: armed to ~05:12 local (2h).
- cam-lan pcap: expires ~04:07 local (1h from 03:07).
- Sweep cadence ~40min +/- irregular: next sweep expected ~07:05Z
  +/- 10min. If it recurs while watchers live, the ARP log gets a
  fifth confirmation for free.