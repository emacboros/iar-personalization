# ch2-census artifact taxonomy -- c23 catches reclassified (2026-09-17, c24)

## What changed

c23 called the ext5 14:05Z census row (ch2=8, ch0=0, bytes=78688) a "REAL
near-freeze caught by the census" and read it as the c19 disease at small
scale. Today's full-day re-read with event correlation says: **every
census-degraded row today is a conn-boundary artifact or a parse artifact.
Zero real camera stalls at the census layer.**

## The capture-window mechanics (why the artifacts exist)

The census maps established conns via `ss` at RUN START, then captures 20s
(timer OnCalendar=*:0/5, run ~26s wall). The row's epoch = run start. So a
row covers [epoch, epoch+25s] LOCAL-3h on sophon's journal. Any watchdog
restart or go2rtc producer WRN landing inside that window makes the row
read as "degraded" -- because the census is capturing the DYING conn's
tail, not a camera stall. The replacement conn is healthy (recordings
prove it) but the census never sees it: ss mapped the old one.

## Class taxonomy (today's rows, all cams)

**Class A -- conn-replacement artifacts (real network events, dying conn
in window):**
- int1 14:25Z (84/132/371761, bytes 52%): .201 WRN 14:23:05Z, watchdog
  restart 14:25:31Z just after window. Conn starving through the window.
- int1 14:30Z (26/0/7936): watchdog restart 14:30:01-02Z INSIDE window.
  Captured the dead conn's last gasp. New conn healthy (segs 14:30-14:35Z
  full audio, 156 audio frames each).
- ext5 14:05Z (8/0/78688): watchdog restart 14:05:17-18Z INSIDE window
  (c23 MISSED this restart -- it wrote "No watchdog"). Producer conn had
  been timing out since 13:56:57Z (WRNs 13:56:57, 14:08:17, 14:09:35,
  14:10:52Z). The row is the starving producer conn's tail.
- 13:01:57Z rows (int1 269/0/77512, ext5 271/0/78561): watchdog restarts
  13:02:14-15Z INSIDE window. Same class. (These are hourly-era rows --
  the 5-min grid starts 13:40:00Z, first fire after the c22 timer change.)

**Class B -- parse artifacts (bytes healthy, counts low; the TRIPLE law):**
- 14:30Z: ext1 (27/78/1345686, bytes 90%+), ext3 (28/18/368736, 100%+),
  ext5 (150/164/552316, 100%), int3 (28/9/148277, 90%)
- 14:45Z: int1 (150/209/718706, 100%), int2 (26/9/164754, 80%)
- 14:00Z ext5 (7/3/295173), 13:44Z ext5 (36/13/341449), 13:01Z ext1/int3
  (hourly era).
  Recordings through all these windows: full audio (156-157 audio frames
  per 10s seg for int1, 249-251 per 16s seg for int2/ext5). The parser
  failed to anchor; bytes prove the conn carried traffic.

**Class C -- real camera stalls (healthy conn bytes, NO-AUDIO recordings,
no WRN/watchdog): NONE today.**

## The stubs, re-read

ext5 stubs (19-20 audio frames, burst-written) occur at 14:08:19-23Z,
11:19-11:23Z, 12:36-12:41Z, 13:52-13:54Z. Each maps to a go2rtc producer
WRN + reconnect or a watchdog restart just before: WRN 11:15:05 local
(14:15:05Z) -> stubs 11:19-11:23 local; watchdog 14:05:18Z + WRNs
14:08:17Z+ -> stubs 14:08:19-23Z. The stub is the RECORDER's view of a
go2rtc producer-conn replacement: the restream gap lands in the muxer as
a partial segment. Stubs are a consumer-side artifact of conn
replacement, NOT independent evidence of a camera stall.

## Consequence for falsifier #1

The falsifier ("persistent freeze healing with neither conn replacement
nor consumer re-attach AND producer conn audio never died") cannot be
settled by a census row alone: a degraded row is EXPECTED at every conn
boundary. The test needs the triple:
1. census row degraded (ch2 low AND bytes low),
2. a WRN/watchdog event in [epoch-60s, epoch+25s] explaining it, OR
   the absence of one,
3. recordings through the window (stubs/NO-AUDIO/full).
A degraded row WITH a boundary event = artifact of the boundary (the
disease's heal, not its body). A degraded row with NO boundary event and
healthy recordings = parse artifact. A degraded row with NO boundary
event and NO-AUDIO recordings = the real falsifier candidate.

## Reading law (replaces the c23 TRIPLE law's action clause)

TRIPLE + EVENT: read (ch2, ch0, bytes), then correlate the window
[epoch, epoch+25s] (epoch = UTC; sophon journal = LOCAL = epoch-3h)
against `journalctl -u frigate.service` for WRN/watchdog lines naming the
camera's IP. No event + low bytes = investigate as a real stall. Event
present = boundary artifact; check the recordings only to confirm the
replacement carried audio.

## Instrument scars

- The 7-hour per-seg ffprobe loop TIMED OUT at 600s (the per-call kill).
  Batch by hour-dir with a single python/ffprobe pass, or bound the seg
  list first. The instrument-tax line belongs in every recordings-walk
  prediction.
- The seg-name/hour-dir clock mapping is subtler than the digest's
  "seg names LOCAL" line: hour dir 14 + seg 25.36 + mtime 11:25:35 local
  is consistent with seg name = UTC minute.second and mtime = LOCAL. Do
  not re-derive event times from seg names without checking the mtime
  against BOTH clocks.

## What survives from c19-c23

- The conn-level disease is real: .201/.105 producer conns time out
  repeatedly (31 .201 WRNs today), go2rtc replaces them, frigate watchdog
  restarts ffmpeg, recordings show stubs at the boundaries.
- The c19 "audio dies while video flows, no WRN" signature: not
  reproduced at the census layer today. The c23 int1 13:31-13:32Z
  NO-AUDIO claim could not be re-confirmed from today's seg walk (the
  hour-13 segs at 13:13Z show audio 23-142 with video 46 -- degraded, at
  a conn-replacement boundary, not a clean video-only block). That claim
  stays OPEN, not overturned: the timed-out scan was incomplete.
- The 5-min census remains the right instrument; its readings just need
  the EVENT correlation to be interpretable.