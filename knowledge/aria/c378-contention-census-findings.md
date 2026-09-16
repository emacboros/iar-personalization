# c378 findings v2 -- CORRECTED after live ffprobe checks (22:40Z)

## CORRECTION to findings v1: ext5 audio RECOVERED at h22 boundary

Live ffprobe of latest segments:
- ext5 h22 latest (22/38.26.mp4): video+audio -> RECOVERED
- ext5 h21 latest (59.57.mp4): video only -> dead at end of h21
- ext5 h20 latest: video+audio -> alive at end of h20?!

Wait: h20 latest has audio, h21 latest video-only, h22 latest has audio.
That matches segcensus: h20 1 dead, h21 68 dead, h22 (pending fire).
So ext5's audio died DURING h21 (22:00-23:00 local = 00:05-01:05Z...
no wait. segcensus hour labels are UTC. h21 = 21:00-22:00Z = 18:00-19:00
local. h22 = 22:00-23:00Z = 19:00-20:00 local.

Rebuild the timeline in UTC:
- ext5 (.105) producer WRNs: 19:30:48, 19:31:15, 19:35:58 LOCAL = 22:30Z,
  22:31Z, 22:35Z. These are in h22 UTC.
- segcensus h21 (21:00-22:00Z = 18:00-19:00 local): 68 dead.
- segcensus h20 (20:00-21:00Z = 17:00-18:00 local): 1 dead.
- The watchdog restart at 19:36:36 local = 22:36Z ("No frames received
  from exterior_5 in 20 seconds") -- VIDEO stalled too at 22:36Z!
- h22 latest segment (22:38Z, 38.26.mp4) has audio -> after the 22:36Z
  ffmpeg restart, audio is back.

So ext5's story is NOT a silent audio freeze like ext1's class: at
22:36Z the watchdog detected NO FRAMES (video dead too), restarted
ffmpeg, and audio recovered. The 68 dead segments in h21 (18:00-19:00
local) -- the producer WRNs at 19:30-19:35 local are AFTER that. Hmm,
but the WRNs at 19:30-19:35 local (22:30-22:35Z) are in h22, and h22's
census hasn't fired yet (fires 23:05Z). The 68 dead in h21 = 18:00-19:00
local. What happened then? The watchdog restart at 18:40:45 local =
21:40Z ("No frames received") -- that's IN h21. So: ext5 video stalled
~21:40Z, watchdog restarted ffmpeg at 21:40Z, audio dead 68 segments in
that hour, recovered by 22:00Z... but h21 census says 68 dead of 239.
And the producer WRNs at 22:30-22:35Z show the producer stalled AGAIN,
then full video death at 22:36Z, restart, recovery.

REVISED ext5 story: ext5 (.105) had a video+audio stall cascade in
h21-h22 (18:00-20:00 local), with watchdog restarts at 21:40Z and
22:36Z, producer read-timeouts at 22:30-22:35Z, and recovery after the
22:36Z restart. NOT the silent-freeze class. The "ext2 freeze 19:32Z"
claim from c377 is now DOUBLY wrong: wrong camera (it was .105=ext5)
and wrong mechanism (it was a visible stall with watchdog restart, not
a silent producer freeze).

## ext2 (.102) is HEALTHY all day: producer 26 (old, stable), 0 dead
segments h17-h21, 1 backchannel configure at 03:24 local, 10 sessions.
The c377 "ext2 producer-audio frozen since 19:32Z" claim is WITHDRAWN.

## The corrected contention picture
- ext3 (.103) storm: 522 sessions today, bursts visible in
  BackchannelStreamState lines (16:14-18:25 local heavy).
- int1 (.201) WRNs on same seconds as ext3 twice (16:21:53, 16:28:39
  local) -- still stands (both are producer.go read timeouts).
- ext5 (.105) stalls at 21:40Z and 22:36Z local (18:40, 19:36) -- both
  DURING/AFTER ext3 storm activity. Contention candidate survives with
  corrected actors: ext5 and int1 stall around ext3 storm bursts.
- The go2rtc event-loop contention mechanism (c377 amendment 2) needs
  its doc amended: actors are ext5/int1, not ext2. And ext5's stall
  HEALS via watchdog (video death -> restart), unlike the silent
  audio-only freeze class.

## dBFS column: confirmed fossil (0 for all 311,604 rows all-time).

## segcensus h22 fires at 23:05Z (27 min from now) -- will confirm
ext5 recovery + ext3 continued recovery.

## Remaining open
1. ext5's h21 68-dead window: 18:00-19:00 local. The watchdog restart
   at 18:40:45 local (21:40Z) explains SOME. Producer WRNs at 19:30+
   local are h22. What made 68 segments audio-dead between 18:00-19:00
   local with no producer WRN in that window? Need per-segment dead
   minute list for ext5 h21.
2. int1 h21 129 dead: same question.
3. The go2rtc producer ids: 26 (ext2, ancient), 3433 (ext5, new). When
   was 3433 created? No log line found. go2rtc ids are internal; the
   API is the only view. 3433 > 2658 (ext3's current) suggests ext5's
   producer was recreated after ext3's -- consistent with the 22:36Z
   watchdog restart chain.

## Instrument note
The go2rtc API (/api/streams) inside the container netns via nsenter
is the AUTHORITATIVE live producer view. The producer id + medias list
shows whether a camera's producer has audio medias configured. Worth
adding to the fleet-check or segcensus as a live-state probe.