# REQ 20260910-aria-0032
filed: 2026-09-10T23:44Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: sophon CPU: localsearch indexer + firefox + first nemotron-vs-frigate stall (20:37)
body: |
  [EXTERNAL DATA: none -- infrastructure findings from aria cycle 170, 2026-09-10 ~23:45Z]
  
  ## 1. localsearch-3 (GNOME LocalSearch/tracker3 indexer) on sophon: standing CPU tax
  
  - Active 9d19h (since boot 09-01), CPU time 7d10h = 78% of one core
    continuously, right now 76%.
  - sophon is the NVR + Ollama host; its 12 cores also run frigate
    (8 cameras + GPU detector), ollama (qwen GPU-resident + nemotron
    CPU inference), and the desktop.
  - The indexer is churning the home dir (which now includes large
    container storage trees). It will never finish; it is a permanent
    background load.
  
  ASK: mask it on sophon (your desktop, your call):
    systemctl --user mask localsearch-3.service
  (or mask tracker-miner-fs-3.service if present). Reversible.
  
  ## 2. firefox on sophon: 61% CPU, running 1d3h
  
  If this is a stale remote session, closing it frees ~0.6 core.
  
  ## 3. NEW: 20:37 -03 all-8-camera watchdog burst = HOST STALL
  
  All 8 cameras watchdogged at 20:37:02 simultaneously (fps-limit
  exceeded). No camera-side RTSP timeouts in the window -- this is
  CPU starvation, not a camera event. Attribution (timing evidence):
  continuo's nemotron-3-super:cloud CPU-inference request (34k in /
  1978 out in 6m2s = 5.4 tok/s CPU decode) was mid-cycle; combined
  with localsearch (0.78 core) + firefox (0.6) + detector (0.36) +
  frigate processes, the 12 cores saturated.
  
  This is the first live sighting of the nemotron-CPU-vs-frigate
  contention class (D-014 put continuo on nemotron:cloud = CPU-only;
  qwen stays GPU-resident). The outlier request was the trigger;
  typical nemotron requests are 2-15s. If it recurs, options: revisit
  D-014 composition, or renice frigate's processes above ollama's CPU
  inference. Watch item filed in my roadmap.
  
  ## 4. fleet-check v2.19 shipped (mine, no action needed)
  
  The v2.18 SEG-TAIL RECOVERY branch was poison-blind (-sseof -2
  decodes fine on poisoned-but-decodable segments) and fired a
  standing FALSE RECOVERY on every run (18:04 -03 feeder run:
  "SEG-TAIL RECOVERED" while duration was 412523s). v2.19 (8f8889ec)
  pairs the tail decode with an ffprobe duration check (threshold
  60s). Live-verified both directions. aria-0028 (camera reboot)
  unchanged -- ext1 re-synced twice today (11:33, 20:37 watchdog
  restarts), both heals temporary, poison returns on next stream
  break.
answer: (none)
