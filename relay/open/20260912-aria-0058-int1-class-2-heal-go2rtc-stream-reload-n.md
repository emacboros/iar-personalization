# REQ 20260912-aria-0058
filed: 2026-09-12T18:16Z
filer: aria
class: nacho-test
state: open
urgent: no
title: int1 class-2 heal: frigate restart (or PUT+proc-kill) -- PATCH useless (c262 source-verified)
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

## AMENDMENT (c262, 18:20Z -- source-verified recipe correction)

Read go2rtc v1.9.10 source (internal/streams/api.go, streams.go,
stream.go, internal/rtsp/rtsp.go). The PATCH recipe above is
WRONG -- do not run it:

1. PATCH ?name=X&src=Y: SetSource() only updates the source
   STRING label on the existing producer. No reconnect. Useless.
2. PUT /api/streams?name=interior_1&src=rtsp://thingino:thingino@
   192.168.2.201/ch0: creates a NEW stream object + fresh camera
   session, replaces the map entry. BUT existing consumers bind
   at DESCRIBE and stay attached to the OLD object. The frigate
   record proc keeps reading the old stalled object (its 20s
   no-frames watchdog never fires because video flows).
3. Minimal full heal = PUT + kill the interior_1 record proc
   (watchdog restarts it in seconds; fresh DESCRIBE binds to the
   new object; old producer stops when its last consumer leaves).
4. SIMPLER EQUIVALENT: restart the frigate container. Remakes ALL
   sessions -- heals int1 (class 2) AND ext2 (class 1) in one
   move. Cost: ~30s detection gap on all 8 cams.

PREDICTION (testable): after heal, new producer's audio receiver
pkts grow; int1 segments carry ~150-250 audio pkts/10s-seg within
one minute. If not, ADDENDUM 3.

## RESOLUTION (c264, 19:29Z -- NO ACTION NEEDED, healed naturally)

int1 healed WITHOUT intervention at 18:40:37Z, ~2.5h after the
16:13:42Z death. Mechanism (verified from recordings + logs):

1. The frigate watchdog's FPS-LIMIT path fired (18:40:02Z "exceeded
   fps limit" -> force kill 18:40:32Z -> restart). The audio leg
   stall causes ffmpeg timestamp drift -> fps anomaly -> restart.
2. The record-proc restart DID heal: killing the sole consumer
   stops the old producer (RemoveConsumer -> stopProducers), and
   the fresh DESCRIBE starts a new producer with a fresh camera
   session. Receiver ids prove it: 39984 (frozen, c262) -> 42418
   (flowing 19:11Z) -> 43127 (flowing after the 19:20Z restart).
   Audio has been continuous 156-158 pkts/seg since 18:40:37Z
   (one brief 19:19:13-19:20:17Z gap straddling a second
   fps-exit restart, healed identically).
3. c262's ADDENDUM 2/3 correction ("record-proc restart will NOT
   heal") was WRONG -- the stopProducers-on-last-consumer-leave
   path was in the same source reading and I read past it.

So: do NOT run the PUT+kill or container restart for int1. The
recipe remains valid as a MANUAL fallback if a future class-2
stall persists past the next fps-exit restart. Doc:
knowledge/aria/int1-class2-heal-natural-2026-09-12.md.

Suggest: answer + move to answered/ at next hygiene pass (or
Nacho can just note it at the debrief).
