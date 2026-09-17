# int1 recorder-audio deaths -- mechanism resolved (c19, 2026-09-17)

## What c18 left open

c18 found interior_1 (.201) recorder segments audio-dead since ~03:08
local while the producer connection intermittently carried ch2, and
called it a possible RECORDER-side disease distinct from ext1's
producer-side freeze. It also flagged an ear-check vs segcensus
discrepancy (mean -39.8 dB vs 0 samples). This cycle resolved both.

## The ear-check discrepancy: NO BUG

- ear-check (fleet-check) reads the NEWEST segment (live window).
- segcensus reads the PREVIOUS COMPLETE UTC hour (dead block).
- At 09:04Z the newest int1 segment was from the alive window
  (08:47-09:0x local); segcensus hour-10 was the dead block. Both
  instruments were correct about their own windows. Two windows, not
  two answers.

## The int1 death blocks (all times LOCAL, -03; seg names are local)

| block | length | heal event |
|---|---|---|
| 21:03-21:12 (09-16) | 9 min | go2rtc reconnect 21:12:29 |
| 02:08-02:18 | 10 min | go2rtc reconnect 02:18:47 |
| 04:17-04:25 | 8 min | go2rtc reconnect 04:25:51 |
| 07:33-07:35 | 2 min | go2rtc reconnect 07:35:38 |
| 08:03-08:26 | 23 min | go2rtc reconnect 08:26:28 |
| 08:39-08:46 | 7 min | go2rtc reconnect 08:46:44 + ffmpeg restart 08:47:14 |

All six heals coincide with go2rtc read-timeout reconnects (producer
replacement). The 08:03-08:46 "43-minute block" of c18 was actually
TWO blocks separated by a 13-minute alive window (08:26-08:39) -- the
per-minute mtime histogram split it.

## The unified mechanism (one disease, two heal paths)

DISEASE (all cams, ext1/ext2/int1/int2/ext3 confirmed): prudynt on the
camera silently stops sending audio RTP on the ESTABLISHED RTSP
connection. Video keeps flowing, TCP stays healthy, go2rtc's video read
never blocks, so go2rtc never times the conn out. The recorder ffmpeg
keeps writing video-only segments. No log trace anywhere. Audio-only,
silent, invisible to age checks and to SDP reads (SDP still says
audio-yes -- SDP-ADVERTISED != PACKETS-FLOWING, law 50 member).

HEAL PATH A (go2rtc reconnect): a subsequent FULL-stream stall blocks
the video read => read-timeout => go2rtc replaces the producer => the
fresh conn carries audio => recorder audio resumes. Latency = time
until the next full stall. int1 (.201) full-stalls ~59x/day (go2rtc
timeout count) => freezes last minutes. ext1 (.101) full-stalls
rarely (11 in the log window) => the 09-17 freeze lasted 5h22m
(01:55-07:17 local), healed at the 07:17:04 reconnect.

HEAL PATH B (consumer restart): the frigate watchdog restarts the
detect+record ffmpeg (ONE process, two outputs) => fresh consumer
conn => audio resumes. The 08:47:14 restart landed 30s after the
08:46:44 reconnect -- both heals coincided.

## Why ext1 froze 9.5h and int1 heals in minutes

Not two diseases. One disease, different stall cadences:
- ext1's audio-only drop never triggered a reconnect (video flowing =>
  no read timeout) and no watchdog restart happened (video flowing =>
  "No frames" never fired) => 9.5h freeze.
- int1's camera full-stalls constantly => reconnects and restarts are
  frequent => freezes last 2-23 minutes.

## Falsifier status

- The 12:05Z segcensus hour-11 row for int1 should read ~284 total /
  ~180 dead => STALE-MAJ flag expected (v1.2 cross-reference).
- Tonight's 01:02Z ext1 reboot is now a RECURRENCE watch, not a heal
  test (ext1 already healed at 10:17Z).
- If a freeze heals WITHOUT a go2rtc reconnect and WITHOUT an ffmpeg
  restart, the mechanism is wrong.

## Still open (camera-side root cause)

WHY prudynt drops the audio track silently. Needs pcap at the camera
or prudynt logs -- rides 0062 (ONVIF sweep, physical visit) per
0073+0063 (observation-only ruling).

## Instrument notes

- frigate container logs and seg names are LOCAL (-03); podman logs
  --since takes UTC. The three-clock law (digest) bit again: I nearly
  mis-mapped the 08:47 heal to 11:47Z before re-deriving from the
  container's own date output.
- go2rtc /api/log is the reconnect witness; producers.log id changes
  are the replacement witness; segcensus is the delivery witness.
  Three instruments, one story, all consistent.