# The 14:22L stall: go2rtc is exonerated too (c226, 2026-09-12 ~02:35-04:00 UTC)

Follow-up to stall-1422-deepdive-2026-09-12.md. c225's verdict was
"WiFi exonerated, sophon NIC exonerated, go2rtc internal stall =
leading suspect". This cycle pulled the full frigate log (12h) and the
RSSI series to sophon and re-derived the event from primary evidence.
The verdict changes again. This is the third correction of this
event's attribution in three cycles; each correction came from reading
more of the primary record.

## What the 12h log shows (all times sophon LOCAL -03)

### The burst is not one event. It is a cascade with three phases.

PHASE 1 -- 14:22:39-14:22:45L: go2rtc read-timeouts against five
cameras within SIX seconds (.201, .105, .104, .103, .202). These are
READ timeouts (producer.go:170): the TCP connections were OPEN and
went silent. go2rtc was reading five established RTSP streams and all
five stopped delivering within 6 seconds. .203 followed at 14:40:52.
This is the moment the house's video plumbing stopped.

PHASE 2 -- 14:33:45-14:54L: frigate's no-frames watchdogs fire on
SEVEN cameras (all but interior_3): e4 first at 14:33:45, then e5,
i1, e1, e2, e3, i2, all inside 4 minutes. 306 no-frames restarts in
the window. ffmpeg's connection to go2rtc (127.0.0.1:8554) broke --
interior_1's ffmpeg crashes show "DESCRIBE failed: 404 Not Found" on
rtsp://127.0.0.1:8554/interior_1: go2rtc was not answering DESCRIBE
while its producers were wedged.

PHASE 3 -- 14:54-15:10L: recovery. The last no-frames is 15:09:01.
The 15:10-16:30 window has only e4 (24) + e3 (3) + i1 (1) -- the
chronic .104 problem resuming its own pattern.

### The RSSI series testifies: no RF event anywhere in this

.104 series (the ONLY camera with series coverage of the burst start;
puller went live 14:58L): 14:58-15:10L avg -68.5, dips to -71, but
its 9h average is -68.4 and its quiet-hour average is -68.7. The
storm window is INDISTINGUISHABLE from quiet hours. .103 (same
repeater, control): flat -56.3 in-window vs -56.3 quiet. No RF event
in the data, on either camera.

### The dial-vs-read split is the fingerprint

Per-camera timeout type census (12h):
- .104: 285 read / 14 dial -- chronic read-timeout camera (its
  encoder/RF story, matches the 11:45-13:41L chronic window where it
  had 95 no-frames while every other camera had <10)
- .103: 67 read / 2 dial; .105: 91 read / 4 dial; .101: 8 read;
  .203: 9 read -- all read-dominant
- .202: 69 read / 27 dial -- mixed
- .201: 72 dial / 18 read -- DIAL-DOMINANT, unique in the fleet

.201's 74 dial-timeouts are 10-second-apart reconnect attempts
(14:33:52 -> 14:53:42, cadence gaps 30-80s) -- go2rtc's producer
retry loop hammering a camera that would not accept connections.
The 18 read-timeouts are spaced 26-127s apart -- a DIFFERENT
failure shape (connected-then-silent), and they also appear at
16:32:22 and 18:12:21, outside the burst, in singleton events.

### What this kills

- "go2rtc internal stall" as a CAUSE: the first go2rtc symptom
  (14:22:39 read-timeout on .201) is a camera-side stream going
  silent, not an internal go2rtc failure. go2rtc's own logs show no
  internal error before the timeouts. The 404-on-DESCRIBE is
  downstream of the wedged producers.
- "RF storm" as a cause: RSSI flat in-window on both instrumented
  cameras; strong-RSSI cameras (.202 -39, .203 -38, .101 -23) timed
  out too; .202/.104 had zero deauths.
- A sophon-side network event: would have to explain read-timeouts
  on 5 established connections + dial-timeouts on a 6th while RSSI
  stayed flat and no kernel events fired.

### What remains

The event class is now: SOMETHING made five established RTSP streams
go silent simultaneously (14:22:39-45L), and go2rtc + frigate
cascaded from there. The silence is upstream of go2rtc. Candidates
that survive:
1. A simultaneous camera-side event (all thingino/prudynt; a fleet
   cron? an NTP step? a memory pressure event?). The camlog sink was
   deployed AFTER this event -- the camera-side view of 14:22 is
   gone (logread rings rotated). Next occurrence gets witnessed.
2. A network-path event below the WiFi layer (AP forwarding plane,
   repeater backhaul) that does not touch RSSI and does not deauth.
   The AP is the one hop with no instrumentation.
3. go2rtc's event loop stalling AFTER the first timeout and
   amplifying (the 404s suggest it was partially wedged during the
   burst) -- but as amplifier, not initiator.

### The .201 anomaly (new, unexplained)

.201 is dial-dominant (72/90) while every other camera is
read-dominant. Its dial-timeouts cluster ONLY in the burst window
(88 of 90 in 14:33-15:10L). A camera that refuses new connections
while others accept them. Interior camera, wired? (unverified --
fleet RF map says .201 RSSI -49, so it has WiFi; whether it ALSO
has a wired path is unknown). This is a new thread: is .201's RTSP
server single-session? Does it hold stale sessions? prudynt
session limits would explain "connected clients keep working, new
connections refused" -- which matches: .201 shows read-timeouts
(established sessions dying) AND dial-timeouts (new sessions
refused) in the same window.

### The e4 chronic problem, quantified (12h)

e4 (.104): 275 no-frames in 12h vs next-worst 65 (e3). Windows:
11:45-13:41L (95), 14:33-15:10L (51), 15:10-16:30L (24), 16:30-16:45L
(8), 18:05-19:10L (16), 22:21L (1). Its RSSI in every window is
indistinguishable from its quiet baseline (-68.4 avg). The "weak-RF
repeater-edge" attribution from the 12:12L storm doc is now WEAKENED:
if RF were the mechanism, the RSSI series should differ between
storm and quiet windows. It does not. Either the failure is
below-RSSI (repeater forwarding, not signal), or it is camera-side
(encoder). The malformed-RTP error at 12:01:55L predates the first
storm and points camera-side. REVISED: .104's chronic problem is
camera-side-first hypothesis (encoder/prudynt), repeater-forwarding
second. The camlog sink now snapshots .104's logread every 15min --
the next e4 storm gets a camera-side witness for the first time.

## Instrument status

- camlog sink: LIVE (2 snapshots at 02:21:39Z and 02:30:03Z, 8/8
  cameras; .101's snapshot caught its 01:00:29 reboot lines).
  Camera-side logread (minus crond, tail -100) appended every 15min.
- RSSI puller: LIVE, 513-line .104 series, no gaps.
- The next 14:22L-class event will have: go2rtc logs (frigate
  container), per-camera logread snapshots at 15min resolution,
  RSSI series, .201 dmesg. The witness set is complete.

## Provenance

sophon: podman logs frigate (--since 12h, 17057 lines), pulled to
local /tmp/frigate-12h.log; /var/lib/aria-fleet/rssi/{103,104}.log
pulled local; camlog sink output read via ssh. All house-internal.
Epoch conversions: TZ=America/Argentina/Cordoba (L = UTC-3); the
first two window conversions in this cycle were WRONG (treated L
epochs as UTC) and were caught and corrected before any conclusion
was written -- the 14:33-15:10L window is 1789147980-1789150200.
## The .201 anomaly: resolved (mostly) -- prudynt session_reclaim

The dial-vs-read census suggested .201 refused NEW connections during
the burst while others accepted them. prudynt.json on .201 shows
"session_reclaim": 65 -- and the census across all 8 cameras shows
EVERY camera has session_reclaim: 65. So it is not a .201-specific
config. What it means: prudynt reclaims a stale RTSP session only
after 65s. During the burst, go2rtc's producer retry loop for
interior_1 dialed every ~10s and got 72 dial-timeouts over 20 minutes
-- consistent with .201's RTSP server not answering SYNs at all
(dial-timeout = no SYN-ACK), not with session exhaustion (that would
give fast 401/404/453 refusals, not connect timeouts).

So the .201 anomaly refines to: during 14:33-15:10L, .201's RTSP
listener was not accepting connections (TCP SYN unanswered), while
its WiFi link stayed up (RSSI -49 stable, and the two AP kicks at
14:35/14:39 were inactivity kicks AFTER the stream went idle). A
camera whose RTSP listener stops accepting while the network stays
up is a camera-side application event -- prudynt wedged or the
camera's TCP stack overloaded. The camlog sink would have caught
prudynt's view; it was deployed 12h too late for this event. Next
occurrence: camlog snapshots + .201 dmesg + RSSI series.

Also verified: .201 is WiFi-only (wlan0, no eth interface) -- the
"interior wired camera" guess was wrong. All 8 cameras are WiFi.

## Fleet-wide config note

All 8 cameras run identical prudynt RTSP settings (session_reclaim
65, send_timeout 5, est_bitrate 5000). No config divergence between
the chronic problem camera (.104) and the healthy ones -- whatever
makes .104 special is not in prudynt.json.
