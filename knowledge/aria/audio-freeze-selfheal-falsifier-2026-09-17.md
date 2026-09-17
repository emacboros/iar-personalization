# The falsifier fired: camera-side self-heal exists (2026-09-17, cycle 21)

## What fired

The c19/c20 unified audio-freeze mechanism claimed: a freeze heals ONLY
when something replaces the connection (go2rtc reconnect WRN or ffmpeg
watchdog restart). The standing falsifier was "any freeze healing WITHOUT
a reconnect or restart". It fired today, four times.

## Evidence (all UTC; sophon local = UTC-3; seg names UTC; mtimes local)

### ext1 (.101) -- the 5h22m freeze was actually 6h22m, and the c20 heal claim was wrong

- Audio died SILENTLY at 03:54:47Z (seg 54.47, hour-04 dir, audio=0 from
  there; video mtimes continuous -- no stall, no timeout, no WRN).
- The 07:17:04Z go2rtc read-timeout WRN (which c20 credited as the audio
  heal) did NOT restore audio: hour-07 (07:00-07:59Z) row 225/225 dead,
  hour-08 225/225 dead, hour-09 235/235 dead -- all AFTER the WRN. That
  WRN healed a VIDEO stall only. The recording ffmpeg never re-attached
  (no full stall => no watchdog => same consumer kept pulling audio-dead
  restream).
- Audio returned at 10:16:49Z (seg 16.49, hour-10 dir, audio=1 from there).
  Heal chain: 10:01:43Z i/o-timeout WRN (producer conn died) -> go2rtc
  reconnect -> watchdog restarts 10:09:08Z + 10:13:59Z (restream had no
  frames during the producer gap) -> new recording ffmpeg attached ->
  audio flows from 10:16:49Z.
- Producer id witness: 8147 stable across 04:05Z-10:05Z census runs
  (frozen in place), then 12555 (replaced). CONSISTENT.

### The counterexample class: camera-side self-heal

Four freezes today healed with NO WRN, NO watchdog restart, video flowing
continuously (seg mtimes continuous, no timeout possible):

- int1 (.201) 11h: audio dead 11:03:08-11:26:15Z (~23 min)
- int1 (.201) 11h: audio dead 11:39:45-11:46:39Z (~7 min)
- int1 (.201) 12h: audio dead 12:08:24-12:16:59Z (~8.5 min)
- ext5 (.105) 13h: audio dead 13:02:49-13:13:13Z (~10 min)

All four: video kept flowing (no go2rtc read timeout possible), no WRN in
the window (int1 hour-11 WRN count = 0), no watchdog restart nearby, and
audio simply returned. The camera resumed sending audio RTP on the SAME
connection. prudynt's audio drop is sometimes TRANSIENT.

### The refined mechanism (c21)

The DISEASE is unchanged: prudynt silently stops audio RTP on the
established conn (video keeps flowing => no timeout => no reconnect).
But the RETURN has three paths:

- Heal C (NEW): camera-side self-heal -- prudynt resumes audio on the
  same conn. Minutes-scale. Today: 4/5 freezes.
- Heal B: watchdog restart (ffmpeg re-attaches to a producer whose audio
  is live). Works.
- Heal A (REFINED): go2rtc reconnect alone is INSUFFICIENT -- the
  recording ffmpeg (consumer) keeps its TCP conn to the go2rtc restream
  and does not pick up the replaced producer's audio unless IT also
  re-attaches (watchdog restart). The 07:17:04Z case proves reconnect
  without consumer re-attach leaves audio dead. Heal A+B together is the
  real path (what happened at 10:16:49Z).

Freeze length now has TWO regimes: transient drops self-heal in minutes
(int1/ext5 today); persistent drops last until the next full video stall
triggers BOTH a producer replacement AND a consumer re-attach (ext1:
6h22m because .101 rarely full-stalls).

### Instrument notes

- The ch2 census (hourly) cannot resolve 7-20min blocks -- it sampled
  before and after each self-heal and saw "alive" both times. Cadence
  gap, not a bug. A 5-min cadence would catch producer-conn state during
  a freeze and settle the one remaining ambiguity (whether the producer
  conn audio died during the self-heal blocks, or only the restream path).
- segcensus hour rows are the right longitudinal net; per-segment
  ffprobe audio-presence scans (the transition-collapse loop) are the
  scalpel. mtime gaps with CONTINUOUS seg names are muxer lag, not stalls.
- c20's ext5-h19 closure and the stub-vs-freeze separation still stand.
- c20's "ext1 healed 10:17Z" was right about the TIME but wrong about the
  WRN attribution (the heal was the watchdog re-attach, not the 07:17Z WRN).

## What this changes

- The falsifier list: "heal without reconnect" is no longer a falsifier --
  it is a confirmed heal path. New falsifier: a PERSISTENT (>30min) freeze
  healing with neither conn replacement nor consumer re-attach AND with
  ch2-census proof the producer conn audio never died (that would mean
  the restream lost audio while the producer kept it -- a different disease).
- 0075 escalation bar unchanged (ext1-class latency now 6h22m observed).
- The camera-side WHY (prudynt) still rides 0062; but the new datum is
  that prudynt's drop is sometimes self-recovering -- which smells like a
  resource/pressure condition inside the camera rather than a hard fault.