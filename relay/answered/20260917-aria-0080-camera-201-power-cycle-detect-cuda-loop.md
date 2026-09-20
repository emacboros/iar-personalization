# REQ 20260917-aria-0080
filed: 2026-09-17T20:35Z
filer: aria
class: nacho-external
state: open
urgent: no
title: camera .201 power cycle: detect-ffmpeg CUDA filter-init loop + audio clock chaos
body: |
  NEW failure class on interior_1 (.201), 2026-09-17. Two symptoms:

  1. AUDIO CLOCK CHAOS: at 19:01:54Z the camera's audio DTS jumped ~11h
     mid-session (DTS 3801664718 vs session-age 296923000 at 90kHz).
     Timestamps-unset + DTS-dropping errors followed.

  2. DETECT-FFMPEG RESTART LOOP: from 19:09:54Z, frigate's interior_1
     detect ffmpeg (hwaccel cuda path) fails filter-graph init with
     "Impossible to convert between the formats supported by the filter
     'Parsed_fps_0' and the filter 'auto_scale_0'" + error -38 (ENOSYS),
     every restart, every ~20s. BURSTY: 16:09-16:19, 16:49-17:13,
     17:22-17:27+ local. Recordings STOP during bursts (maintainer
     discards 44-byte stubs), resume in quiet gaps.

  NOT stream shape (all 8 cameras: identical SPS, yuv420p, 1280x720,
  5fps; fresh CPU-path ffprobe normal), NOT GPU OOM (9.0/10.2GB, no CUDA
  errors). The same "Impossible to convert" error appeared on ext3 at
  17:54-18:0xZ, ~10 min before its 18:05Z fatal window -- early-warning
  signature of degraded stream negotiation.

  Doc: knowledge/aria/int1-cuda-filter-loop-2026-09-17.md (b0a3276c).

  REQUEST: physical power cycle of camera .201 on the next visit (rides
  the 0063/.104 visit). The falsifier: if the burst cadence does NOT
  change post-reboot, the trigger is the go2rtc<->detect negotiation
  path, not camera state. No remote fix attempted (camera standing mode
  is full-access per D-018, but a reboot mid-burst would destroy the
  evidence the pre/post comparison needs).
UPDATE 2026-09-17T21:20Z (aria c33): the detect CUDA loop is a SYMPTOM.
The established go2rtc producer conn to .201 carries video=0/audio=11
(ch2census 21:15-21:17Z) while the camera serves video fine on NEW conns
(ffprobe direct 94-116 pkts/10s x7 probes). Detect restarts track the
census video=0 windows 1:1. One continuous degradation window
19:09-21:15Z (c32's "bursts" = census sampling aliasing; corrected).
go2rtc never re-dials on video-track death (0060 gap, video variant).
Doc: knowledge/aria/int1-video-track-conn-degradation-2026-09-17.md.
Falsifier sharpened: a go2rtc producer re-dial (PATCH /api/streams?src=
interior_1) is testable REMOTELY before the physical visit -- if re-dial
heals and degradation recurs, camera-side (power cycle still valid); if
it stays healed, go2rtc-side only. PATCH body-form returned 400 (stream
defined in frigate config); correct API shape is next-cycle work.
UPDATE 2026-09-17T21:57Z (aria c34): RE-DIAL TEST EXECUTED AND SUCCEEDED.
Path (after PATCH body 400 + PUT name-as-source corruption + PATCH
no-op echo): DELETE runtime registration + restart go2rtc inside the
frigate container (s6-svc -r /run/s6-rc/servicedirs/go2rtc; config
yaml in /dev/shm still defines interior_1). Fresh producer (id 50)
delivers BOTH tracks (hevc +412/20s, aac +319/20s), ch2 census ch2=211/
ch0=285, detect ffmpeg attached with filter init PASSED, zero
Impossible errors since 18:55:21 local, segments writing again.

RESULT: the camera is healthy; the ESTABLISHED producer conn was the
disease carrier. go2rtc never re-dials when a track dies (0060 gap,
BOTH variants now proven: audio-only c19/c21, video-track c33).

NEW FINDING -- TRACK FLIP: the same conn carried both diseases in
sequence: video=0 19:09-21:15Z, then audio=0 21:47-21:52Z (census
FROZEN; API aac packets flat over 30s = confirmed). One conn, two
track deaths, opposite order. prudynt degrades tracks independently
on long-lived conns.

REVISED REQUEST: the power cycle is still worth it (clock chaos + the
camera-side trigger for the track deaths), but the amplifier is now
proven: go2rtc's no-re-dial turns any track blip into an hours-long
outage. A go2rtc-side reconnect fix would have prevented today's
entire 19:09-21:55Z outage without touching the camera.
Watch: producer id 50 health (next cycles). If a track dies on the
fresh conn too, the camera-side trigger is fast; if it stays healed
for hours, degradation is long-conn-specific.
Doc: knowledge/aria/int1-redial-test-2026-09-17.md (f70d73b2).

UPDATE c35 (2026-09-17 ~23:16Z) -- CHRONIC CHURN CENSUS:
The c34 watch question ("does the fresh conn stay healthy?") answered
itself: conn 338 died SILENTLY at 23:05Z (~28 min after birth), go2rtc
re-dialed without logging anything, conn 461 healthy within a minute.
Census FROZEN row caught the window; API packet-delta confirmed.

The bigger find: .201's RTSP conn churn is CHRONIC -- 97/131/108
WRN-visible conn deaths per day (Sep 15/16/17), ~1 per 15 min, diurnal
shape (day 8-13/h, night 0-4/h). WRNs UNDERCOUNT (silent deaths exist).
RSSI is strong (-49..-54 dBm), so this is prudynt software instability,
not signal.

TWO-MECHANISM PICTURE (both confirmed live):
1. Conn death: common, chronic, self-healing via go2rtc re-dial
   (sometimes silent; occasionally costs a detect crash + watchdog
   restart, as at 23:06Z tonight).
2. Track death on a LIVING conn: rare, NO re-dial, hours-long outage
   (the 19:09-21:55Z disease). go2rtc is blind to this one.

POWER-CYCLE FALSIFIER (sharper now): if churn drops to ~0 for days
after the power cycle, prudynt state accumulation is the trigger.
If churn resumes immediately, it is steady-state prudynt behavior and
the fix is upstream (go2rtc reconnect for mechanism 2, thingino
update for mechanism 1).
Doc: knowledge/aria/int1-chronic-conn-churn-2026-09-17.md (b2ee803d).

## AMENDMENT (aria c37, 2026-09-18 ~00:52Z): churn census corroborated + AP topology fact

The chronic churn census (97/131/108 WRN-visible conn deaths/day,
Sep 15/16/17) now has a structural candidate: .201 sits on
nacho_guest (72:7f:f0:1e:4a:a8) which shares channel 1 (2417 MHz)
with nacho_camaras (08:8a:f1:6a:62:56). Co-channel interference
between the two APs is a standing condition, not an event. The
power cycle remains the state-reset falsifier; if churn resumes
immediately after, co-channel interference becomes the primary
suspect and a channel split (camaras -> ch6/11) is the cheap fix
that rides this filing. RSSI data unchanged (-50/-51 stable).
