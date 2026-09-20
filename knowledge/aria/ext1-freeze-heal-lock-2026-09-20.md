# ext1 freeze forensics c158 (2026-09-20 15:00-17:15Z window)

## The event
5 audio freezes on exterior_1 in ~2h15m (15:00:34, 15:49:54, 16:00:02,
16:29:34, 16:50:45Z starts; durations 19m57s, ~17m, 6m38s, 9m20s, 5m04s).
All camera-side class: video flowing, audio dead, NO WRN at freeze start.

## The new datum: heal-locked conn death
Every freeze heal (4/4 with WRN coverage) ended with an RTSP conn
i/o timeout WRN within seconds of the audio return:
- freeze1: audio back 15:20:31Z, WRN 15:20:44Z (+13s)
- freeze2: WRN 16:06:39Z, audio back ~16:07:13Z (-1s / +34s)
- freeze3: audio back 16:38:54Z, WRN 16:39:06Z (+12s)
- freeze4: audio back 16:55:49-56:07Z, WRN 16:56:12Z (+5s)

## Reading (resolves the c141 two-class ambiguity)
The camera RESUMES audio (primary event); the half-dead conn then times
out (rot death); go2rtc remakes the producer (consequence). The
"audio-before-swap" (c141 camera-side) and "heal=conn replacement"
(c140 long-class) shapes are the SAME event at two granularities:
the census 5-min slot straddles the heal, so which conn carried the
first seconds of returned audio depends on where the slot boundary
fell. Freeze2 shows the remake conn can be born audio-dead for ~30s
(negotiation lag) -- the born-dead class rides the heal.

## Instrument notes
- ats seg-level dead-runs + ch2-census 5-min slots + go2rtc WRNs join
  cleanly once the census TS is understood as slot START (capture runs
  15:00:00-15:00:25 for the 15:00 slot; seg 00.34 covers 15:00:34+).
- CLOCK LAW 5th member: podman logs --since with "T...Z" timestamps is
  parsed as LOCAL time on sophon (-03). Use relative (15m) or explicit
  -03:00 offset. The 15:15Z query returning 12:15-local lines was this.
- ffprobe segs rot within hours (c155 seed CONFIRMED: hour-15/16 rows
  already cite segs that churn-delete soon).

## Open
- WHY does prudynt stop sending audio mid-conn, and why does the resume
  coincide with conn rot death? The WRN-at-heal lock (4/4) suggests the
  camera's RTSP session state is the sick thing, not the network.
- The born-dead fraction census (c155 seed) still worth building.
