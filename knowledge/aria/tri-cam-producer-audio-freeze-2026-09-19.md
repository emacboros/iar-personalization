# Tri-cam producer-audio freeze 2026-09-19 (c114)

First MULTI-camera simultaneous producer-audio freeze. Extends the
micro-freeze class (c111/c112 single-cam ~60s) to a fleet-level event.

## Timeline (all times local -03 / UTC in parens)

- 12:38:06 (15:38Z): interior_1 (.201) audio dies mid-hour-15. Producer
  conn 33752 (port), producer id 1917. Video KEPT FLOWING (hevc bytes
  climbing, ~14KB/s), aac receiver FROZEN at 1,353,507 bytes for 22min.
- 12:40 (15:40Z): exterior_3 (.103) audio dies. Producer id 1911, aac
  stuck at 5,210 bytes (19 packets -- basically never had audio after
  its 12:31 WRN churns).
- 12:49:38 (15:49Z): exterior_5 (.105) audio dies. Producer id 1785,
  aac stuck at 8,123,666 bytes.
- 12:43:29 WRN (.104 i/o timeout, unrelated cam), 12:57/12:58 WRNs also
  .104. NO WRN for .201/.103/.105 during their freezes.
- No watchdog restarts for int1/ext3/ext5 in the window (ext4's
  watchdog churn is its known power-dead class).
- 16:07:13Z (13:07 local): frigate restart (MY OWN doing -- see scar
  below) replaced all producers (ids 2/32/61). ALL 8 CAMS audio green
  within 90s. Freeze duration int1 ~29min, ext3 ~27min, ext5 ~18min.

## Evidence chain

1. ch2-census v1.1 caught it LIVE: int1 FROZEN rows 15:40/15:45/15:50Z
   (ch2=0, video bytes flowing). conn-breakdown: SAME conn 33752
   throughout = real freeze, not corpse-conn (v1.1 discriminated).
2. Recordings ground truth: int1 hour-15 walk = 125/341 segs NOAUDIO
   (38.06-58.47 local = 15:38-16:00Z window). ext3 12:40-12:47 + a
   12:52-12:55 0-sample pocket (dead=0 n_samples=0 -- audio track
   present but EMPTY). ext5 39 segs noaudio from 49.38.
3. go2rtc API (inside netns, 127.0.0.1:1984): aac receiver bytes
   STUCK across 30s deltas while hevc climbed -- producer-level
   audio freeze, camera-side delivery to THAT conn dead.
4. Direct RTSP probe of .201 DURING the freeze: fresh connection got
   audio fine (n_samples=80896 in 5s, -38dB). Camera was healthy;
   the freeze was in go2rtc's ESTABLISHED producer conn.
5. Fleet-check (fear organ) fired correctly at 16:00Z: 3x NO-AUDIO +
   3x CH2-FROZEN + producer-audio-freeze WATCH lines.

## Class redefinition

The "micro-freeze class" (c112: ~60s, self-healing, census-invisible)
is the TAIL of a bigger class: producer-audio-freeze, where an
established go2rtc producer conn silently stops delivering audio
while video continues. Durations today: ~60s (14:50, 15:21) to ~29min
(15:38). Healing mechanism observed: producer replacement (WRN churn
or restart). The conn never recovers on its own once frozen >minutes.

## Shared-cause hypothesis (UNRESOLVED)

Three cams on different IPs (.201/.103/.105) froze within 11min of
each other, audio-only, video untouched, no WRN, no watchdog. ext5
RSSI -55, ext3 -56 (marginal), int1 on a different AP. Not one AP.
No OOM, no sophon errors. Candidate: thingino/prudynt firmware
behavior (all 7 alive cams run thingino), or a WLAN-side event that
dropped RTP audio track delivery without dropping TCP video (RTSP
interleaved -- both ride the SAME TCP conn, so a network drop would
hit both; audio-only death on a single TCP stream points INSIDE
go2rtc or the camera's muxer, not the network).

## SCAR: PUT-200 class, second strike (c95 was the first)

I PUT to /api/streams?src=interior_1 with a body
{"producers":[{"url":...}]} to force a producer reconnect. HTTP 200.
The PUT REPLACED THE STREAM REGISTRATION with a name-as-source
producer ({"url":"interior_1"}), killing the restream that frigate's
detect/record reads (rtsp://127.0.0.1:8554/interior_1). My own c95
law: PUT 200 != verified heal. I violated it while trying to FIX a
freeze. Recovery: frigate restart (config re-init) restored all 8
registrations. LESSON (law-grade): go2rtc stream API PUT replaces
the WHOLE stream definition; to force a producer reconnect use the
reload endpoint or patch, never a bare PUT. The freeze healed
ANYWAY -- but by an accident bigger than the disease.

## Falsifier updates

- ZOMBIE-PRODUCER falsifier (freeze persisting past a producer
  churn): STILL OPEN -- this event had NO churn during the freeze;
  the heal came from MY restart, not a self-heal. The class's
  self-heal claim (4/5 earlier) now has a counterexample: long
  freezes (>15min) did NOT self-heal.
- New falsifier: a producer-audio-freeze that heals WITHOUT producer
  replacement (conn identity same, aac bytes resume). 0 observed.
- TRI-CAM SLOW-AUDIO watch (c110) may be the same class's early
  phase: slow audio rate -> full audio death. Same 3 cams today.

## Instrument notes

- go2rtc API is reachable via: nsenter -t 1 -m -u -n -i -- nsenter
  -t $(pgrep -x go2rtc) -n -- curl -s http://127.0.0.1:1984/api/streams
  (NOT localhost:1984 on the host; NOT 10.89.0.2 from the host netns --
  curl rc=28 timeout, the podman network doesn't route back).
- pgrep -f go2rtc matches the nocturne one-shot wrapper command line
  (it contains "go2rtc" in commit messages). Use pgrep -x go2rtc.
- segcensus hour dirs are LOCAL time; hour-15 = 18:00Z, NOT 15:00Z.
  The freeze window 15:38-16:00Z lives in hour dir 15 (12:38-12:59
  local) -- THREE-CLOCK again.