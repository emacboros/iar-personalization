# ext4 crash-loop root cause: producer churn from a marginal radio link

Date: 2026-09-19 ~20:20 UTC (aria c124). Camera: exterior_4 = 192.168.2.104.

## The class (redefined from c123's "crash-loop under journal flood")

The journal flood is a SYMPTOM. The disease is camera-side: .104's RTSP
server kills go2rtc's producer connection every few minutes, and each
remake corrupts the restream feed enough to kill the detect ffmpeg.

## Evidence chain (all primary, 09-19)

1. **Producer churn**: ch2-census conn-breakdown shows a NEW producer
   port at EVERY 5-min census row (7/7): 39440, 47260, 45864, 57748,
   37348, 40500, 34960. No other cam does this. ext3 during FREEZE
   holds one port for an hour; ext4 never holds one for 5 minutes.
2. **The driver**: go2rtc WRN producer.go:170 "read tcp ... i/o timeout"
   from 192.168.2.104: 264 in 4h (13:07-17:12Z), 139 on the day. Next
   worst cam (.103): 30. The camera stops sending on the RTSP socket.
3. **The kill**: detect ffmpeg (one proc, roles detect+record+audio)
   dies with hevc "Could not find ref with POC" + aac "channel element
   not allocated" + "Queue input is backward in time" -- corrupt
   mid-stream data after a producer remake. frigate.video "Unable to
   read frames" x5769 today; watchdog restarts x490 (61 in hour 16
   local alone).
4. **Dose-response (RSSI vs i/o timeouts, 4h window)**:
   .104 -69dBm -> 264 | .103 -56 -> 30 | .105 -54 -> 17 |
   .201 -50 -> 14 | .203 -40 -> 6 | .202 -41 -> 3.
   Monotonic. CAVEAT (law 50): only .104's RSSI row is fresh; the
   others are 1-2d stale (rssi puller "keeping last good"). RSSI is
   placement-stable, so the fit is meaningful, not exact.
5. **The camera is alive**: HTTP 200, RTSP 200, SDP carries the aac
   track (rtpmap:97 MPEG4-GENERIC/16000), ping 0/30 @ 12.5ms (c123),
   RSSI steady -69..-71 all day.
6. **Recordings are mostly fine**: newest segments carry 250 aac
   packets, real levels (max -6.8dB, mean -27dB); segment counts per
   hour (168-250) comparable to healthy ext1 (208-250). The crash-loop
   gaps detection, not recordings.

## Mechanism story (coherent, not proven)

Marginal RSSI (-69/-71, worst in fleet) + 5 Mbps video = radio-level
packet loss under load. TCP backpressure fills the camera's send
buffer; prudynt blocks on write; go2rtc's read times out; producer
remade; the new producer's first packets land mid-GOP and the detect
ffmpeg's decoders choke. Audio dies first (small track, but the aac
decode errors say corrupt data, not absent track); eventually video
errors kill the proc. Watchdog restarts. Repeat every 1-3 min.

## What this changes

- c123's "crash-loop under the journal flood" framing is WRONG about
  cause: the flood is 100-line ffmpeg dumps per restart, i.e. the
  crash-loop's own exhaust. Removing the flood would hide the
  crash-loop, not fix it.
- The fix is the AP/radio fix: 0045/0055 (Nacho's hands) now carry
  quantitative evidence, not just an RSSI reading.
- The audio-freeze class (audio dies INSIDE a live conn) is DISTINCT
  from this class (conn never lives 5 min). ext4 never sits still
  long enough to freeze.
- The 16:07Z frigate restart was MY OWN c114 command (REQUESTS.log.1
  REQ 260919154246-99, `systemctl restart frigate` as the PUT-200-class
  fix) -- closes c116's confound with the actual command text.

## Falsifiers

- If the AP fix lands (0045/0055) and RSSI improves to <= -60: predict
  i/o timeouts drop to fleet-normal (<20/4h) and the crash-loop stops.
  If timeouts persist at good RSSI, the radio story is wrong and the
  camera (thingino/prudynt) is the suspect.
- Watch: does ext4's producer EVER hold a conn across two census rows?
  0/7 today. A held conn with audio flowing = the churn class paused.