# Camera stall 01:46-01:50 local + ONVIF sweep 05:00:58Z (cycle 286, 2026-09-13)

## Event 1: multi-camera stall with audio/video DIVERGENCE (new anatomy)

Window: 01:46:47-01:50:19 local (04:46:47-04:50:19Z), Sep 13.

Cameras hit: ext3 (.103) hardest, ext5 (.105) moderate, int1 (.201) one
restart. ext1 (.101) and ext2 (.102) clean (recordings continuous, audio
250 pkts/segment throughout hour 04).

### ext3 (.103) anatomy -- the richest sample yet

Camera-side witness (cameras.log sink, UTC):
- 04:47:10Z prudynt WARN `audio encChn:0 - msgChannel sink clogged, 1
  frames dropped in last 5s` -- NEW camera-side symptom: the camera's
  own audio encoder channel backed up.
- 04:47:10Z, 04:47:36Z, 04:48:09Z: three BackchannelStreamState
  "Configuring stream for TCP" sessions (9 lines, 3 ch each) -- the
  mic-probe/wave signature, INSIDE the stall window.

Frigate-side (journal, local -03):
- 01:46:47 Unable to read frames -> 01:46:54 crash (Timestamps unset +
  Connection timed out) -> restart
- 01:47:14 crash (Error opening input: Invalid data) -> restart
- 01:48:14 No frames in 20s -> crash (aac channel element not allocated,
  POC error) -> restart
- 01:48:54 No frames in 20s -> restart
- 01:49:35 No frames in 20s -> crash (aac Queue input is backward in
  time) -> restart
- Recovery by 01:49:57 (segments normal 16s from 49.57 on).

Recording anatomy (the NEW finding): during the stall, ffmpeg kept
writing AUDIO while VIDEO starved. Segments:
- 46.21: 4.4s stub (both streams short)
- 47.27: video 24.8s / audio 25.0s (stretched segment)
- 47.47: video 1.0s / audio 31.6s  <-- audio timeline 30x video
- 48.26: video 2.9s / audio 35.4s
- 49.08: video 1.9s / audio 39.9s
- 49.41: video 20.9s / audio 21.1s (recovery splice)
- 49.57+: normal 16s/16s

Audio pts inside the divergent segments: NO backward jumps, but GAPS
(47.47: 3.128s gap at pts 1.581->4.709; 48.26: 1.078s + 0.542s; 49.08:
1.358s + 0.527s). Audio decodes clean (ffmpeg -f null exit 0). So the
audio path kept producing, with dropouts, while the video path produced
1-3s per 20-40s wall window. This is the DTS-gap class (c279 ext1
22:01) caught LIVE with full camera-side witness: backchannel sessions
+ sink-clogged warning + audio-continues-video-starves.

### ext5 (.105) anatomy
- 47.03 + 47.07: 1.2s stubs (video 6 frames, audio 15/23 frames)
- 47.42: spliced segment 21.5s (video 107 frames, audio 336)
- 47.59+: normal. Frigate: 01:47:32 Unable to read -> 01:47:36 crash
  (Timestamps unset, aac channel element, Connection timed out).
- Full hour-04 audio census: only 47.03 (15) and 47.07 (23) odd; plus
  benign boundary segments (24.45=125, 26.11=323, 59.59=28).

### int1 (.201)
- 01:47:16 No frames in 20s -> restart. One event, clean recovery.

### go2rtc layer
- 01:46-01:48: producer read-timeouts against .103 (x5+), .105 (x1),
  .104 (power-dead, constant). "start from CONN state" on .103 at
  01:47:16. No fps-limit events on ext1/ext2 (their producers rode it
  out or re-dialed silently).

### Interpretation (honest)
The wave-mechanism chain (page load -> paramless GETs -> AddTrack ->
Reconnect -> fleet remake) predicts backchannel sessions + fps-limits.
Here: backchannel sessions present on ext3, restarts on 3 cameras, but
NO page traffic found in the frigate journal (nginx lines absent from
journal in the window -- access log not in journal). The trigger is
unconfirmed. What is NEW and confirmed: the camera-side audio encoder
clogs (msgChannel sink clogged) and the camera keeps emitting audio
while video stalls -- the divergence is CAMERA-SIDE, not frigate-side.
The 3 backchannel sessions in 59s on one camera is wave-shaped.

## Event 2: ONVIF sweep 05:00:58-05:01:05Z (source UNKNOWN)

Sink captured (first time this class is visible):
- .101 (12 lines), .201 (4), .202 (8), .203 (10): onvif_simple_server
  "get_method: Could not find Body element or method" + "XML parsing
  error", FATAL, per-request PIDs (spawned CGI handler).
- 4 of 7 cameras logged; .102/.103/.105 silent (no onvif error lines).
- Timing: 05:00:58-05:01:05Z = 02:00:58-02:01:05 local. A 7-second sweep.

Mechanism REPRODUCED from sophon (05:08:04Z): POST to
http://cam/onvif/device_service with a SOAP envelope lacking a Body
reproduces the exact two-line signature. Route: uhttpd serves
/var/www/onvif/device_service -> onvif.cgi -> spawns onvif_simple_server.
Port 8080 is Prudynt MJPEG (401), NOT the onvif path.

Source: UNKNOWN. Exonerated: aria-dashboard.sh (no onvif), fleet-check.sh
(no onvif), rage/fear organs (no onvif), fleet-feed (ran 03:01Z, not 05:00Z).
No sophon journal entries at 02:00:58-02:01:05 local matching a probe run.
Candidates: yoga-side tool, Nacho's phone/app (note: .201 is a PTZ camera,
hostname ptz-1 -- PTZ controller apps do ONVIF discovery sweeps), or
something else on the LAN. Cameras are LAN-side (192.168.2.x), not
WG-exposed.

CORRELATION HYPOTHESIS (unverified): the dropbear brute-force at
03:39:48Z (3x root pw from 192.168.2.69 = sophon, source UNIDENTIFIED,
c283) and this ONVIF sweep are both camera-directed scanning from inside
the LAN within 80 minutes. Could be one actor. OR the dropbear attempt
was sophon-local (some process with wrong creds) and unrelated. Filed to
relay for Nacho -- he can see interactive sessions and yoga-side state.

## Sink verdict
The cameras.log sink caught BOTH events with camera-side witnesses that
frigate's journal cannot provide (backchannel configs, encoder clog,
onvif probe errors). First night of full operation = two new classes
visible. The instrument paid for itself twice in one night.

## IP map (confirmed this cycle)
ext1=.101, ext2=.102, ext3=.103, ext5=.105, int1=.201 (ptz-1),
int2=.202, int3=.203. ext4=.104 (power-dead).

## Watches
- ONVIF sweep: watch for recurrence; if it repeats, tcpdump port 80
  on-camera or sophon-side to capture the source IP.
- Audio/video divergence: new census predicate -- video_dur vs
  audio_dur per segment. A segment with audio_dur > 2x video_dur is a
  stall witness even when the journal rolled.
- int1 06:00Z splice watch: still pending (fires ~06:00Z).
- Boot-activation full-wave census: still pending (~09Z).