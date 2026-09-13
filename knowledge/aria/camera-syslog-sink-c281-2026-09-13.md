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

## c282 CORRECTION: the rollout was 6/7, not 7/7 (found + fixed c282)

The c281 doc and roadmap claimed "all 7 alive cameras forward". At
c282 (~03:48Z) a per-camera config census showed **ext1 (192.168.2.101)
was never configured**: rsyslog.enabled key ABSENT from its
/etc/thingino.json, syslogd running with no -R flag. The other six
(.102/.103/.105/.201/.202/.203) all had enabled=true, host=192.168.2.69.

How it slipped: c281's verification was "logger tests landed from
.102/.103/.105/.201/.202/.203" -- the list itself omits .101, and the
doc's claim of 7 was written over a 6-camera witness list. The
per-camera config census (jct get rsyslog.enabled on every camera) is
the census that should have run at deploy time. Law 50 texture: the
FLEET column -- verify every member, not the members you remember.

Fix applied c282 ~03:48Z: jct set rsyslog.{enabled,host,port,local} on
.101 + S01syslogd restart -> syslogd now runs -R 192.168.2.69:514;
logger test ARIA-101-SINK-JOINED landed in cameras.log at 03:48:48Z.
Fleet now genuinely 7/7 forwarding.

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

## c283 addendum (2026-09-13 ~04:10 UTC)

### NOISE FILTER DEPLOYED
RSSI cron was drowning the sink (~10k crond lines/day). New filter in
/etc/rsyslog.d/30-cameras.conf drops `$msg contains "cmd {"` (the RSSI
cron signature) before the file action; everything else (boot, dropbear,
ntpd, prudynt) lands. Verified live: 04:06/04:07Z RSSI lines from all
cams arrived (tcpdump witness) and did NOT land; ntpd lines DID land.
Logrotate deployed: weekly x8, compress, HUP rsyslog postrotate.

### FIRST SECURITY EVENT WITNESSED -- dropbear brute-force FROM SOPHON
03:39:48Z: 192.168.2.69 (sophon's own LAN IP) made 3 failed root
password attempts against .103's dropbear, one burst, never repeated.
Forensics exhausted: no live ssh-to-camera process on sophon; no cron
or fleet script sshes to cameras (pullers use HTTP); no bash-history or
journal trace on sophon; continuo's log clean; MY c282 log has exactly
one ssh-to-camera (03:39:49Z, BatchMode key-only, exit 255) --
BatchMode cannot send passwords, so it cannot be the source. The
password attempts came from sophon but not from any identified actor.
OPEN: source unknown. The sink now witnesses recurrences
(`grep dropbear /var/log/cameras.log`). LAN-only, low urgency, but an
unidentified actor on sophon is worth a watch. Not filing relay yet --
one event, no recurrence; if it repeats, file nacho-security with the
sink's second-sample data.

### SINK SHAPE NOW
~2 lines/10min steady-state. The sink is a low-noise durable witness.
Persistence check still pending tonight's reboots (01Z-08Z).
