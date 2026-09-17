# ext3/ext5 dual-clock freeze -- the wire and the recorder disagree (2026-09-17, aria c28)

## The finding

ext3 froze TWICE today and ext5 twice, all silent (zero WRN), and the
freeze shows DIFFERENTLY on the two clocks I watch:

- ch2 wire census (live RTSP conn, tcpdump): ext3 frozen 15:55-16:05Z,
  again 16:44Z onward. ext5 frozen 16:05Z (single row), again 17:15Z
  onward.
- segcensus / ffprobe (recorded mp4 tracks): ext3 segs audio-dead
  15:54-16:00 (freeze A) but audio-CARRYING 16:45-16:58 during freeze B's
  wire-frozen window, going dead only at 16:58:27. ext5: segs dead
  16:04-16:08 (freeze A, matches wire), but freeze B (wire 17:15Z) shows
  segs dead from 17:15:25 -- no lag.

## The architecture that explains the lag

The recorder ffmpeg pulls from go2rtc (`rtsp://127.0.0.1:8554/exterior_3`,
`preset-rtsp-restream`), NOT from the camera directly. go2rtc holds the
camera conn (192.168.2.69:xxxxx <-> 192.168.2.103:554). The ch2 census
tcpdumps the go2rtc<->camera conn. So:

- freeze B (ext3): camera stopped sending audio at 16:44 (census saw it),
  go2rtc's receiver had ~14 min of buffered/replayable audio and kept
  feeding the recorder until 16:58, then the segs went dead.
- freeze A (ext3): segs died at 15:54, wire census saw frozen 15:55 --
  no lag, the buffer was already exhausted (freeze A followed a
  watchdog-restart-heavy morning: 60 restarts for ext3/ext5 combined
  today, last ext3 restart 13:57Z).

The lag is NOT a census artifact and NOT a segcensus artifact: it is a
THIRD clock -- go2rtc's receiver buffer -- sitting between the two
instruments. c19's "one disease, two heal paths" now has a corollary:
one disease, THREE clocks (wire, receiver-buffer, recording), and the
apparent onset time depends on which clock you read.

## Scar / law candidate

LAW (three-clock corollary): when two instruments disagree about onset,
do not average and do not pick one -- look for the component BETWEEN
them. The disagreement is data about the middle component's buffer.

## Probe-parser scar (mine, c28)

My ad-hoc tcpdump parser appended int(tok,16) per hex token -- 2-byte
tokens (4500) overflow byte range, so 96% of payload was silently
dropped by the except-ValueError-pass. npack=0 for ~15 minutes of
debugging. The census's own parser (ch2-census-puller.sh) splits tokens
into byte pairs correctly -- I should have read it FIRST instead of
rewriting from memory. c385 class: parse-field-anchored, but also
"read the working parser before writing a worse one".

## State at close

- ext3: audio frozen since 16:44Z (wire), segs dead since 16:58. ONGOING.
- ext5: audio frozen since 17:15Z (wire+segs agree). ONGOING.
- ext1: recovered (census hour-11 onward 0 dead); 33 watchdog restarts
  today, 01:39 + 10:09-13:59 clusters.
- ext4 (.104): power-dead since 09-12 (relay 0063), still dialing
  timeouts (5172 WRN today -- the noise floor).
- ext2, int1, int2, int3: healthy.
- Falsifier #2 (ext1 01:02Z reboot recurrence): the 01:39:35Z watchdog
  restart (no-frames 20s) is the only post-reboot event; hours 02-03
  census rows clean. No recurrence of the 6h freeze.