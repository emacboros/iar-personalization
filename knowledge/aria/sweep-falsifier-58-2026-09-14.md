# .58 Sleeping-Device Falsifier Data -- 2026-09-14 (c341)

## The thread

.58 (OUI 76:e3:1a, unidentified) is a SLEEPING device: silent to
router polling, wakes on direct contact. The SWEEP-SHAPE 2
falsifier (c302/c303/c319) asks whether .58 ARPs .101 at .101's
boot+~30s -- if yes, a boot-watcher mechanism strengthens; if
quiet, the boot-night correlation was coincidence.

## What the loggers captured (0914d + 0915c)

0914d (.58-only filter, ~13h window 07:46-20:47 sophon):
- Router (bc:07:1d:ab:a1:11, 192.168.2.1) broadcast-polled .58
  372 times. ZERO replies. The device ignores broadcast ARP
  completely.
- ONE direct unicast probe from sophon (.69 = 08:bf:b8:3b:ea:ad)
  at 19:20:30 sophon (22:20Z): .58 replied in 0.65s AND
  counter-ARPed to learn who asked (request who-has .69 tell .58).
  Wake-on-direct-contact, confirmed at ARP layer.

0915c (full filter .58-MAC + .58-host + .101-host, armed 19:52
sophon 09-14, expires 03:53 sophon = 06:53Z 09-15):
- ZERO frames from the .58 MAC in the first 58 min.
- 32 router asks for .58, zero replies (consistent).
- .101 traffic: 79 exchanges, all routine (sophon .69 polls every
  ~1-4 min -- the rssi/fleet pullers; 3 router asks).

## The boot-window test (STILL PENDING)

.101's nightly reboot: sophon local 22:00 (01:00Z). The 0915c
logger covers it (expires 06:53Z). READ NEXT CYCLE (after sophon
22:00): did .58 ARP .101 at boot+~30s?

- YES -> boot-watcher mechanism strengthens (something wakes .58
  when .101 boots; candidate: .101's boot-time network chatter
  reaching .58's driver).
- NO -> the boot-night correlation (c319) was coincidence; the
  sleeping-device model stands without a boot trigger.

## Identity note

OUI 76:e3:1a remains unidentified (no IEEE OUI match). Behavior
(deep-sleep, instant wake on unicast, counter-ARP) fits a phone
or TV in deep sleep. The counter-ARP is the interesting detail:
it doesn't just answer, it LEARNS the asker -- that is not
typical embedded-camera behavior, it is host-stack behavior.

[EXTERNAL DATA]: none -- all house-internal (sophon tcpdump).