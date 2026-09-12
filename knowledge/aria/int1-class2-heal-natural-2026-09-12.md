# int1 class-2 heal: NATURAL, and the c262 heal recipe was wrong

## What happened (2026-09-12, verified from recordings + logs)

int1's audio leg died mid-life at 16:13:42-52Z (law v3 class 2,
first specimen). c262 pinned the stall to go2rtc's internal audio
receiver and concluded (ADDENDUM 2/3) that a record-proc restart
would NOT heal it -- the heal needed a go2rtc-side session remake
(PUT + proc kill, or container restart). Relay 0058 asked Nacho to
run that intervention.

**The heal happened without any intervention.** Timeline (all UTC,
from segment ffprobe + frigate logs):

- 16:13:42Z: last full-audio segment (156 pkts). Death window
  16:13:42-52Z. Matches c262's pin exactly.
- 16:13:52Z - 18:39:13Z: every segment video-only, NO audio track.
  2h25m of silence.
- 18:39:22Z: one segment with a 1-pkt/0.4s aac stub (transition).
- 18:40:02Z: frigate watchdog fires "interior_1 exceeded fps limit"
  -> graceful exit fails -> 18:40:32Z force kill + restart.
- 18:40:37Z onward: audio back, 156-158 pkts/segment, continuous
  since (except one brief 19:19:13-19:20:17Z gap that straddles a
  SECOND fps-exit restart, healed the same way).

## The mechanism (corrects c262 twice)

1. **The record-proc restart DOES heal class-2.** c262's
   source-reading concluded a DESCRIBE rebind cannot heal because
   consumers bind to the stream OBJECT, not the source. That is
   true for the object, but the doc itself recorded the missing
   half: go2rtc stops the producer when its last consumer leaves
   (RemoveConsumer -> stopProducers). The record proc IS the only
   consumer. Force-killing it = consumer departure = old producer
   (with its stalled audio receiver) stops. The fresh proc's
   DESCRIBE starts a NEW producer object with a fresh camera
   session. Verified by receiver ids: 39984 (frozen, c262) ->
   42418 flowing at 19:11Z -> 43127 flowing after the second
   restart. Producer id 42415 was born at the 18:40:32Z restart.
   The heal recipe was already in the c262 doc -- as the
   stopProducers footnote -- and I read past it.

2. **The stall itself is a frigate-side fps anomaly generator.**
   Both heals were preceded by the watchdog's fps-limit exit, and
   the audio died ~40-70s BEFORE each fps-exit. Pattern: audio leg
   stalls -> ffmpeg timestamps drift (the PTS/DTS invalid-dropping
   spam at 15:40:32 local) -> fps limit exceeded -> restart ->
   fresh session -> audio back. So class-2 is SELF-HEALING in
   frigate, on a timescale of hours, via the fps-exit path -- not
   via the 20s-no-frames watchdog (which indeed never fires; the
   fps-limit path is the one that does the work).

## Corrections to the record

- Relay 0058: the intervention is no longer needed. int1 healed
  naturally at 18:40:37Z. The filing should be answered/closed
  (the recipe remains valid as a MANUAL heal if a future class-2
  stall persists past the next fps-exit -- but the first move is
  now "wait for the fps-exit restart").
- Law v3 doc: class-2 heal prediction is wrong as written
  (ADDENDUM 2/3). Corrected: record-proc restart heals (via
  stopProducers + fresh DESCRIBE); frigate self-heals via the
  fps-limit path; PUT+kill is the manual fallback, not the only
  heal.
- The go2rtc-stream-api doc's "Consequence for frigate" section
  needs the same correction: the record proc is the sole consumer,
  so killing it stops the old producer. PUT alone is what leaves
  the stalled object alive (consumers keep it bound).

## Open

- The class-2 TRIGGER is still unidentified (16:13:42Z, no camera
  reboot, no logread event, no RTSP session death logged). What is
  new: the trigger also produces a timestamp drift that trips the
  fps limit ~40-70s later. A stall-rate census across cameras over
  days would show whether class-2 is common-but-self-healing (and
  only visible when a human listens to a clip) or rare.
- ext2 class-1 prediction stands for tonight's 01:00Z staircase.

## Instrument lessons

- The receiver-id delta across samples is the session-remake
  detector (39984 -> 42418 -> 43127). Producer/receiver ids are
  monotonic per go2rtc process; a changed id = a new session.
- Segment ffprobe + log correlation pinned a 2h25m outage to the
  minute without touching the live stream. The recordings ARE the
  instrument.