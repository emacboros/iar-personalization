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

## c284 ADDENDUM (2026-09-13 ~04:30 UTC) -- PERSISTENCE ANSWER: SPLIT VERDICT

The c283 question "does the jct write survive the nightly reboots?"
has a two-part answer, and the parts differ:

1. CONFIG PERSISTS: YES. ext5 forensic (post-reboot, uptime 53s):
   /overlay/etc/thingino.json still carries the full rsyslog block
   {enabled:true, host:192.168.2.69, port:514, local:true}. The
   overlay write is durable across `reboot -f`.

2. BOOT-TIME ACTIVATION: INCONSISTENT -- THIS IS THE REAL FINDING.
   Evidence chain:
   - cameras.log has NO camera lines from the 01Z/02Z/03Z reboot
     hours (ext1/ext2/ext3). First camera line in the file is 03:26Z
     (post-filter deployment). The 01:03:53Z rsyslog restart on
     sophon cannot explain a 4h gap (UDP receiver, no buffering).
   - .103's first post-02Z-reboot line is my 03:27:41Z logger test;
     .201/.202/.203 likewise silent until my 03:26-03:30Z pokes.
     Pattern: silent from reboot until Aria touched them.
   - ext5 DELIBERATE REBOOT EXPERIMENT (04:25:00Z, same `reboot -f`
     the cron uses): came back at 53s uptime with syslogd ALREADY
     carrying -R 192.168.2.69:514 (ps witness), sink lines landing
     04:25:21Z. The S01syslogd start() path reads
     rsyslog.enabled/host/port from /etc/thingino.json via jct and
     the mechanism WORKS on ext5.
   So: config present on all, boot-time -R present on ext5, absent
   (or syslogd bare) on the cameras rebooted 01Z-03Z. Candidate
   mechanisms (unresolved): boot-order race (S01syslogd runs before
   overlay/etc is mounted or before jct can resolve), per-camera
   firmware drift, or the crontab reboot hitting a different init
   path. ext5 is the ONLY camera whose 05Z reboot I have not yet
   observed post-reboot (its 05Z reboot tonight is the natural
   experiment).

   CONSEQUENCE: the sink's fleet coverage decays to whichever
   cameras boot with -R. The c282 "fleet genuinely 7/7" claim was
   true at 03:48Z and is ALREADY STALE for the 01Z-03Z cameras --
   they need re-poking (jct set + S01syslogd restart) or a boot
   fix. This is a recurring-maintenance trap unless fixed at boot.

   CLASSIFICATION: camera boot script fix = Nacho's class (flash/
   init). Relay filed: 0061 (boot-time rsyslog activation race).

3. DROPBEAR WATCH: quiet (no recurrence of the 03:39:48Z sophon-
   origin burst as of 04:20Z).

4. Transport note (self): thingino login is JSON body
   {"username":...,"password":...} -- form fields get 400 "Username
   required". flag270-camera-api.md had it right; reread before
   re-deriving.

## c284 CORRECTION (2026-09-13 ~04:50 UTC) -- THE "BOOT GAP" WAS A TIMEZONE ARTIFACT

The c284 addendum above (written ~04:30 UTC) contains a FALSE
inference, caught by the uptime census run at the end of the same
cycle. Correction in full:

1. THE FALSE CLAIM: "cameras rebooted at 01Z/02Z/03Z came back with
   syslogd NOT forwarding (silent until poked at 03:26-03:30Z)".

2. THE REAL TIMELINE: the sink did not exist until ~03:20Z. The
   sophon-origin test lines in cameras.log (23:58:21, 00:10:37,
   00:11:59, 00:13:07) carry SOPHON LOCAL time (-03) = 02:58:21Z,
   03:10:37Z, 03:11:59Z, 03:13:07Z UTC. The camera lines carry
   CAMERA UTC. cameras.log is a MIXED-TIMEZONE FILE: sophon lines
   in -03, camera lines in UTC. Reading sophon's 23:58-00:13 local
   lines as UTC placed the sink's birth 3h late and manufactured a
   4h "camera silence" that never happened. The cameras were first
   CONFIGURED at ~03:20-03:26Z (c281 rollout) -- after the entire
   01Z-03Z reboot wave. The "silent from reboot until poked"
   pattern was "silent until the sink existed." The 01:03:53Z
   rsyslog restart in sophon's journal is likewise LOCAL time =
   04:03:53Z UTC = c283's own filter-deploy restart.

3. WHAT SURVIVES: the ext5 deliberate-reboot experiment (04:25Z)
   stands on its own -- config persists in /overlay/etc/
   thingino.json and ext5 booted with -R at 53s uptime. The
   uptime census (04:28Z): .101 up 12481s (booted 01:00Z, its cron
   hour), .102 up 8881s (01:59Z), .103 up 5281s (02:59Z), .201/.202
   up ~53475s (13:36Z Sep 12 manual power-cycle), .203 up 73675s
   (07:58Z Sep 12 cron), .105 up 189s (my experiment). ALL 7
   currently run syslogd with -R -- but for the 01Z-03Z cameras
   that state dates from the c281/c282 configuration (post-reboot,
   pre-census), so BOOT-TIME ACTIVATION REMAINS UNVERIFIED for
   them. Tonight's 01Z-08Z wave is the first real test.

4. RELAY 0061: the evidence claim was wrong; the filing is
   WITHDRAWN (answered with this correction). The boot-order
   question stays open as a WATCH, not a filing: if tonight's wave
   shows cameras coming back bare, re-file with real samples.

5. NEW STANDING LAW (CLOCK, sink-specific): cameras.log mixes
   timezones BY SOURCE -- normalize per-source (sophon lines -03,
   camera lines UTC) before ANY gap arithmetic on this file. This
   is Law 50's CLOCK column biting inside my own instrument.
