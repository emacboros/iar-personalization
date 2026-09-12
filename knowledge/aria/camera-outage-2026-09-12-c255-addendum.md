# Camera outage 2026-09-12 -- c255 addendum (~15:15Z)

## What changed this cycle

The rssi ring buffers (pulled wholesale by rssi-puller, so the per-camera
.log IS the camera's /var/rssi.log) plus the uptime-column boot-clock law
give a per-camera freeze/reboot map that the earlier incident doc did not
have. This is the refined shape.

## Boot map (uptime col -> boot time, law-50 verified)

| cam | boot (UTC) | outage behavior |
|-----|------------|-----------------|
| .101 ext1 | 01:00:03Z | unaffected; rows continuous through outage |
| .102 ext2 | 02:00:03Z | unaffected; rows continuous |
| .203 int3 | 08:00:09Z | unaffected; rows continuous |
| .103 ext3 | 03:00:03Z | rssi rows STOP at 11:00:00Z; never returned |
| .104 ext4 | 04:00:02Z | rssi rows STOP at 11:00:00Z; never returned |
| .105 ext5 | 05:00:13Z | rows stop 11:09Z; REBOOTED 13:36:42Z |
| .201 int1 | 06:00:20Z | rows stop 11:09Z; REBOOTED 13:36:49Z |
| .202 int2 | 07:00:22Z | rows stop 11:09Z; REBOOTED 13:36:50Z |

The five affected cameras are exactly the ones whose hourly staircase
reboots (01:00Z-07:00Z) preceded the outage. The three survivors are the
ones whose staircase reboot happened later or earlier relative to the
event -- no, correction: the survivors simply did not freeze. The
staircase itself (hourly reboots) is normal fleet behavior and not the
cause.

## Refined timeline

- 08:10:39Z: frigate ext3/ext4 RTSP 404s BEGIN. go2rtc producers for
  exterior_3/exterior_4 died here. But .103/.104 stayed pingable and
  their rssi writers kept running (rows continuous 08:00-11:00, 60s
  intervals, no gaps). So 08:10Z = prudynt RTSP session death on the
  cameras, NOT camera death. This is a NEW earlier event the incident
  doc did not have.
- 11:00:00Z: .103/.104 rssi writers stop (last row exactly 11:00:00Z).
- 11:09:00Z: .105/.201/.202 rssi writers stop (last row 11:09:00Z).
- 11:10:00-11:10:22Z: frigate loses all five (c247 death window;
  watchdog crashes + 404s through 11:08-11:10).
- 13:36:42-50Z: .105/.201/.202 reboot, 8-second spread, full cold boot
  (syslogd start, firmware-default "May 25" pre-NTP labels, then NTP
  jump to 13:37). Post-reboot they are healthy: RTSP re-established
  (producer ids 37xxx), video + audio healthy (ext5=250, int2=249,
  int1=155 audio pkts in hour-15 segments).
- .103/.104: no ping, ARP FAILED, HTTP dead, RTSP dead, 4h+ down at
  15:15Z. Never returned.

## The 13:36Z reboot trigger (open)

8-second spread across three cameras, two of them PTZ (motors-daemon
present) and one not (.105). All three did a full cold boot. Candidates:
shared power circuit brown-out, a broadcast/wifi-recovery trigger, or a
common watchdog. The camlog boot blocks are BARE (11 lines for .105:
telegrambot/onvif/ledd only) -- consistent with power-on, not a clean
software reboot. .103/.104 did NOT reboot -- if the trigger was a shared
circuit, .103/.104 are on a different circuit (consistent with the c253
finding that Mercury serves .103/.104 while .55/BE230 serves the rest).

## Puller-log gap lesson (instrument schema)

rssi-puller logs only FAILURES to puller.log; success is silent (file
replace via mv). The 11:15-12:15Z failure rows for .105/.201/.202 plus
the ABSENCE of rows 12:30-13:30 in puller.log could be misread as
"recovered at 12:30" -- but the per-camera rssi.log has ZERO rows in
12:30-13:36, so the pulls kept failing; the failure rows for 12:30-13:30
exist (1789216218, 1789217119, 1789218019, 1789218919, 1789219819) and
I initially miscounted the window. Lesson: when a puller replaces its
output file wholesale, "no new rows" is the failure signal, and the
failure log is the authoritative timeline -- read BOTH, not the file
alone. (Law-50 family: the instrument's file is the camera's ring
buffer, not a puller-side append log.)

## Audio-death law status after this event

- ext2 (stale producer 27818, camera never rebooted): audio 1 pkt -- deaf. Law holds.
- ext1 (stale producer 27793, camera never rebooted): audio 250 pkts -- HEALTHY.
  This WEAKENS the law as stated: a stale session alone does not imply deafness.
  ext1's session predates the 02:00Z reboot too (27793 < 27818). Difference:
  ext1's session survived the 02:00Z staircase reboot of .101 (its producer
  was made AFTER .101's last reboot? No -- 27793 is pre-02:00Z). The working
  refinement: the law binds when the RTSP session predates the camera reboot
  THAT THE SESSION BELONGS TO. ext1's session was established after .101's
  01:00Z boot; .102's 02:00Z reboot happened while ext2's session was already
  established -> ext2 deaf. int3 (.203, session 28267, boot 08:00Z): session
  born AFTER the boot -> healthy. The camera-reboot-relative framing from
  c241-c242 stands; the "predates 02:00Z reboot" phrasing was ext2-specific.
- ext2 heal prediction UNCHANGED: heals at the 01:00Z staircase tonight
  (01:00Z Sep 13) when .102 reboots and the producer is remade. Watch after
  01:00Z.

## State at close

- Trio (.105/.201/.202): RECOVERED, healthy video+audio, post-reboot sessions.
- ext2: still deaf (control; heal watch 01:00Z tonight).
- ext3/ext4: DEAD 4h+ (11:00Z/11:09Z freeze, no recovery). Telegram #7 sent
  15:07Z with the 4h mark + power-cycle suggestion.
- 13:30Z NIC burst: no recurrence through 15:07Z (rx_peak 1.00 Mbps).
- Falsification window 14:00-18:00Z: contaminated by the outage (five
  cameras dark = reduced traffic); the saturation test needs a normal day.