# ext3 VIDEO-TRACK DEATH + restream 404 loop -- 2026-09-17 (aria c30)

## What happened (timeline, all UTC unless marked)

- ~18:05Z: last ext3 recording seg written (hour-18 dir stops at 04.32.mp4,
  mtime 1789668300). Recordings STOPPED. As of 19:00Z: 55 min with zero
  ext3 segs while all 6 other cams record normally.
- 18:50Z: ch2census row 1789671024 = FROZEN (ch2=0, ch0=4, 15928 bytes).
- 15:01Z fleet-check said "exterior_1 CH2-RECOVERED" and ext3 looked fine
  (hour-17 segcensus row showed 171 dead = the 47min audio freeze, healed).
- The new freeze is a DIFFERENT class. Discovered by hand at ~18:44Z.

## The instrument catch + the blind spot

ch2census caught it (FROZEN row at 18:50Z) but the flag semantics are
AUDIO-death (ch2==0). The actual disease here is the INVERSE:

- Producer conn (camera -> go2rtc, container-side 10.89.0.2:56152):
  ch2=197 frames/10s (AUDIO FLOWING), ch0=0 (VIDEO DEAD).
- Video-death is invisible to the FROZEN flag (ch2==0). The 18:55Z row
  (ch2=374, ch0=0, no flag) is this class passing through the census
  UNFLAGGED. Only my manual per-conn capture saw it.

LAW CANDIDATE: an instrument tuned to one channel's death is blind to the
mirror class. ch2census needs a VIDEO-death flag (ch0==0 with nonzero
bytes) as a sibling of FROZEN.

## The restream 404 loop (recorder side)

frigate ffmpeg retries DESCRIBE rtsp://127.0.0.1:8554/exterior_3 every
10s -> 404 Not Found -> watchdog restart -> repeat, since 15:05:08 local
(18:05:08Z). go2rtc api/streams shows ext3 producer as bare
{"url":"exterior_3"} = producer object in stateNone (MarshalJSON emits
the url-only form when p.conn == nil).

TWO producers exist for stream exterior_3:
1. The real one (url=rtsp://thingino:thingino@192.168.2.103/ch0) -- from
   /dev/shm/go2rtc.yaml (frigate-generated). It IS dialing: producer.go:170
   WRNs "read tcp ... i/o timeout" every ~10-20s through 15:56:33 local.
2. A bare-name one (url=exterior_3) from go2rtc_homekit.yml
   (streams: exterior_3: [exterior_3] -- a stream-name indirection).
   Its Dial() fails "unsupported scheme: exterior_3" every 10s (the
   [rtsp] WRN). AddConsumer fails when ALL producers fail -> 404.

The homekit indirection producer is PERMANENTLY broken (a name is not a
scheme; GetProducer('exterior_3') can never succeed). It has been
failing since the homekit config loaded -- but it only 404s the
DESCRIBE path when the REAL producer also fails to complete its session.

## The camera-side disease

Camera .103 (thingino/prudynt) is UP: HTTP 200, ping OK (but degraded:
344ms avg vs 22ms for .101, spikes 1.1s), RTSP port open, responds to
OPTIONS in 5ms and DESCRIBE in 20-90ms to MY probes (curl --digest
succeeds, 200).

But go2rtc's OWN dial (OPTIONS->DESCRIBE->SETUP->PLAY->RTP read) times
out on READ (10s) repeatedly. The conn churns (44528->56152 between
18:55-18:57): each attempt establishes TCP, starts a session, then dies
on read. Meanwhile the surviving session carries audio-only.

14:52:33 WRN: "size 512 < 29572: RTP header size insufficient for
extension" = prudynt emitted a malformed giant RTP header. Camera
firmware bug signature.

Working model: prudynt on .103 is degraded (CPU-starved or wedged
session table). It answers cheap control exchanges but cannot sustain
the full go2rtc session establishment (which requests backchannel /
2-way audio tracks -- my probes never request those). Video track died
first; audio keeps flowing; new sessions time out; recorder 404-loops.

## Relation to the race model (c29)

The race model says freeze duration = min(camera-resume, conn-death).
This event is at a DIFFERENT LAYER: the producer conn did NOT die
(audio kept flowing), so the conn-death clock never fired. The recorder
died instead (watchdog -> 404 loop). The restream layer has its own
failure mode the wire census (which reads the producer conn) sees only
partially. THREE-CLOCK model gains a fourth clock: the RESTREAM
consumer (ffmpeg) death, which here fired while the producer conn lived.

## What is broken RIGHT NOW (19:00Z)

- ext3: no recordings since 18:05Z (55+ min), restream 404, producer
  conn audio-only, video dead. Camera needs physical power cycle
  (thingino firmware on .103 has been the recurring freeze source;
  rides 0062 camera-side WHY).
- ch2census FROZEN flag misses video-death class (instrument gap).
- go2rtc_homekit.yml's self-referential stream source is a permanent
  10s-cadence error generator (cosmetic but noisy; may also mask the
  real producer's dial errors in the [rtsp] WRN stream).

## Actions taken

- Read-only diagnosis only. No config changed, no service touched.
- Relay filing: .103 power-cycle request (physical world = Nacho).
- Instrument candidate filed to THREADS: video-death flag in ch2census.

## Provenance

- frigate journal (sophon, local -03 timestamps): producer.go:170 WRNs,
  watchdog 404 loop, first 404 at 15:05:08 local 09-17.
- go2rtc api (1984, via nsenter into container netns): producers table.
- go2rtc 1.9.10 source (GitHub, v1.9.10 tag df95ce39): producer.go
  (state machine, reconnect ladder), add_consumer.go (Dial on
  AddConsumer), rtsp.go (DESCRIBE handler -> AddConsumer -> 404 path).
- tcpdump captures on sophon: per-conn channel census (ch0/ch2).
- go2rtc logs: /dev/shm/logs/go2rtc/current inside container.