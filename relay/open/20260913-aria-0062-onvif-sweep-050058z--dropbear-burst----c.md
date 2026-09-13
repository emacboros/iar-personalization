# REQ 20260913-aria-0062
filed: 2026-09-13T05:10Z
filer: aria
class: nacho-security
state: open
urgent: no
title: ONVIF sweep 05:00:58Z + dropbear burst -- camera-directed LAN scanning, source unknown
body: |
  Camera-directed scanning from inside the LAN, two events in 80 minutes:
  
  1. 03:39:48Z Sep 13 -- dropbear burst: RESOLVED as own tooling (c287).
     My c282 census ran an inner `ssh root@192.168.2.103` WITHOUT
     BatchMode; OpenSSH sent 3 empty password prompts after key rejection
     -> dropbear logged 3x bad password. sophon sshd accepted the outer
     session at the exact second. Fifth own-tooling attribution in this
     class (c282 established the pattern). Recipe fix landed: camera ssh
     now always carries -o BatchMode=yes.
  
  2. 05:00:57-05:01:05Z Sep 13 -- ONVIF sweep: HTTP POSTs to
     http://<cam>/onvif/device_service with malformed SOAP (no Body element)
     hit ALL 7 alive cameras (.101/.102/.103/.105/.201/.202/.203 all logged
     onvif_simple_server XML parse errors via the new syslog sink; corrected
     census 0062-v2, the 4-camera count was a partial read). Serial-ish
     sweep, ~1-2s per camera, ordered by IP (.201 probed last at 05:01:04).
     PRIOR SIGHTINGS: .101's logread ring held identical onvif_simple_server
     errors from Sep 11 01:00:32Z and Sep 11 05:10:40Z (seen in cycle 181,
     pre-sink) -- so this sweep class RECURS, at least since Sep 11.
     Source UNKNOWN. tcpdump port-80 capture to the camera subnet is now
     ARMED on sophon (/tmp/onvif-capture-0913.pcap, 80min window) so the
     next recurrence gets a source IP + payload.
  
  Exonerated (all checked this cycle): aria-dashboard.sh, fleet-check.sh,
  rage/fear organs, fleet-feed, rssi/camlog/nic pullers. No sophon journal
  entries at the probe time. I reproduced the exact error signature from
  sophon (POST with Body-less SOAP envelope), so the signature is confirmed
  as the onvif CGI handler, but the 05:00:58Z caller is not identified.
  
  Ask:
  - Do you know of anything on yoga or your phone that does ONVIF discovery
    (PTZ controller app for ptz-1/.201? Frigate UI open somewhere doing
    camera discovery? Home Assistant?)
  - If nothing known: this is LAN-side scanning we can't attribute, and the
    dropbear burst + ONVIF sweep pattern together suggest one actor poking
    the camera fleet. Cameras are LAN-only (no WG exposure), so the actor is
    on 192.168.2.x or came through the router.
  
  UPDATE c287 (05:52Z): the sweep RECURRED at 05:43:42-51Z -- all 7
  cameras again, same signature. The sophon tcpdump (armed 05:16) caught
  NOTHING at that timestamp: the sweep traffic does not transit sophon
  (cameras' gateway is the router; a same-L2 source talks to cameras
  directly). Sophon-side capture can never attribute this class.
  ARP evidence instead: every camera's ARP cache holds 192.168.2.58
  (76:e3:1a:69:e3:9c, randomized MAC, SSH-only Linux box on WiFi) in ALL
  7 caches; 192.168.2.55 (TP-Link BE230v1, second unit) in 6/7. .58 in
  all seven caches right after a fleet-wide sweep is the strongest
  correlate. Watchers armed (ARP-watch + full-traffic capture).
  QUESTIONS FOR YOU: (1) Is 192.168.2.58 yours? SSH-only Linux device,
  randomized MAC, on the WiFi -- a laptop? (2) Is the second BE230
  (.55) yours and does it run any device-scan feature? If neither is
  known, we have an unidentified Linux device on the camera WiFi
  sweeping the fleet every ~40 min.

  Watch filed: track/aria/onvif-sweep-watch. tcpdump on sophon is
  USELESS for this class (vantage lesson); ARP-watch + camera-side
  netstat are the working instruments.answer: (none)
