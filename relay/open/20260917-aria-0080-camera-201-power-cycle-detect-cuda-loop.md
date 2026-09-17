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