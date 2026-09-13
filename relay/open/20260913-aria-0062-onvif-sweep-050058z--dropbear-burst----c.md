# REQ 20260913-aria-0062
filed: 2026-09-13T05:10Z
filer: aria
class: nacho-security
state: open
urgent: no
title: ONVIF sweep 05:00:58Z + dropbear burst -- camera-directed LAN scanning, source unknown
body: |
  Camera-directed scanning from inside the LAN, two events in 80 minutes:
  
  1. 03:39:48Z Sep 13 -- dropbear burst: RESOLVED as own tooling.
     ATTRIBUTION CORRECTED (c289): the burst was c288's INNER-SSH (not
     c282's census) -- a nested `ssh sophon 'ssh root@192.168.2.103 ...'`
     whose OUTER hop had BatchMode=yes but INNER hop did not. Dropbear
     rejected the key, the inner ssh sent 3 empty passwords, exit.
     Tool result stamped 03:39:49Z matches dropbear 03:39:48-49Z exactly.
     Sixth own-tooling attribution. LAW REFINED: BatchMode on EVERY hop
     of a nested ssh, not just the outer one. Doc: knowledge/aria/
     dropbear-burst-c288-inner-ssh-2026-09-13.md.
  
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

  UPDATE c288 (06:32Z) -- ATTRIBUTED to 192.168.2.58, 4/4 second-level
  correlation. Raw ARP capture on sophon caught .58 ARP-sweeping the
  cameras seconds before BOTH in-window sweeps: sweep3 06:21:11Z
  (.58 ARP 03:21:11.125-.885 local, 6 cams; onvif 06:21:11-13Z) and
  sweep4 06:27:28Z (.58 ARP 03:27:27.9-29.6 local, all 7 cams; onvif
  06:27:28-36Z; .58 sent gratuitous-ARP rejoin probes 0.2s before
  sweeping). .58's ARP targets in the whole capture: gateway + exactly
  the 7 cameras, nothing else. Camera HTTP is invisible from sophon
  (WiFi unicast, switched fabric) -- correlation is the evidence.
  IDENTITY: snsv.local, Fedora Linux (announces Passim-951F like
  sophon announces Passim-0FA4), Avahi desktop stack, OpenSSH_10.2,
  randomized MAC, WiFi on the .55 guest VAP. NOT yoga/.66 (different
  SSH host keys; .66 = yoga, confirmed via ansible key in sshd journal).
  Sweep shape: uniform 8 error-lines/camera (single probe pass) or
  14-16/camera (double pass), all 7 cams, serial by IP. Fires on .58
  network events (rejoin/ARP-resolution), not a fixed clock.
  Doc: knowledge/aria/onvif-sweep-attribution-c288-2026-09-13.md
  QUESTIONS (narrowed): (1) What device is snsv.local / .58? A Fedora
  machine on your WiFi with a camera-discovery app on it. (2) What app
  POSTs malformed ONVIF SOAP from it? (Camera viewer, PTZ controller,
  python-onvif script?) If .58 is yours and the app is known-benign,
  this filing closes as "known device, noisy discovery client".

  Watch filed: track/aria/onvif-sweep-watch. tcpdump on sophon is
  USELESS for this class (vantage lesson); ARP-watch + camera-side
  netstat are the working instruments.answer: (none)
