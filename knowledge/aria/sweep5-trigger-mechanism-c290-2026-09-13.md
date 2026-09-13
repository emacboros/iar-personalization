# SWEEP5 + TRIGGER MECHANISM (c290, 2026-09-13)

## What happened this cycle

Sweep 5 fired at 07:21:03-09Z and was caught by the ARP logger c289
armed. Fifth consecutive sweep correlated to .58 -- the attribution
is now standing evidence, not a one-night correlation.

## Sweep5 correlation (sophon local = UTC-3; camera logs UTC)

| cam  | .58 ARP (local)  | onvif error (UTC) |
|------|------------------|-------------------|
| .102 | 04:21:03.59      | 07:21:03          |
| .101 | 04:21:03.84      | 07:21:03-04       |
| .201 | 04:21:04.02      | 07:21:04          |
| .203 | 04:21:04.22      | 07:21:04          |
| .105 | 04:21:04.88      | 07:21:05          |
| .202 | 04:21:05.05      | 07:21:05          |
| .103 | 04:21:05.85      | 07:21:06          |

All 7 alive cameras, second-level match. Per-camera POST census
(distinct onvif_simple_server PIDs = spawned per request): 6-8 POSTs
per camera (101:8, 102:8, 103:6, 105:7, 201:8, 202:7, 203:8) -- the
client enumerates multiple operations per camera. .104 (power-dead)
got nothing -- it cannot answer ARP, and the client skipped it.

## The trigger, corrected (c288 detail amended)

c288 said "camera ARP-resolves .58 -> sweep 23ms". Re-examined against
the raw captures this cycle: that 23ms was the gap between .58's ARP
to a camera and the onvif POST landing -- the ARP is the ONVIF client
resolving its target, INSIDE the sweep, not the sweep's trigger.

The real trigger is a .58-side network event:

- sweep3 (06:21Z): gateway ARP-ed for .58 3x (03:20:55-57 local) ->
  .58 ARP-ed gateway (03:21:03.9) -> sweep 03:21:11.1 (7s later).
- sweep4 (06:27Z, c288): .58 wifi rejoin probe -> sweep 0.2s later.
- sweep5 (07:21Z): DAD probes (who-has .58 tell 0.0.0.0 x3) +
  gratuitous announce at 04:21:01.17-.37 local = a wifi JOIN ->
  first camera ARP 04:21:03.59 (2.3s later).

UNIFIED: .58's wifi stack wakes (join/rejoin/roam/renew) -> its ONVIF
discovery client sweeps the camera subnet within ~0.2-14s. The sweep
is tied to .58 network-layer wakeups, not to camera traffic.

## Falsification experiments (both negative, this cycle)

1. sophon pinged .58 (07:24:31Z): .58 replied (211ms RTT), ARP-ed
   sophon back. NO sweep in 3min.
2. .103 pinged .58 (07:27:40Z, via thingino run.cgi): .58 replied,
   ARP-ed .103 back. NO sweep in 3min.

Incoming ARP/ping alone does NOT trigger the sweep. The trigger is
internal to .58 (its own wifi events). This also kills the "camera
ARP wakes it" reading of sweep3.

## .58 identity addendum

- MAC 76:e3:1a:69:e3:9c (kernel neigh + -e capture confirmed).
  Locally-administered (randomized), consistent with c288's Fedora
  privacy-extensions reading.
- Idle behavior: ARPs gateway every ~2min when active; nothing else.
- 5 sweeps today (05:00, 05:43, 06:21, 06:27, 07:21Z); gaps 43m, 38m,
  6m, 54m. Cadence = event-driven (wifi wakeups), confirmed again.

## Instruments

- ARP logger re-armed with -e (MAC detail) at 04:24 local ->
  /tmp/arp-reqs-0913d.txt, 90min (to ~05:54 local / 08:54Z). Stale
  loggers (0913c pair + 1558582) killed to stop double-capture.
- Note: /tmp/arp-reqs-0913.raw is NOT a pcap -- it is the ASCII
  stdout of the c288 logger (file(1) says ASCII text). Cannot
  tcpdump -r it. MAC detail was lost in c288's captures; -e fixes
  that going forward.

## What would close this class

Nacho answers relay 0062: what/whose is snsv.local (.58). Then it is
either a known device with a noisy app (class closes) or an unknown
machine worth watching (class opens). Until then: log every sweep
with its .58-side trigger event; the -e capture now records MACs.

[EXTERNAL DATA]: none -- all primary evidence from sophon captures
and camera logs.