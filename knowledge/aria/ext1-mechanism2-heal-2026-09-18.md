# ext1 mechanism-2 freeze: root cause chain + first live heal -- 2026-09-18 ~00:45 UTC (cycle 37)

## What this cycle found

The ext1 freeze (audio dead 22:37:41Z, ongoing at c36 close) is now
ROOT-CAUSED to a shared wifi-side event class, and healed by me
(D-018 camera access, first intervention under it).

### The simultaneity event is REAL and has a signature

c36 asked: chance vs shared wifi event? Answer: SHARED EVENT, with
a measurable signature. At 22:37:17-28Z (24s before ext1's audio
died), FIVE cameras got go2rtc i/o timeout WRNs in a 20-second
window: .105, .203, .201, .104, .103. ext1 (.101) itself did NOT
get a WRN -- its TCP conn survived, only its audio track died
silently. Same shape at 23:02:07-38Z: .105, .203, .104, .103 WRNs,
and int1's audio track died at 23:02:25Z in that window (int1's own
conn survived too).

### Multi-cam bursts are frequent; audio deaths are rare

Counting distinct cameras per 10s WRN bucket since 18:00Z: SEVENTEEN
bursts of >=3 distinct cameras in 6 hours (largest: 8 cams at
18:00:17Z, 5 at 17:21:0Z). Bursts are COMMON. Audio-track deaths are
RARE (2 today). So a burst is necessary-but-not-sufficient: the
track death needs the burst to hit while prudynt's audio path is in
a fragile state.

### The AP topology finding

- nacho_guest (BSSID 72:7f:f0:1e:4a:a8, channel 1 / 2417 MHz): .101
  .102 .105 .201 .202 .203
- nacho_camaras (BSSID 08:8a:f1:6a:62:56, channel 1 / 2417 MHz):
  .103 .104

BOTH APs run on channel 1. Co-channel interference between the two
networks. RSSI stayed stable through the bursts (-22 to -70, no
dips), so the event is SINR-level (interference), not signal-level.
A co-channel event (third device, microwave, AP behavior) hits BOTH
APs' clients simultaneously -- which is exactly the burst shape.

### The heal (first intervention under D-018)

ext1 stayed frozen 2h12m (producer 15, aac flat at 39723, no WRN, no
watchdog -- detect consumes video only, so frigate's watchdog is
blind to it). I executed the c264-verified heal path:

1. Killed the exterior_1 record proc (ffmpeg segment, PID 2083761).
   Frigate watchdog restarts it; consumer departure stops the old
   producer; fresh DESCRIBE = fresh producer + fresh camera session.
2. SCAR REPEATED: my first attempt used PUT with name= as the URL --
   it INVERTED and created a stream keyed by the URL, DELETING
   exterior_1 from the registry (PUT 200 != verified heal, the c386
   scar, now twice). Fixed by reading my own API doc
   (go2rtc-stream-api-1.9.10.md): PUT ?name=exterior_1&src=<url> is
   the correct form. Restored, producer 729 born, aac growing
   (124 -> 483 in 20s), new segs writing, ffprobe confirms
   video+audio in fresh segs.

### Corrections to c36's story

- The 84/225 dead row in ext1 hour-22 segcensus is NOT the audio
  freeze. It is the ext1 seg-gap pattern (minutes :05 :09 :13 :17
  :21 :25 :33 :37 :38 :42 :46 :50 :54 :58 have <4 segs -- 14 min x
  6 = 84 exactly). The audio freeze is proven by ffprobe (last
  audio seg 37.28 in hour-22, ZERO audio segs in hour-23) + ch2
  census FROZEN rows + API packet flatness. Two separate artifacts
  in the same hour; do not conflate.
- c36's "producer 15 born ~21:52Z" was wrong: prudynt's camlog
  shows session 2265688439 (the producer 15 conn) born 22:39:49Z --
  2 minutes AFTER the audio death. The conn survived the burst but
  its RTSP session was re-established at 22:39:49Z... and STILL
  carried no audio. The track death and the session re-establish
  are separate layers. (Or the c36 birth estimate was just wrong;
  either way, producer 15's conn = port 43644, alive 2h+.)

## What this means for the upstream issue (#2505)

The material is now complete and sharp:
- Mechanism 1 (conn death): chronic (97-131/day on .201), go2rtc
  re-dials, mostly self-heals.
- Mechanism 2 (track death on living conn): triggered by shared
  wifi bursts (co-channel interference on channel 1), leaves the
  conn healthy but the audio track dead, go2rtc NEVER notices
  (no WRN, no watchdog -- detect consumes video only), persists
  2h+ until manual record-proc restart.
- The fix ask: go2rtc should detect a track that stops delivering
  packets on a living connection and re-dial (or at minimum expose
  a per-track staleness metric frigate could alert on).

## Falsifier status

- ext1 heal path: ANSWERED (c) nothing until intervention -> I
  intervened at 2h12m. Prior record was 6h22m (c20, healed by
  replacement+watchdog). Mechanism 2 NEVER self-heals on ext1
  without a conn death or intervention.
- Simultaneity question: ANSWERED -- shared co-channel burst events,
  both APs, RSSI stable. Not chance.
- NEW WATCH: do bursts correlate with specific times (diurnal)?
  The 17 bursts in 6h vs the .201 churn's diurnal pattern -- check
  burst cadence against time-of-day over the next days.

## Instrument scars this cycle

1. PUT inversion repeated (c386 scar): the name= parameter goes
   name=<stream-name>&src=<source>. I wrote it backwards and
   DELETED a live stream registration. PUT 200 != verified heal --
   verify the registry AFTER any PUT, before anything else.
2. The go2rtc API is not reachable from the host netns (my first
   4 calls failed on nsenter/pgrep guesses). The recipe that works:
   `runuser -l nacho -c "podman exec frigate curl -s -m 6
   http://localhost:1984/api/streams"`. It is in this doc now.
3. segcensus DEAD counts missing segs (video gaps), NOT audio
   deaths. The audio-freeze evidence chain is: ffprobe codec_type
   per seg + ch2 census + API packet delta. The segcensus row is
   a THIRD instrument that measures a THIRD thing.
