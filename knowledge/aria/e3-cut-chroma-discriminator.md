# Flag 380: the midnight cut is NOT an ircut flip -- chroma discriminator run (aria c25, 2026-09-04)

## The experiment

The c24 discriminator was: read e3's ircut/colormode state files at
23:50Z vs 00:10Z. But a LIVE probe at the cut would need a cycle
landing in a 20-minute window at 03:00Z -- 17h away. Instead I ran
the discriminator BACKWARD from the recordings themselves: if e3's
camera had flipped to monochrome (ircut) at the cut, the frames
after the cut would have zero chroma. signalstats UAVG/VAVG on
frame 1 of each segment:

**2026-09-04 (last night):**
- e3 hour 01 (mid-block): YAVG 100.11, UAVG 127.993, VAVG 128.013
- e3 hour 02 tail (pre-cut): YAVG 100.6/100.7, UAVG 127.99, VAVG 128.01
- e3 hour 03 head (post-cut): YAVG 87.5 -> 93.7 ramp, UAVG 127.99, VAVG 128.01
- e4 control hour 02 tail: YAVG 100.3, UAVG 127.99
- e4 control hour 03 head: YAVG 100.2-100.4, UAVG 127.99
- e3 day ref (hour 09): YAVG 97.7, UAVG 127.99

**2026-09-03:** same shape. Post-cut e3 UAVG 127.99 except the
first renegotiation segment (00.14: UAVG 131.2 -- the stream-drop
artifact, then back to 127.99).

## The verdict

**Chroma is FLAT at 127.99 through the cut, on both nights, on
both cameras.** 128 = neutral chroma. The frame was ALREADY
effectively monochrome (night mode, color off) before the cut and
stayed so after. There is no ircut flip at 03:00:43Z.

Mechanism (C) -- camera auto gain-switch flipping AT the cut -- is
DEAD as the trigger of the observed step. What remains:

- (B) external light timer: the light changes state at local
  midnight; the camera follows with exposure/gain smoothly (the
  YAVG ramp 87->94 over ~6s post-cut is exposure settling, and
  the +4 YAVG step vs pre-cut is the steadier light).
- (B') the camera's own IR LEDs: daynight controls have ir850/ir940
  = true. If the camera's IR illuminators were involved, chroma
  would still be flat (IR is mono) BUT the brightness step would
  come from the camera itself. However: the daynight switch is
  gain-threshold driven (300/3000), and /run/prudynt/daynight_mode
  is ALREADY "night" at 09:36Z (daytime!) -- wait, that's odd.

## The daynight_mode puzzle (new, unexplained)

Both e3 and e4 report daynight_mode = "night" and colormode.txt = 0
(monochrome) at 09:36 GMT -- in DAYLIGHT (sunrise ~07:30 local).
Yet the day frames are clearly color-capable daylight scenes and
the eye reads them normally. Two possibilities:

1. The mode file is stale (daynight script runs on gain thresholds;
   the file only updates on a switch event, and the last event was
   last night's dusk entry -- no dawn exit recorded?). If the
   camera never switched back to day at dawn, the mode file stays
   "night" while the ISP adapts anyway.
2. The script's state file is written by the switch, but prudynt
   (the binary) manages the actual ISP state independently, and
   the script is vestigial.

Either way: the /tmp state files and daynight_mode are NOT a
reliable live indicator of ircut state. The chroma-in-frames
measurement is the ground truth. This retroactively validates the
c25 decision to measure frames instead of state files -- the state
files would have given a misleading "night" reading at both
23:50Z and 00:10Z (both are night), showing no flip, which would
have looked like evidence for (B) even under mechanism (C).

## What the cut actually is (current best model)

The step is a LIGHT-LEVEL step (YAVG -7 pre->post at the ramp
bottom, then +4 vs pre-cut steady) with a stream renegotiation
hiccup, chroma flat, no profile change, no schedule in config.
The renegotiation hiccup at a light step is itself interesting --
a gain/exposure jump shouldn't renegotiate the stream. Unless the
camera's sensor does a mode change (fps/binning) that go2rtc sees
as stream params changing. But stream0 config is identical
day/night...

Remaining candidates, both external to the camera:
- (B) a physical light on a midnight timer (flicker->steady or
  second source on).
- (B'') the camera's OWN IR illuminators toggling (light ir850/940
  on/off) driven by something other than the daynight script --
  but that would need a trigger at exactly 00:00:43 local.

The dusk onset (photocell-like, ~+27min after sunset) and the
midnight cut are now TWO SEPARATE EVENTS: dusk = real light on
(camera follows); midnight = a discrete change in the light's
behavior. The "which light is it" question (physical) is the
remaining discriminator -- flag 380 narrows to: identify the
physical light (Nacho's knowledge of his own balcony/driveway
lighting is the fastest path).

## Instrument notes

- host ffmpeg is ffmpeg-free (no hevc decoder) -- signalstats on
  frigate recordings must run INSIDE the frigate container
  (runuser -l nacho -c "podman exec frigate ..."), with the
  /media/frigate path mapping.
- metadata=print:key=lavfi.signalstats.YAVG:file=- is the reliable
  extraction (grep on the signalstats log line does NOT work in
  ffmpeg 7 container build).
- Camera API from sophon HOST: cameras are on 192.168.2.0/24 (LAN),
  NOT 10.66.0.x. 10.66.0.103/104 don't answer; 192.168.2.103/104 do.
  The c24 session (from inside the frigate container) was on the
  LAN side. SOPHON-HOST can reach the cameras directly (same LAN).
- run.cgi output: echo of the command in <b>...</b>, then output.
  State files: /tmp/ircutmode.txt (1=day-filter-in), /tmp/
  colormode.txt (0=mono). /run/prudynt/daynight_mode = "night".