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
  UPDATE c290 (07:32Z) -- SWEEP5 caught by the -e ARP logger; 5/5
  correlation now (sweeps 05:00, 05:43, 06:21, 06:27, 07:21Z all
  match .58 ARP bursts at second resolution). Sweep5: .58 ARP-ed all
  7 alive cameras 04:21:03.59-05.85 local; onvif errors 07:21:03-09Z;
  .104 (power-dead) skipped. Per-camera POST census 6-8 (distinct
  onvif_simple_server PIDs). TRIGGER MECHANISM CORRECTED (c288
  amendment): the "camera ARP-resolves .58 -> sweep 23ms" detail was
  wrong -- the 23ms gap is .58-ARP-to-camera -> onvif POST (the ARP
  is the ONVIF client resolving its target INSIDE the sweep). Real
  trigger = .58-side wifi events: sweep3 = gateway resolving .58 3x
  then sweep 7s later; sweep4 = rejoin probe, sweep 0.2s; sweep5 =
  DAD probes + gratuitous announce (a JOIN), sweep 2.3s. FALSIFIED
  EXPERIMENTS (both negative): sophon pinged .58 (replied, no sweep,
  3min watch); .103 pinged .58 via run.cgi (replied + ARP-ed back,
  no sweep, 3min watch). Incoming ARP/ping does NOT trigger; trigger
  is internal to .58. MAC confirmed 76:e3:1a:69:e3:9c (locally
  administered = randomized). Idle behavior: gateway ARP ~2min
  cadence, nothing else. Doc:
  knowledge/aria/sweep5-trigger-mechanism-c290-2026-09-13.md
  QUESTIONS UNCHANGED: (1) what device is snsv.local/.58, (2) what
  app on it POSTs malformed ONVIF SOAP at the fleet.
  UPDATE c342 (2026-09-15 ~00:15Z, aria cycle) -- .58 behavioral profile completed + Passim identity confirmed:
  
  1. DEEP-SLEEP CONFIRMED at ARP layer (c341): .58 slept through 372
     router broadcast polls over 13h (zero replies), then answered ONE
     direct unicast from sophon in 0.65s AND counter-ARPed to learn the
     asker (who-has .69 tell .58). Wake-on-direct-contact only. The
     counter-ARP is host-stack behavior, not embedded-camera behavior.
  
  2. MAC STABLE ACROSS DAYS: 76:e3:1a:69:e3:9c identical in every
     sighting Sep 13-14. Randomized (L-bit=1, maclookup.app isRand=true,
     no OUI match) but PERSISTENT PER NETWORK -- not daily rotation.
     Consistent with Android per-network randomization or Windows
     per-SSID randomization on a device that returns to this SSID.
  
  3. PASSIM CONFIRMED (primary source, github.com/hughsie/passim
     README): Passim is Richard Hughes' local caching server, ships
     with recent Fedora Workstation. The Passim-951F mDNS announcement
     (c288) pins .58 = snsv.local as a FEDORA WORKSTATION machine
     (laptop likely) on the .55 guest VAP. Avahi + OpenSSH_10.2 fit.
  
  4. Boot-window falsifier ARMED and LIVE: logger 0915c (sophon
     /tmp/arp-reqs-0915c.txt, armed 19:52 local Sep 14, expires 00:52
     local) covers tonight's .101 boot at 22:00:28 local. The c302
     boot+1s probe (Sep 14 01:00:30Z) was a ONE-OFF on prior data;
     tonight's read decides: .58 ARP at boot+0-2s again = boot-timed
     behavior real; quiet = one-off confirmed.
  
  5. ONVIF client identification via web search: DEAD END this cycle
     (Google JS-blocked, DDG anomaly-blocked, Bing bot-served junk).
     The malformed-SOAP-no-Body signature remains the best client
     fingerprint; identifying the app still needs the device in hand.
  
  QUESTIONS UNCHANGED (Nacho): (1) what device is snsv.local/.58,
  (2) what app on it POSTs malformed ONVIF SOAP at the fleet. New
  sub-question: does he recognize a Fedora laptop on the guest WiFi?
answer: (none)
  UPDATE c344 (2026-09-15 ~01:20Z, aria cycle) -- boot-window falsifier RAN, boot-timed hypothesis DEAD:

  Logger 0915d captured .101's 01:00:28Z boot window (22:00:13-22:00:32
  local). Result: ZERO .58 MAC (76:e3:1a:69:e3:9c) anywhere in the
  capture; .58 IP appears 22x but only as (a) the router's periodic
  who-has probes and (b) .101's own who-has 192.168.2.58 queries
  (camera-side ARP resolution attempts, unanswered). No .58 ARP
  activity at boot+0-2s.

  VERDICT: the c302 boot+1s probe (Sep 14 01:00:30Z) is CONFIRMED
  ONE-OFF. .58 does not wake on camera boots; it sleeps through them
  (consistent with c341 deep-sleep: ignores broadcasts, answers only
  direct contact). The sweep trigger remains .58-internal (wifi
  events), as c290 established.

  NOTE: logger 0915d itself died silently 10 minutes after arming
  (tcpdump process alive, file frozen at 22:10:16 local) -- the
  boot-window read used the 21:43-22:10 span, which fully covers the
  boot+0-2s window (boot at 22:00:28 local), so the verdict stands on
  valid data. Logger corpse is a separate finding (watchdog-quiet
  law; 0915e re-armed for the .201 06:00Z boot).

  QUESTIONS UNCHANGED (Nacho): (1) what device is snsv.local/.58, (2)
  what app on it POSTs malformed ONVIF SOAP at the fleet. Sub-question
  (Fedora laptop on guest WiFi?) unchanged. The boot-timed sub-thread
  is CLOSED; identity + app remain his.
