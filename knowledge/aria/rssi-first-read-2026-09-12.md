# exterior_4 storm + the 14:22L house-wide RTSP stall (2026-09-11) -- RSSI series first read

All times sophon LOCAL (-03) unless marked UTC. Written cycle c224, 2026-09-12 ~02:00 UTC.

## The question this read answers

The 2026-09-11 storm doc (ext4-rtsp-storm-2026-09-11.md) hypothesized
"intermittent WiFi degradation at the repeater edge" for the .104
(exterior_4) 12:12-13:41L storm, and said proving it needs RF-side
evidence during an episode. The RSSI longitudinal series (c202/c209)
went live ~14:58L -- AFTER the storm window. So the storm itself
remains RF-unwitnessed. But the series' first 14 hours caught two
other events, and the camera-side dmesg/logread backfill (via the
thingino run.cgi recipe, c224) caught more.

## Finding 1: the 14:21-14:54L house-wide stall -- go2rtc-side, not RF

At 14:22:39-14:23:12L, go2rtc logged i/o timeouts against FIVE
different cameras within 33 seconds (.201, .105, .104, .103, .202).
The common factor is not the cameras -- it is go2rtc's own TCP
connections (all sourced 10.89.0.3, the container). Watchdog events
then fired across the house: .104 x97, .105 x51, .103 x42,
.201 x6 in 14:23-15:30L.

Camera-side evidence contradicts a per-camera WiFi story for this
window: .201 (interior_1, RSSI -50, strong) deauthenticated at
14:31:18L and 14:39:36L (Reason 4 = inactivity, AP-side kick) with 8
reauthens 14:31-14:39L -- while its go2rtc timeouts ran 14:22-14:53L
continuous, ~10/min, then STOPPED (2 stragglers 16:32, 18:12L).
.104's own WiFi (atbm6031 driver) shows ZERO deauth/disassoc since
boot 09:45L -- dmesg has only the boot-time auth dance at +34-55s.

So the 14:22L event looks like a go2rtc/frigate-side stall (or a
switch/AP-side event that hit many streams at once and also kicked
idle WiFi clients), not the weak-RF class. The .104 storm an hour
earlier is a separate event.

## Finding 2: .104 RF is chronically marginal but NOT storm-correlated (yet)

- .104 rides the .2 AP (bssid 08:8a:f1:6a:62:56, ssid nacho_camaras)
  at RSSI -68 avg, dips to -74. 94/470 samples <= -70 dBm (20%) --
  it sits ON the bgscan threshold (simple:30:-70:3600) permanently.
- .103 rides the SAME AP at -57 and is 5x quieter in i/o timeouts
  (139 vs 580). The repeater-edge class holds for the baseline.
- BUT the camera-side RSSI log (starts 14:58L, misses the storm)
  shows the -72/-74 dips at 15:33, 16:25-16:35, 17:36-17:39L --
  and .104's i/o timeouts in those exact windows were only 2-4/min,
  NOT a storm. The 12:12-13:41L storm (92 watchdog restarts, 172
  timeouts) happened when the camera-side WiFi showed no anomaly
  (its dmesg is clean all day) and before any RSSI witness existed.
- .201/.202/.203/.101/.102 all ride nacho_guest (bssid 72:7f:...),
  RSSI -23 to -50, and are quiet (16-149 timeouts/14h vs .104's 580).

## Current fleet RF map (c224, signal_poll live reads)

| cam | IP | ssid | bssid | RSSI now | i/o timeouts 14h |
|-----|----|------|-------|----------|------------------|
| exterior_1 | .101 | nacho_guest | 72:7f | -23 | 16 |
| exterior_2 | .102 | nacho_guest | 72:7f | -29 | 42 |
| exterior_3 | .103 | nacho_camaras | 08:8a | -57 | 139 |
| exterior_4 | .104 | nacho_camaras | 08:8a | -68 | 580 |
| exterior_5 | .105 | nacho_guest | 72:7f | -59 | 182 |
| interior_1 | .201 | nacho_guest | 72:7f | -50 | 148 |
| interior_2 | .202 | nacho_guest | 72:7f | -41 | 149 |
| interior_3 | .203 | nacho_guest | 72:7f | -39 | 18 |

## What this changes

1. The storm doc's attribution ("weak-RF delivery path") stands for
   the 12:12L storm as a hypothesis but is UNPROVEN -- the RSSI
   witness missed the window, and .104's WiFi stack showed nothing
   wrong all day. Alternative hypothesis now open: camera-side
   encoder/prudynt stall (the 12:01:55L malformed-RTP error from
   .104, 10 min before the storm, remains the best lead).
2. The 14:22L house-wide stall is a NEW event class: go2rtc-side
   multi-stream timeout burst, all cameras, ~30 min, self-heals.
   Not viewer-correlated (0 nginx GETs 17:20-17:59Z = 14:20-14:59L).
   Candidate causes: go2rtc internal stall, sophon-side network
   hiccup, AP-side event. No sophon kernel logs in the window
   (journalctl -k empty 14:15-14:30L).
3. The bgscan threshold (-70) is mis-set for .104: it lives AT the
   threshold, so bgscan-simple's logic (scan when RSSI < -70) fires
   constantly or never meaningfully. If .104 ever needs to roam, it
   has no better AP to roam TO on nacho_camaras -- the fix is
   physical (AP placement), not config.

## Watch / next

- NEXT STORM on .104: the camera-side /var/rssi.log now covers
  continuously (cron every 60s, 312 lines ring). Correlate RSSI dips
  vs watchdog events IN-WINDOW before attributing. One command via
  the thingino recipe.
- The 14:22L class: if it recurs, check (a) go2rtc logs for a
  restart/internal error just before, (b) sophon NIC counters
  around the window, (c) whether .201-class (strong-RSSI) cameras
  also timeout -- that would kill the RF hypothesis for the class.
- .201's two Reason-4 deauths (14:31, 14:39L): AP-side inactivity
  kicks during the stall window. If the AP kicks clients when the
  uplink stalls, the AP (72:7f) is a suspect for the 14:22L class.
  Nacho-side lever: check the AP/repeater logs (I have no access).

## Recipe additions (hard-won this read)

- Thingino login is JSON: POST /x/login.cgi
  {"username":"thingino","password":"thingino"} -> Set-Cookie:
  thingino_session=...; then GET /x/run.cgi?cmd=<base64> with the
  cookie. (The -d "user=thingino&pass=thingino" form in the old
  recipe returns 400 "Username required".)
- Camera-side logs: dmesg (atbm driver wifi events), logread (ring,
  ~312 lines, crond-heavy -- grep -v crond), /var/rssi.log (the
  cron-written series). wpa_cli signal_poll gives live RSSI.
- .201's dmesg timestamps are seconds-since-boot: convert with
  uptime (boot 09:45Z Sep 11 for both .104 and .201 -- they booted
  together at 06:45L, likely a power event).