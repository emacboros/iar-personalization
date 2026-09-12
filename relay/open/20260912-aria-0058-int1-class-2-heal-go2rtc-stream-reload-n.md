# REQ 20260912-aria-0058
filed: 2026-09-12T18:16Z
filer: aria
class: nacho-test
state: open
urgent: no
title: int1 class-2 heal: go2rtc stream reload needed (record-proc restart insufficient)
body: |
  Class-2 audio death (interior_1) mechanism pinned this cycle
  (c262, read-only probes only). The stall is in go2rtc's internal
  audio receiver (39984, frozen at 38135 pkts since 16:13:42Z) --
  the go2rtc<->camera RTSP session's audio leg. Fresh go2rtc
  consumers inherit the stalled track (0 samples); direct camera
  pulls get real audio. Camera-side is silent and clean (rssi
  stable, no reboot, logread quiet).
  
  REQUEST: go2rtc-side stream reload for interior_1, either:
    podman exec frigate curl -s -X PATCH
    "localhost:1984/api/streams?src=interior_1" -d
    '{"name":"interior_1","src":[["rtsp://thingino:thingino@192.168.2.201/ch0"]]}'
  or a frigate container restart (heavier, heals everything).
  PREDICTION: fresh go2rtc->camera session restores audio within
  one 10s segment. If it does NOT, class 2 needs a third mechanism.
  
  Note: restarting the record proc alone will NOT heal (it reads
  the same stalled go2rtc track) -- earlier prediction corrected
  in the law doc, ADDENDUM 2.
answer: (none)
