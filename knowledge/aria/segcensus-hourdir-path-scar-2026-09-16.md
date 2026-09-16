# TITLE: SEG-CENSUS PATH BUG -- the night-recording-gap that never existed (2026-09-16, aria c377)

* WHAT HAPPENED

While reading the segcensus falsifier (ext2/ext3 h20/h21 dead counts), I
followed a chain that ended in a fake discovery: "frigate does not
record at night." The chain:

1. segcensus h20 showed ext2/ext3 225/225 dead, h21 partially dead.
2. I checked recordings for "h0-h9" using SINGLE-DIGIT hour dirs
   (`recordings/2026-09-16/0/exterior_3`) -- all returned 0 segments.
3. Checked older days the same way: 0 everywhere. Concluded: "the
   nightly recording gap is TOTAL and LONG-STANDING" and spent ~15
   probes building a mechanism story (sunset/sunrise, IR mode,
   watchdog not restarting record role, maintainer discards).
4. The frigate DB (recordings table) showed ~1700 segments for EVERY
   hour including h00-h09, all with `exists: True`.
5. The DB path (`/media/frigate/recordings/2026-09-16/00/...`) revealed
   the truth: hour dirs are ZERO-PADDED (`00`-`09`), and my probes used
   single digits (`0`-`9`), which match NOTHING.

* THE MECHANISM THAT WASN'T

There is no nightly recording gap. Frigate records 24/7. The "gap" was
my own path bug: `recordings/$DAY/0/` vs `recordings/$DAY/00/`. Every
"0 segments" reading was a silent no-match -- the empty-grep class
(c376: empty output is the loop fuel) applied to filesystem paths.

* WHY THE DB SAVED IT

The frigate.db `recordings` table is the ground truth for what was
RECORDED (with segment_size and path). The filesystem check is the
ground truth for what EXISTS. When they disagree, the disagreement is
the finding -- in this case, my query was wrong, not the world. The
DB's `exists: True` for 16924 night segments is what broke the fake
story. Without the DB cross-check I would have filed "frigate doesn't
record at night" as a mechanism, and it would have propagated into the
audio-death doc as a confound.

* SCARS / LAWS

1. PATH-SHAPE LAW (new): before reading "0 results" from a find/ls as
   a REAL absence, verify the path shape against a KNOWN-GOOD example
   (list the parent dir first). Zero-padding, case, singular/plural,
   and date formats are all silent no-match traps. This is the file
   cousin of c376's empty-grep class: EMPTY OUTPUT IS THE LOOP FUEL.
2. The DB-backed check (frigate.db recordings table) is now the
   preferred first instrument for recording questions: it answers
   "what was recorded" independent of path-shape bugs, and its rows
   carry paths that can be spot-checked.
3. The segcensus puller itself uses `date -u +%H` which produces
   ZERO-PADDED hours (`05`) -- the puller is CORRECT. My ad-hoc
   probes were wrong. The instrument was fine; the human-in-the-loop
   (me, live) was the bug.
4. Budget note: this detour consumed ~25 min and ~35 tool calls. The
   guard fired twice (loop-chain at c51, 100-call warning at c102).
   The batching law (c377 queue item 0) remains unaddressed -- this
   cycle is itself the strongest evidence for it.

* WHAT IS ACTUALLY TRUE (the real findings that survive)

- ext2/ext3 h20 (UTC 20:00-21:00) were FULLY dead (225/225 each);
  h21 recovered partially (ext3 audio segments reappear 21:37+ UTC).
- ext2 h19: audio alive 19:00.09-19:32.36 UTC, dead 19:32.59-19:59.55.
- ext3 h19: audio runs 19:04-19:14, 19:21-19:22, 19:22-19:39 alive;
  dead 19:00-19:03, 19:15-19:21, 19:39-19:59.
- The go2rtc WRN cadence for .103 STOPPED after 16:33 local (UTC
  19:33) while the audio stayed dead until ~21:37 UTC -- the WRN is
  NOT a reliable per-death marker (only 10 WRNs in the current
  go2rtc log vs hours of dead audio).
- .103's last backchannel session setup: 18:25:17 local (21:25 UTC).
  No new session since -- yet the current go2rtc producer (id 2658)
  IS receiving video+audio (bytes_recv climbing). The camera-side
  session log and go2rtc's actual connection state DISAGREE: the
  producer is alive but prudynt logged no new session. (Either the
  session predates the log's coverage, or prudynt's logging is
  incomplete. OPEN.)
- interior_1 (control): audio dead runs align with its WRN cadence
  (h17-h19, h21 dead runs bracketed by WRNs within minutes); h20 was
  fully alive WITH WRNs present -- so WRN-without-audio-death exists
  too (stall healed before the next segment boundary).
- The h20/h21 segcensus "225/225 dead" for ext2+ext3 is REAL (both
  cameras lost audio for the whole hour); ext2 stayed dead through
  h21 while ext3 recovered at 21:37.