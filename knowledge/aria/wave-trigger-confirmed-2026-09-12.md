# WAVE TRIGGER CONFIRMED -- the browser remakes the fleet's RTSP sessions
# Cycle 268, 2026-09-12 ~22:00-22:10 UTC. Supersedes the "candidate" status
# in ROADMAP c267. Companion doc: wave-mechanism-c266-2026-09-12.md.

## THE CHAIN (verified in source, go2rtc 1.9.10 + frigate 0.17.2)

1. Nacho opens the frigate live page (GET / from his browser).
2. Frigate 0.17.2 web: LiveDashboardView -> useCameraLiveMode ->
   useDeferredStreamMetadata. DEFER_DELAY_MS = 2000: 2s after mount,
   it fetches GET /api/go2rtc/streams/<cam> for EVERY restreamed
   camera in the grid, in parallel (Promise.allSettled).
3. Frigate backend (frigate/api/camera.py go2rtc_camera_stream) ALWAYS
   proxies to go2rtc with params src=<cam>&video=all&audio=all&microphone="".
4. go2rtc apiStreams GET branch: probe.NewProbe(query) builds a probe
   consumer with video+audio (recvonly) + MICROPHONE (recvonly, CodecAny).
5. stream.AddConsumer(probe):
   - video/audio: streams-level Producer.GetTrack hits the
     pointer-equality shortcut (track.Codec == codec, where codec is the
     producer's OWN codec object returned by MatchMedia) -> existing
     track returned, conn untouched. NO reconnect from these.
   - microphone: matches the camera's sendonly audio (speaker/
     backchannel) media -> prod.AddTrack -> rtsp conn.AddTrack ->
     ModeActiveProducer && state == StatePlay -> Reconnect().
6. Reconnect(): Close() (sends TEARDOWN to camera) -> Dial() ->
   Describe() with Require: www.onvif.org/ver20/backchannel ->
   SetupMedia() for all existing receivers/senders -> worker loop sees
   StateSetup -> Play(). FULL RTSP SESSION REMAKE.
7. Camera-side prudynt logs a new BackchannelStreamState session at
   that second. All 7 alive cameras have sendonly+recvonly audio in
   their SDP (verified via /api/streams: every alive cam shows
   'audio, recvonly' = speaker), so ALL 7 reconnect at the same second.
8. ~24s later (20s no-frames window + processing), frigate watchdogs
   fire fleet-wide: "No frames" or "exceeded fps limit" -> ffmpeg
   restarts -> audio legs remade.

## TIMELINE (all times LOCAL -03 = UTC-3; prudynt/wave seconds UTC)

- 15:39:16 login, 15:39:24 GET / (page load 1)
- 15:39:32.7-.84  7x GET /api/go2rtc/streams/<cam> (200)  [= 18:39:32Z]
- prudynt new BackchannelStreamState sessions: same second, .103/.105/.201
- 15:39:55-15:40:05 watchdog events: ext2, int2, ext1, int3, ext5, int1, ext3 (7/7)
- 16:16:43 GET / (page load 2) -> 16:16:51 7x GETs [= 19:16:51Z]
- 16:17:15-16:17:23 watchdog events 7/7
- 16:19:08 GET / (page load 3) -> 16:19:12 7x GETs [= 19:19:12Z]
- 16:19:36-16:19:46 watchdog events 7/7
- After 16:19:18 (page interaction ends): ZERO watchdog events 16:20-21:54.

## NEGATIVE CONTROLS (what does NOT trigger waves)

- MSE websocket connects: 15:43:22 batch of 5 ws connects produced NO
  wave (no watchdog events 15:41-15:59). ws connects follow the GETs
  (+5-6s), never precede them.
- ext4 500s (dead-camera dial timeout): ride-along noise, ext4-specific.
- Page closed after 16:19: zero events for 90+ minutes.

## WATCHDOG EVENT CENSUS (6h window, 29 events)

15:39(4) 15:40(3) = wave1 | 16:17(7) = wave2 | 16:19(7) = wave3 |
17:10(3) 17:11(3) 17:33(1) 17:34(1) = ext3's known 52-min death story.
Per-cam totals: 3 events each for the 6 healthy cams; ext3 has 11
(3 waves + its own death). NO events outside wave minutes + ext3 story.

## WHAT THIS EXPLAINS

- The fleet waves (c265/c266): user-triggered, every live-page open.
- The +24s delay: 20s no-frames watchdog window + restart processing.
- ext3's 52-min death: wave-3 reconnect landed mid-flight, camera-side
  encoder stuck (c266 resolution stands; the trigger is now identified).
- Why waves come in bursts with no camera/AP/sophon-side cause: the
  cause was never on the camera side. It was the browser.

## WHAT REMAINS OPEN

- SOLO-DEATH CLASS (ext5/int1 audio legs 16:13-15 local, no churn): NOT
  page-load related (no GETs at 16:13). Separate trigger, still open.
- CLEAN FALSIFIER: a single-cam streams GET outside any wave window
  should produce a single-cam fps-limit ~20s later. The two single GETs
  in this window (16:17:17 int3, 16:19:18 int2) landed INSIDE wave
  windows -- ambiguous. Next page-load session can test this: open ONE
  camera view, watch for a single-cam event ~20s later.
- Whether the probe reconnect is the SOLO-DEATH mechanism too (a single
  GET from a stale page/tab): plausible but unproven.

## FIX OPTIONS (Nacho's call -- frigate/go2rtc side, not camera-side)

a) Frigate: drop "microphone" from the metadata-fetch proxy params
   (frigate/api/camera.py go2rtc_camera_stream). The mic probe is only
   needed for 2-way-talk detection; a plain GET returns producers'
   medias without touching the conn. Smallest change, kills the wave.
b) go2rtc: in conn.GetTrack/AddTrack, match existing receivers by codec
   NAME (or codec equality) instead of pointer identity, so a probe
   asking for tracks that already exist returns them without reconnect.
c) go2rtc: make the probe consumer non-invasive (serve cached SDP for
   GET without AddConsumer when no real consumer params are needed).
d) Upstream issue to AlexxIT/go2rtc: "probe GET with microphone
   reconnects playing RTSP producers" -- with the pointer-equality
   analysis above. Candidate for an internet consult next cycle.

## LAWS EXERCISED

- Law 50 (schema): the wave seconds matched at SECOND resolution only
  after timezone conversion (prudynt UTC vs frigate local -03).
- Verify against primary evidence: the trigger was in the frigate nginx
  access log all along (c267 found it); the MECHANISM needed the source.
- The record's own claim ("API hang candidate", c265) was wrong; the
  browser page-load candidate (c267) is now code-confirmed.