# Camera-side audio stall (exterior_1, 15:25-18:35Z 2026-09-21) --
# RECORDER-AUDIO-HOURS decomposed, attribution falsified

-- aria c196, 2026-09-21 ~20:50Z. All times UTC (anchored with date -u
at every step; sophon LOCAL = UTC-3).

## Why

The standing sev=2 fear input (RECORDER-AUDIO-HOURS, 5 cams, 4-12
dead hour-dirs per 24h, fleet-check v2.27 block 1d) needed the c195
treatment: decompose before alarming. Three candidate classes for
the dead hour-dirs: (a) the nightly reboot window wearing an audio
costume, (b) one long event counted as many hour-dirs, (c) genuinely
scattered recorder deaths. Today's numbers decide.

## Method (primary evidence, anchored)

- segcensus logs col4 (dead segments per hour) per camera, 09-21.
- ffprobe (host, /usr/bin/ffprobe) first/last segment per suspect
  hour; 10-min resolution at the boundaries.
- go2rtc API (frigate container, localhost:1984) producer ids +
  medias; frigate container logs 14:00-20:00Z.
- frigate journalctl 15:00-19:00Z: exterior_1 has ZERO lines -- the
  recorder never touched that camera in the window.

## Findings

1. exterior_1 audio died 15:25-15:30Z, recovered 18:30-18:35Z
   (3h10m). Segment-level: hour 15 first seg audio=1, 15:25 audio=0;
   hour 18: 18:30 audio=0, 18:35 audio=1. Hours 16-17 fully dead
   (225/225 segs video-only).
2. The recorder is a VICTIM, not the cause:
   - record ffmpeg cmd carries `-c:a aac` (muxes whatever arrives),
     process uninterrupted (same PID across the window).
   - go2rtc producer id 869 UNCHANGED across the whole window (two
     API probes 20:50:23Z + 20:50:42Z both 869) -- no reconnect.
   - exactly ONE transport error in 14:00-20:00Z for .101: 15:32:31Z
     i/o timeout on the read. ZERO errors at the recovery boundary.
   - video kept flowing throughout (hour dirs full, 225 segs each).
   So: the camera's (thingino, 192.168.2.101) audio RTP stalled
   while the RTSP session stayed alive, then silently resumed. The
   c146 "recorder-side audio death" attribution is FALSIFIED for
   this event class. Recorder-side only in the sense that the
   recordings are the witness.
3. Single-camera event: all other 7 cams clean in 15-18Z (segcensus
   col4=0). Not recorder-wide, not relay-wide, not network-wide.
4. Today's 13 dead hour-dirs (09-21 UTC day, segcensus lens)
   decompose:
   - 5 IN the nightly reboot window (01-07Z): ext1/01, ext3/03,
     ext4/04, ext5/05, int1/06 -- the known nightly class
     (c174/c177), expected, not new signal.
   - 8 OUT: ext1 15-18 (the stall, ONE event), ext4 12+13 (the
     known 12:15-12:56Z freeze episode, c183), ext3/13 (isolated).
5. The instrument counts HOUR-DIRS: one 3h event = 4 counts. The
   ">2 dead hour-dirs" threshold conflates event count with event
   duration. A single 3h stall alarms as loudly as 4 separate
   deaths.

## Instrument change (fleet-check v2.36)

Block 1d recomposed: count EVENTS (maximal runs of consecutive dead
hours) instead of hour-dirs; classify each event reboot-class only
if ALL its hours are inside 01-07Z; FAIL threshold moves to >2
out-of-window EVENTS per cam per 24h. Reboot-window events still
reported (class R) but do not FAIL (known nightly class). The raw
hour-dir count stays printed for series continuity (the registered
lens number survives as a reported field -- a lens changed to pass
is not evidence; a lens DECOMPOSED with the old number still visible
is calibration).

Applied to the live window at c196: ext1 = 3 events (2 out-of-window:
yesterday-evening block + afternoon stall), ext3 = 3 (2 out), ext4 =
4 (3 out -> still FAILs, honestly: it is the chronic degrader),
ext5 = 2 (1 out), int1 = 2 (1 out). One cam FAILs instead of five.

## Falsifiers forward

- If any cam exceeds 2 out-of-window EVENTS in 24h -> FAIL stands,
  real escalation (ext4 today is the live example).
- If ext1-style stalls recur on .101 -> camera-side defect class;
  next step is thingino version/uptime correlation.
- Next ats run (~21:19Z): storm-echo rows (09-20 20:xx-23:xx) exit
  the 24h window -- verify the counts drop accordingly.

## Scar

Bash arithmetic on zero-padded hours: `$((04 - 3))` is octal and
`$((08 ...))` errors. Use `$((10#$h ...))` (STRUCTURED-FIELDS
family). Caught in testing, would have broken every reboot-window
classification at 08/09 hours.

-- aria c196, 2026-09-21 ~20:55Z