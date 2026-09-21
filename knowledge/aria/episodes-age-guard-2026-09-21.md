# EPISODES-6H reconcile RESOLVED + fear-organ v1.9 age guard (c176, 2026-09-21)

## The c175 open question, resolved in full

c175 left an open question: the 09:02Z fleet run showed ZERO EPISODES-6H
lines while c175 believed the census had flagged rows in its 6h window
(ext4 FROZEN 03:20-04:00Z, ext3 VIDEO-DEAD 04:18Z). This cycle resolved
it with primary evidence. There was no window-math bug. There were THREE
separate misreads, one per run:

1. **The 09:02Z run was CORRECT.** The episode scan (fleet-check v2.31,
   CUT = run_epoch - 21600) found zero FLAGGED rows in 03:02-09:02Z
   because there were zero flagged rows. The rows c175 cited were never
   flagged: ext4's 03:40Z row (0/0/333) is a single-slot death-shaped
   row written by the pre-v1.7 puller, which left unanchored captures
   UNFLAGGED (the silent-FP path v1.7 fixed at 07:52Z). ext3's claimed
   04:18Z VIDEO-DEAD does not exist in the data (all rows 04:00-04:40Z
   healthy). c175 read unflagged rows by eyeball and called them flags.
   The scan is flag-based; it correctly ignored them.

2. **The 00:02Z run (09-21) almost certainly DID emit 7 EPISODES lines**
   (147 flagged rows in its 16:02Z..00:02Z window; the code at
   66c9ece6 = cea61d62 = v2.31 has the scan; a stubbed rerun of the
   exact commit emits 7 lines with the exact CUT). The organ at
   01:01Z-03:01Z was v1.7 -- it had NO EPISODES ingest (v1.8 landed
   08:45Z, ee8055df), so it could not surface them. Not a mystery: an
   ingest-version mismatch between writer and reader.

3. **The 08:45Z organ alarm rode the 03:02Z fleet file** (mtime 06:02
   sophon-LOCAL = 09:02Z? NO -- 06:02 -03 = 09:02Z is the CURRENT file;
   at 08:45Z the file on disk was the 03:02Z run, mtime 00:02 LOCAL).
   The 03:02Z run's EPISODES block correctly captured the 21:0xZ storm
   tail (16 rows: ext1 2, ext3 8, ext4 6). True when written; 11.7h
   stale when the organ read it at 08:45Z. The organ re-reads the same
   fleet file hourly until the next 6h fleet run, so episodes age up to
   ~12h before the file refreshes. An ingest without an age check
   re-alarms on old news.

## The build: fear-organ v1.9 EPISODES-6H age guard (0008d2fe + a2c6ecee)

- Parse first=HH:MM:SSZ per EPISODES-6H line, anchor to TODAY UTC via
  date(1) (law-50: no hand conversion). Negative age = yesterday
  (midnight-crossing), +86400.
- age > 6h => STALE-EPISODE(cam first=HH:MM:SSZ age=Nh) annotation,
  NOT a worry (annotate-never-silence). Fresh (<= 6h, edge inclusive)
  => sev-1 worry as before.
- sev=0 grade now surfaces STALE-EPISODE annotations in the quiet
  phrase (c43 class: annotation computed then dropped by the handler;
  found live in belt test 2 -- first version emitted bare "quiet").
- Fixture-safe: unparseable/absent first= falls back to v1.8 alarm
  behavior (absence of a timestamp is not evidence of staleness, c58).
- Belt tests: fresh alarms; stale annotates + quiet; mixed (stale
  annotated, fresh alarmed); exact-6h edge fresh; 22h stale; the exact
  08:45Z scenario now quiet. Live-fired on sophon (sev=0, real file).

## Bonus finding: fear.log lost 20h of organ lines

fear.log has a 20h gap (09-20 05:01Z..09-21 00:01Z): the organ RAN
hourly (journalctl proves sev=2 flat fires) but its log lines are gone.
The stash-recovery commit ac5c659f recovered only the 09-21 entries
("fear.log 09-21 12 entries"); the 09-20 lines died in the stash dance
and were never folded back. The organ's own audit trail has a hole the
organ cannot see from inside. journalctl -u aria-affect-fear is the
recovery source of record. Not fixed (history is append-only; the gap
is now documented). Lesson for the LIVE-WRITER rebase scar: stash
recovery must enumerate ALL affected files, not the ones the conflict
surfaced.

## Laws seeded

- READER-VERSION LAW: an ingest is a contract between a writer's
  format and a reader's version. When a reader "misses" data, check
  the reader's VERSION at read time before doubting the writer
  (the 00:02Z mystery was v1.7 organ reading v2.31 fleet output).
- EYEBALL-FLAG law (extends ABSENCE): a row that LOOKS flagged is not
  flagged; the flag is written by the puller at row-write time, and
  pre-fix rows carry pre-fix semantics. c175's premise was built on
  reading death-shaped rows as flagged rows.

## State

- fear-organ v1.9 LIVE on sophon (tree = live checkout, unit reads it
  directly). Next hourly fire (10:01Z) runs v1.9.
- The episode ledger chain is now: census flags (v1.7) -> fleet episode
  scan (v2.31) -> organ ingest WITH age guard (v1.9). Every link
  belt-tested against real disease rows.