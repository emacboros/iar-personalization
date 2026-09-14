# ONVIF sweep census c291 (2026-09-14 ~00:30 UTC)

## Clock-law resolution (the big one)
cameras.log + camlogs = CAMERA clocks = UTC. Sophon tcpdump = LOCAL (-03).
c288-c290 sweep timestamps were LOCAL; the ONVIF error timestamps are UTC.
After conversion, ALL 5 observed .58 sweeps match ONVIF error bursts
minute-for-minute:
- 04:21:01-05L (07:21Z) DAD x3 + self-announce -> sweep 2.2s -> 52 errs
- 05:11:14-15L (08:11Z) gw-ARP only -> sweep 9s -> 28 errs
- 05:12:34-35L (08:12Z) DAD x3 + announce -> sweep 0.15s -> 53 errs
- 05:27:49-50L (08:27Z) gw-ARP only -> sweep 8s -> 28 errs
- 05:43:55-56L (08:43Z) DAD x3 + announce -> sweep 0.05s -> 26 errs
The 05:11/05:27 "ARP-only" sweeps DID produce POSTs (28 errs each);
the earlier "no onvif at 05:11" reading was the UTC/LOCAL mixup.

## Sweep census
- 09-12: 7 sweeps 05:10-07:29Z (local 02:10-04:29), then 21.5h quiet.
- 09-13: 32 sweep-minutes 05:00-16:44Z (local 02:00-13:44), then quiet
  7.6h+ (ongoing at cycle time).
- Envelope = device awake hours; individual trigger = wifi events
  (DAD/announce = JOIN, gw-ARP = renewal/activity).
- .58 still on network (ARP DELAY, ping 1163ms RTT, 50% loss).
- Two sweep shapes: DAD+announce (JOIN) -> sweep within 0.05-2.2s;
  gw-ARP-only -> sweep after 8-9s (renewal path).

## Instruments
- arp logger re-armed 09-14 00:19 local: /tmp/arp-reqs-0914a.txt,
  filter ether src 76:e3:1a:69:e3:9c or host .58, -e, 4h window.
- cameras.log continues as UTC witness.
