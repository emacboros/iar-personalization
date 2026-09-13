# CAMERA SYSLOG SINK -- LIVE (c281, 2026-09-13 ~03:28 UTC)

## What this is

All 7 alive thingino cameras now forward syslog over UDP 514 to sophon
(192.168.2.69), landing in /var/log/cameras.log. The 306-line logread
ring buffer (the thing that made the camlog puller go "empty snapshot"
~5h after each camera's last real log line) is no longer the only
witness. The full log stream is continuous and survives camera reboots
only in the sense that each reboot re-emits its boot lines -- which is
exactly what we want to see.

## The chain (every link verified live)

1. Camera: /etc/thingino.json rsyslog.{enabled,host,port,local} set
   (enabled=true, host=192.168.2.69, port=514, local=true -- local kept
   so logread still works for the puller).
2. Camera: /etc/init.d/S01syslogd restart -> syslogd now runs with
   `-R 192.168.2.69:514` (busybox syslogd forwards UDP).
3. sophon firewalld: rich rule added (PERMANENT) -- source
   192.168.2.0/24, udp dport 514, accept, zone FedoraWorkstation.
   THE TRAP: the zone's standing rule accepts udp 1025-65535; 514 is
   BELOW 1025, so the high-port accept never covered it. tcpdump saw
   packets arriving while rsyslog received nothing -- firewall drop,
   not rsyslog failure. ~25 minutes spent proving rsyslog innocent.
4. sophon rsyslog: /etc/rsyslog.d/30-cameras.conf -- imudp input bound
   to 192.168.2.69:514, rule: if $fromhost-ip startswith "192.168.2."
   then /var/log/cameras.log & stop. Verified: local logger test lands,
   camera crond lines land, camera logger tests land from .102/.103/
   .105/.201/.202/.203.

## Verification at deploy time

- Local test (logger -n 192.168.2.69): ARIA-C281-LOCALTEST landed.
- 103 crond RSSI lines landing every minute since 03:26Z.
- logger tests from .102/.103/.105/.201/.202/.203 all landed.
- .104 (power-dead, relay 0059 family) absent as expected.
- tcpdump -i any confirmed packets arrive In enp10s0; before the
  firewall rule they were captured but never delivered.

## What this enables

1. BackchannelStreamState sessions (the wave fingerprint) now stream
   continuously -- no more 15-min pull cadence or 306-line ring loss.
   A wave's camera-side witnesses are timestamped to the second.
2. Boot lines (the staircase census) land in real time.
3. The 08:10:22Z fleet RTP stall class gets a second witness source:
   camera-side syslog during the stall window.
4. The camlog puller becomes a BACKUP, not the primary witness.

## Open items

- PERSISTENCE CHECK: jct writes to /etc/thingino.json on a squashfs/
  overlay? If the config does not survive reboot, the nightly crontab
  reboots (01Z-08Z) will silently revert cameras one by one. VERIFY
  tomorrow: cameras.log should show boot lines from every camera at
  its crontab hour. If a camera's boot lines never arrive, its config
  reverted -- then the fix belongs in the camera's boot script, not
  jct (relay to Nacho if so).
- Log rotation: cameras.log will grow ~1 line/min/camera (RSSI cron
  noise) = ~10k lines/day/8 cams. Consider logrotate or a filter that
  drops crond lines at the rsyslog level. Watch disk (541G/1.9T used,
  no urgency).
- The RSSI cron noise now lands in cameras.log too. A `if $msg
  contains "cmd {" then stop` filter would keep it clean -- deferred
  until persistence is verified.

## Instrument-tax note

Predicted ~30min for the splice watch + close. Actual: this became a
~45min build (firewall trap + 7-camera rollout + verification). The
instrument tax is real and this was worth it: the wave detector's
primary witness source is now continuous instead of sampled.