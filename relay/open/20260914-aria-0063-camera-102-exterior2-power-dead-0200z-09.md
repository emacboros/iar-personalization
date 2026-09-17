# REQ 20260914-aria-0063
filed: 2026-09-14T02:17Z
filer: aria
class: nacho-external
state: open
urgent: no
title: camera .102 (exterior_2) power-dead ~0200Z 09-14
body: |
  Second camera power-dead: .102 (exterior_2) died ~02:00-02:15Z 2026-09-14.
  Signature matches .104: ARP INCOMPLETE, ping 100% loss, HTTP dead, camlog+rssi pulls fail.
  Death window: camera-side rssi.log stopped 01:45:00Z; last recording segment 01:59:52Z
  (written 02:00:21Z); first pull failure 02:00:18Z. Not a signal fade (rssi was -33 dBm).
  Note: rssi logger stopped 15 min BEFORE the camera died -- new precursor detail vs .104
  (simultaneous). Fleet-check now FAIL=1 (ext2 STALE + ext4 known-fault). Both .102 and
  .104 need physical power cycles. If power cycling does not revive them, both are on the
  same power path -- check the PSU/cable for that camera group.
  ADDENDUM 2026-09-14 ~10:15Z: .102 SELF-RECOVERED -- rssi back at 01:45Z (-32 dBm, strong),
  ARP/ping healthy in fleet-check 10:15Z. Either it power-cycled itself or Nacho cycled it.
  Remaining ask: .104 (exterior_4) still power-dead since 09-12 11:00Z (47h+) -- needs the
  physical power cycle. If cycling does not revive it, check the PSU/cable on that camera group.

  CORRECTION (aria c313, 2026-09-14 ~10:22Z): the c312 "self-recovered" reading was WRONG.
  The rssi.log tail (-32/-33 dBm at 01:44-01:45Z) is the LAST SAMPLE BEFORE DEATH, not a
  recovery. rssi-puller has failed on .102 every 15min since 02:00:18Z (puller.log, 9
  consecutive failures through 10:15Z); ARP INCOMPLETE, ping 100% loss, no recordings since
  01:59:52 local (mtime 02:00:21Z local). .102 is power-dead since ~01:45-02:00Z 09-14 UTC
  (~8.5h at correction time). Original filing stands in full: BOTH .102 and .104 need
  physical power cycles. Scar logged: law 50 (verify the DELTA/CURRENCY of a tail sample
  against the puller's own failure log before calling a state change).
  ADDENDUM (aria c319, 2026-09-14 ~13:15Z): DEATH PRECISION -- .102 died AT its
  scheduled nightly reboot, not "around" it. cameras.log: last activity 01:47:00Z
  (ntpd cron, healthy), then 02:00:00Z crond logged `reboot -f` (pre-exec) and
  NOTHING followed -- no boot banner, no lines since. The camera was alive and
  healthy 13 minutes before death; the reboot cron was the last thing it did.
  .102 SURVIVED the same reboot on Sep 13 (alive at 03:27Z, my ARIA-102-TEST
  marker). Leading hypothesis: power glitch/failure during the reboot itself
  (brownout at the moment of highest load, or the reboot exposed a failing PSU).
  Physical power cycle still the ask; if the cycle revives it, watch tonight's
  02:00Z reboot as the recurrence test (a second failure at the same cron = PSU
  dying; a clean pass = transient).
  ADDENDUM 2026-09-14 ~20:57Z (aria c336): .104 (exterior_4) power-dead AGAIN --
  second event. Timeline (sophon real time, RTSP dial errors in frigate journal):
  died between 17:20:03Z (last i/o timeout onset -- errors continuous from 17:30:03)
  and 17:30:03Z; watchdog crash-loop 17:29-17:45 (2154 lines, ext4 capture thread
  died 17:44:53); SELF-HEALED at 17:45:20 (camera came back, watchdog quiet since).
  Ping at 20:45Z: 100% packet loss, ARP dead. So: brief revival 17:45, dead again by
  20:45. Flapping power. .102 remains up (power restored 16:41Z, audio class-3 open
  per 0067). Ask unchanged: physical check of the .104 power path (PSU/cable/PoE port).
  ADDENDUM (aria c337, 2026-09-14 ~21:12Z): .104 "brief revival 17:45Z"
  CORRECTED -- there was no revival. Segment evidence: exterior_4's last
  recording segment is 2026-09-12 11:xx (mtime 08:10:38 -03 = 11:10Z),
  ZERO segments on 09-13, ZERO on 09-14 (including the 17:45Z window).
  The 17:45 "self-heal" was the WATCHDOG going quiet (crash-loop ended),
  not the camera returning -- frigate kept dialing .104:554 i/o timeout
  continuously 17:30Z onward (still failing 17:59Z). The c336 addendum's
  "brief revival 17:45, dead again by 20:45" is WRONG; the camera has
  been continuously dead since 09-12 ~11:10Z (58h+ at this writing).
  Watchdog quiet = the capture thread gave up, not the camera recovered.
  Ask unchanged: physical power cycle / PSU check on .104.
  ADDENDUM (aria c340, 2026-09-14 ~23:32Z): .104 still power-dead at
  23:17Z ping (100% loss) -- 59h+ continuous. Zero exterior_4
  segments on 09-14 (recordings tree has no exterior_4 dir in any
  hour). No change; ask unchanged.
  ADDENDUM (aria c343, 2026-09-15 ~00:45Z): ROOT CAUSE FOUND for the .102
  "death" -- it was NOT a power failure. The camera rebooted ON SCHEDULE
  (nightly cron `0 2 * * * reboot -f`, staggered per camera: .101 01:00Z,
  .102 02:00Z, .103 03:00Z, .201 06:00Z) and then its BOOT HUNG between
  S50crond and S93telegrambot for 14.7 hours. Evidence: rssi cron rows
  continued every 60s through the whole window (crond alive, /proc/uptime
  continuous 72s -> 52872s), but with EMPTY RSSI field (wlan0 never
  associated) and FACTORY-clock epochs (May 25 11:20). No WiFi => no NTP
  step, no RTSP, no HTTP. Self-healed 16:41:42Z: WiFi associated, ntpd
  stepped, the hung boot RESUMED (telegrambot/rc.local/onvif_notify lines
  stamped 16:41:42-43 real time), frigate recordings resumed 16:42:49Z.
  The c319 "power glitch/PSU" hypothesis is WITHDRAWN. What remains
  anomalous: (1) why the boot hung (exact init script unidentified;
  candidates S56ircut/S60uhttpd/S91mqttsub/S93ha), (2) why WiFi did not
  associate for 14.7h, (3) what unblocked it at 16:41Z. Router-side logs
  would settle (2)/(3) -- Nacho's device. Recurrence test: tonight's
  02:00Z reboot; the rssi log will show WiFi-down within 1 minute if it
  hangs again (empty RSSI field at 02:01Z).
  ALSO: .103 had a SEPARATE factory-clock event 09-12 11:10->15:41Z (~4.5h)
  with WiFi UP (RSSI -54 present) -- NTP path failure, not WiFi failure.
  Two distinct mechanisms; detail: knowledge/aria/camera-boot-hang-c343-
  2026-09-15.md. .104 ask UNCHANGED (still power-dead, physical cycle).

## ANSWERED 2026-09-16 ~23:17Z (interactive session, Nacho): parked -- cameras not a priority now

RULING (same as 0073): no physical visit scheduled. .104 power-dead
(4.5d) and the .103 storm reboot test are ACCEPTED for now; Nacho
will do the physical work later and notify when he does.

Filing stays OPEN (the ask is real and physical; it cannot be
executed by me). It is parked, not dropped: the detector keeps
ext4 in known-fault watch state, and the .103 session census keeps
accumulating so the pre/post-reboot comparison is ready whenever
the visit happens.

## UPDATE 2026-09-17 (interactive session, Nacho): ssh-reboot attempt on .104 -- L2-DEAD, physical visit still needed

Nacho's hypothesis: not a power issue, maybe the streamer process
(streamer = most demanding process) fails periodically; "the camera I
suspect is already on"; ssh reboot authorized.

ATTEMPTED (19:31-19:33Z): ping 100% loss; ARP FAILED then absent;
HTTP 000; RTSP port closed; broadcast ping no reply; arping 3
broadcast probes 0 responses. The camera does not answer AT LAYER 2
from sophon's wired vantage. A crashed streamer process would still
answer ARP (the kernel handles ARP, not prudynt). Verdict: .104 is
power-dead or network-dead at a layer below any process -- the
physical visit (power cycle / cable check) stands as the only path.
The streamer-crash hypothesis is NOT excluded for the FUTURE class
(it would show as ping-OK + RTSP-dead, a different signature -- worth
remembering if .104 ever shows that shape after revival).
