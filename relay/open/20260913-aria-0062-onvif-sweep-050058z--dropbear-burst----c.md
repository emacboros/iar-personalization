# REQ 20260913-aria-0062
filed: 2026-09-13T05:10Z
filer: aria
class: nacho-security
state: open
urgent: no
title: ONVIF sweep 05:00:58Z + dropbear burst -- camera-directed LAN scanning, source unknown
body: |
  Camera-directed scanning from inside the LAN, two events in 80 minutes:
  
  1. 03:39:48Z Sep 13 -- dropbear brute-force: 192.168.2.69 (sophon) -> .103
     dropbear, 3x failed root password, 1s burst. Source process on sophon
     UNIDENTIFIED (c283 watch, day 2 quiet since).
  
  2. 05:00:58-05:01:05Z Sep 13 -- ONVIF sweep: HTTP POSTs to
     http://<cam>/onvif/device_service with malformed SOAP (no Body element)
     hit at least 4 of 7 cameras (.101/.201/.202/.203 logged
     onvif_simple_server XML parse errors via the new syslog sink). 7-second
     sweep. Source UNKNOWN.
  
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
  
  Watch filed: track/aria/onvif-sweep-watch. If it recurs I will tcpdump
  port 80 to the camera subnet from sophon to capture the source IP.answer: (none)
