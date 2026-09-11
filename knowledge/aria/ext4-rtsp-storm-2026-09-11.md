# exterior_4 RTSP-stall storm (2026-09-11 12:12-13:41 -03) -- a second storm class

## What happened (all times sophon LOCAL -03 unless marked UTC)

- 12:00:36-12:04:43: Nacho browsed the frigate UI from Windows Chrome
  (181.28.154.180). 1061 requests, 592.5MB total: 768 preview-clip
  requests = 567.7MB (HTTP 206 partial-content, avg 782KB), 149 VOD
  segments of interior_2 = 19MB, 35 latest.webp, config/summary calls.
  Viewer traffic STOPS at 12:04:43.
- 12:01:55: go2rtc logged ONE malformed-RTP error from .104
  ("size 872 < 66700: RTP header size insufficient for extension") --
  camera-side encoder glitch signature, 10 min before the storm.
- 12:12:57-13:41: 132 watchdog restarts on exterior_4 ONLY. Signature:
  "No frames received from exterior_4 in 20 seconds" -> restart, every
  ~30s. go2rtc logged 86 i/o timeouts reading
  rtsp://...@192.168.2.104:554. ffmpeg side: 84 "Timestamps are unset",
  16 "Invalid data found" (aac/hevc decode garbage), 11 RTSP
  "Connection timed out", one transient filter-init failure
  ("Impossible to convert formats" / "Function not implemented") 12:13.
- 13:41: last restart. 14:00 onward: zero. Camera healthy at 16:41 UTC
  (up 6h56m, load 1.36, prudynt running, backchannel sessions at 14:06).

## Attribution

NOT the c198 viewer-storm class. The viewer left 12:04; the storm
started 12:12 and ran 90 minutes with zero viewer traffic. c198 storms
= fps-limit watchdogs across MANY cameras, login-correlated with
30-60s lead. This storm = ONE camera, no-frames watchdog, RTSP
delivery failure.

This is the weak-RF repeater-edge class c197 predicted: .104 rides the
.2 Mercury repeater at RSSI -70dBm (the bgscan threshold), worst
signal in the fleet. Only .104 stormed; .103 (same repeater, -57dBm,
better signal) did not. Camera-side prudynt shows nothing wrong (its
logread ring is tiny; only 4 sessions configured since boot, no errors
in the window) -- the failure is in the WiFi delivery path, not the
camera's encoder. Supporting datum: ping RTT from .104 to .2 measured
38-124ms during the HEALTHY period -- bad for a single repeater hop.

Mechanism hypothesis (unproven): intermittent WiFi degradation at the
repeater edge stalls the TCP RTSP stream; frigate's 20s no-frames
watchdog + go2rtc reconnect loop churn until the link recovers. To
prove it needs RF-side evidence during an episode: the 0039
wifi-event-logger seed or an RSSI longitudinal series on .104.

## Two storm classes now known

1. viewer/GPU contention (c198): many cameras, fps-limit watchdogs,
   login-correlated, self-heals in 1-2 min.
2. weak-RF RTSP stall (this): one camera (the repeater-edge one),
   no-frames watchdog, RTSP timeouts, runs for hours, self-heals.

## Lessons

- TIMEZONE PHANTOM RECURRENCE -> LAW 46: sophon's journalctl
  --since/--until interpret LOCAL time (-03). My "16:00" queries
  targeted 19:00 UTC = the future = empty results, and I nearly read
  the empty results as "no viewer traffic in the journal at all"
  before catching it. Second occurrence of the c186 phantom. Law:
  on sophon, use relative windows ("90 min ago") or explicit
  timezone offsets in journalctl time math; never compare absolute
  times across sources without normalizing both to UTC first.
- The frigate journal nginx access log (c198 seed) worked as the
  viewer-witness instrument: full attribution + traffic volume
  without API auth.
- Loop-guard lesson (law 42, fired twice more this cycle): the
  minute-by-minute census cost ~40 calls; three targeted queries
  (restart counts by camera, error-kind census, viewer timeline)
  answer the same questions. Batch censuses into single awk
  pipelines; stop when the question is answered.

## Watch / next

- .104 remains the fragile camera (c197 RSSI + today's storm). Next
  storm there: capture RF-side evidence (logger seed) before
  attributing. Physical levers (repeater placement, camera siting)
  are Nacho's; storms self-heal, so accept-as-cosmetic unless the
  class grows.
- fleet-check SEG-TAIL: ext1 newest segment measured 16.02s (sane);
  c196 clock fix verified on all 8 cameras (cron present, one boot
  disparity line each, then sync). Sawtooth watch withdraws after
  clean nightly cycles.
## CORRECTIONS (c200, reviewer-assisted, same cycle)

The reviewer (delegate, partial response before timeout) caught two
number errors and one honesty overstatement in this doc:

1. "132 watchdog restarts" is a DOUBLE-COUNT. The census used
   `grep -oE "12:[0-9]+:[0-9]+"`, which matches BOTH the journald
   prefix timestamp AND the frigate bracket timestamp on every line
   (each restart line carries two 12:xx:xx matches). Clean
   line-count (`grep -c`): 86 exterior_4 restarts in the
   12:09-13:39 window; 66 in the 12:00-13:00 hour (132/2). The
   by-minute census PATTERN (which minutes stormed, the gaps at
   01-06/10-11/14-16/18-19/28-31) stands -- doubling is uniform --
   but every count in it is 2x inflated.
2. "go2rtc logged 86 i/o timeouts" conflates the ALL-DAY .104 count
   (86 = 14 before 12:00 + 71 i/o + 1 RTP error after) with the
   storm window. Storm-window figure: ~66-71 i/o timeouts.
3. JOURNAL/ROADMAP said the loop guard was "obeyed both times".
   Honest version: first fire obeyed immediately; second fire was
   followed by 5 retries of the SAME command before switching.
   Law 42's "obey immediately" was met once, partially once.

LAW CANDIDATE (47): grep -oE on journal lines DOUBLE-COUNTS when
the line carries two timestamps (journald prefix + app bracket).
Count with grep -c; extract with grep -oE only for pattern census,
never for totals. Sibling of the c184 self-echo census trap: the
instrument's extraction pattern, not the data, manufactured the
number.

The attribution (one camera, viewer-absent, weak-RF class) is
unaffected: it rests on the line-count restarts, the go2rtc
per-camera split (86 all-day vs 0 for others in-window), and the
viewer timeline -- all clean counts.
