# REQ 20260911-aria-0038
filed: 2026-09-11T06:10Z
filer: aria
class: nacho-arch
state: open
urgent: yes
title: 5 of 8 cameras DARK since 05:28:20 UTC -- L2/power event upstream of sophon; needs physical check

body: |
  [EXTERNAL DATA: none -- infrastructure finding from aria cycle 181, 2026-09-11 ~06:10Z]

  ## What is down

  Since 05:28:20 UTC (02:28:20 -03) today, five cameras have NO L2
  presence at all: ARP INCOMPLETE/FAILED, no ping, no RTSP :554, no
  HTTP :80:

  - exterior_3 (192.168.2.103)
  - exterior_4 (192.168.2.104)
  - exterior_5 (192.168.2.105)
  - interior_1 (192.168.2.201)
  - interior_2 (192.168.2.202)

  Alive and recording normally: exterior_1 (.101), exterior_2 (.102),
  interior_3 (.203). Frigate's record path for the alive three is
  writing segments normally (ext1 last seg 03:08 -03, current).

  ## Evidence chain (all from sophon, this cycle)

  - Recording stop is SIMULTANEOUS: last segment for all five dead
    cams written 05:28:36 UTC (stat mtimes within 14ms of each other).
  - go2rtc producer read-timeouts for all five at 05:28:20 UTC
    ("read tcp ... i/o timeout"), then DESCRIBE on the go2rtc restream
    returns 404 for the dead five and 200 for the alive three.
  - Sophon itself is CLEAN: NIC UP (no carrier flap), zero kernel
    events at the trigger moment, no NetworkManager events, no sophon
    reboot (uptime 10 days), RX errors 0. The blip is not sophon.
  - The dead five are unreachable at L2 -- this is not a frigate or
    go2rtc problem. The devices are powered off, unplugged, or their
    switch/PoE path is dead.

  ## Reading

  5 devices dying within the same second = a shared upstream path:
  PoE switch / injector bank / power strip / breaker. The Aug-31
  outage (knowledge/aria/camera-outage-2026-08-31.md) was the same
  shape: a 17:24 UTC blip hit all 5 remote producers at once, 3 of 5
  recovered, 2 did not. These five did not recover at all in 40+
  minutes, which is worse than the Aug-31 pattern (that one had
  self-recovery within hours).

  ## What needs the human (physical world)

  1. Check the camera switch / PoE injectors / power strip feeding
     the cameras. Five dark at once points at shared power, not five
     independent failures.
  2. If it is a single PoE switch, its uplink or PSU is the prime
     suspect. If the cams are on the router's PoE... the TP-Link at
     .1 is up (HTTP 200), so the router itself is alive.
  3. After power is restored: verify the cameras come back at their
     static IPs (the Aug-31 episode showed runtime-config disturbance
     + self-recovery; the identity-theft watch applies -- check ARP
     MACs against the known mapping before trusting who is who).

  ## What I already did

  - Diagnosed from sophon only (read-only checks, no config touched).
  - Posted lab-notes note (thread/camera-outage-0911).
  - Frigate: left alone. Restarting frigate would not help (the
    cameras are unreachable at L2) and the restart-lever risk from
    the audio-loss analysis applies (re-rolling sessions can come
    back with MORE deaf cameras). The alive three keep recording.

  ## Watch I will keep

  - Recovery watch: ping the five each cycle; if any come back,
    verify identity (MAC) + NTP clock + RTSP before declaring health.
  - If still dark at the next fleet-check run, the fleet-check FAIL
    will fire -- expected and correct (the instrument is finally
    fresher than the failure).