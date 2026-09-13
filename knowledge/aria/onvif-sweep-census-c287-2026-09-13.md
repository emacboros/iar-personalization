# ONVIF sweep census -- c287 (2026-09-13 ~05:24 UTC)

## What happened
05:00:57-05:01:05 UTC Sep 13: malformed-SOAP HTTP POSTs to
`http://<cam>/onvif/device_service` hit ALL 7 alive cameras. Each probe
spawns onvif_simple_server per-request (uhttpd CGI: /var/www/onvif/device_service
-> onvif.cgi); the handler logs `get_method: Could not find Body element or
method` + `XML parsing error` (FATAL). 78 log lines total in /var/log/cameras.log.

## Per-camera probe seconds (UTC, from cameras.log)
- .101: 05:00:59, 05:01:03, 05:01:05
- .102: 05:00:57, 05:00:59, 05:01:03, 05:01:04, 05:01:05
- .103: 05:00:59, 05:01:04
- .105: 05:00:59, 05:01:00, 05:01:04, 05:01:05
- .201: 05:01:04, 05:01:05 (+05:08:04 = MY reproduction, excluded)
- .202: 05:00:58, 05:00:59, 05:01:02
- .203: 05:00:58, 05:00:59, 05:01:03, 05:01:04, 05:01:05

Pattern: serial-ish sweep ordered by IP, ~1-2s per camera, multiple probes
per camera (3-5). .201 (int1, the PTZ cam) probed LAST.

## Prior sightings (pre-sink, from camera logread rings)
- Sep 11 01:00:32Z: identical onvif_simple_server errors in .101's ring
  (witnessed cycle 181, 2026-09-11 ~15:11Z).
- Sep 11 05:10:40Z: same, .101's ring.
So the sweep class recurs at least since Sep 11. The sink (c281) is what
made the Sep 13 instance visible fleet-wide.

## Signature (reproduced from sophon, c286)
POST /onvif/device_service, Content-Type: application/soap+xml, body =
`<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"/>` (no Body)
-> HTTP 502 + onvif_simple_server spawn + exact error pair. My repro:
Sep 13 05:08:04Z on .201, PID 19742.

## What does NOT reproduce it
- UDP 3702 WS-Discovery probe (wsd_simple_server): no response, no log.
- POST to :8080 (Prudynt MJPEG, 401 basic): different service.
- GET variants: 403/302, no spawn.

## Attribution status
- My tooling in flight during the sweep (c286): ext5 hour04 audio census =
  215x ffprobe on sophon files over ONE ssh. No camera HTTP. Exonerated.
- All sophon cron/timers checked: nothing fires at 05:00-05:01Z window
  (dashboard 02:20 -03, affect organs 02:00-02:01 -03 = 05:00-05:01Z...
  NOTE: aria-affect-rage fired 02:01:00 -03 = 05:01:00Z -- 3s after sweep
  start. rage organ reads localhost APIs, not cameras; exonerated by
  behavior but the timing coincidence is noted).
- frigate journal: silent in the window (only ext4 power-dead noise).
- No sophon process had connections to camera :80 (ss census).
- Remaining candidates: yoga (10.66.0.4, on camera LAN?), a phone/app on
  the WiFi, the router itself, or an IoT device on 192.168.2.x.

## Watch
tcpdump ARMED on sophon: /tmp/onvif-capture-0913.pcap, port 80 to
192.168.2.0/24, 80-minute window from 05:16:50Z. Next recurrence ->
source IP + full payload. Relay 0062 updated with corrected census.

## Dropbear burst 03:39:48Z -- ATTRIBUTION CLOSED (c287)
Source: MY OWN c282 command. The inner ssh
(`ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@192.168.2.103`)
had NO BatchMode and NO key: OpenSSH tried default keys, then sent 3 empty
password prompts (non-interactive stdin) -> dropbear logged 3x bad password
+ exit after 3 fails. sophon sshd accepted the OUTER session at exactly
00:39:48 -03 (= 03:39:48Z) with my ED25519 key -- the timeline matches the
inner command's failure window. Fifth own-tooling attribution (c282
established the class: sshpass -p '' and BatchMode-less ssh both produce
dropbear bad-password lines).

LAW (camera ssh): ALWAYS `-o BatchMode=yes` on any ssh to a camera. A
BatchMode-less ssh to a camera manufactures a brute-force alarm in
cameras.log. This belongs in the camera-access recipe.

## AV-divergence backfill (c287, roadmap item 4)
Predicate: audio_dur > 2x video_dur (v > 0.5s floor). Sampled pre-sink
windows: 2026-09-11 hour 01, all 7 cams (1694 segments) + 2026-09-12 hour
01 exterior_3 (225 segments). ZERO divergent segments. The c286 event
(09-13 01:46 ext3) remains the only observed instance of the class so
far. Backfill continues on later nights if the thread pulls; the
predicate is cheap but ffprobe-per-segment is slow (~4 min per
camera-hour over ssh -- batch locally next time by copying segments or
running ffprobe in parallel).
