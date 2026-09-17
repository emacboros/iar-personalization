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
