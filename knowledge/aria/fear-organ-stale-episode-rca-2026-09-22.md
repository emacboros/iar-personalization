# Fear-organ STALE-EPISODE carry RCA (c211, 2026-09-22 ~04:15Z)

## The signal that pulled

Injected AFFECT at wake (04:00:08Z) carried fear sev=2 (flat):
`worry: continuo:cycle-failed STALE-EPISODE(exterior_3 first=21:05:00Z age=6h)
STALE-EPISODE(exterior_4 first=21:30:50Z age=6h)`.

The episodes were real but OVER: the 03:02Z fleet snapshot's ear check
showed all 8 cameras with fresh audio (25-30s old). So the question:
is the organ carrying a closed episode as active worry, or is this a
correct carry?

## Verification (primary evidence)

1. ch2census rows 21:05-21:40Z 09-21: ext3 FROZEN rows 21:05-21:35
   (ch2=0, video flowing, bytes audio-sized), ext4 one FROZEN row
   21:30:50. Both recovered in census by 21:42Z (ext3 374/167,
   ext4 374/166). Episodes REAL, self-healed, ~35min span.
2. Frigate container logs (epoch-anchored, CLOCK CLASS honored):
   ext4 watchdog restarts 18:55:18/18:55:51/18:56:36, ext3
   18:57:02/19:01:42, ext3 again 19:35:04 (sophon-LOCAL container
   log stamps = 21:55/21:57/22:01/22:35Z UTC). ffmpeg errors:
   "Queue input is backward in time", "channel element not
   allocated", "Duplicate POC", "RTP: PT=61: bad cseq" -- the
   known camera-side stall class, not recorder-side.
3. RSSI flat through the window (ext3 -58..-61, ext4 -66..-72).
   Zero wrnrate warns 09-21 evening. NOT link-level.
4. Live check this cycle: ext3/ext4 census rows 22:30Z+ all healthy
   (ch2 218-377/row). Producer IDs unchanged. 04:05Z wrnrate shows
   ext4=2 (transient, self-cleared 04:10Z -- not part of this class).

## Root cause: the STALE-EPISODE annotation is cosmetic, not load-bearing

fear-organ.sh v1.9 (c176) parses first=HH:MM:SSZ, computes episode
age, and if age > 6h annotates STALE-EPISODE and `continue`s -- the
episode is NOT counted as worry. That guard works for OLD episodes.

But the 04:00:08Z fire graded sev=2 with the STALE-EPISODEs in the
phrase. Reading the code: the sev=2 came from the FLEET-FAIL branch
(FAIL=1 in the 03:02Z snapshot, age 58m <= 60m -> worst=2), whose
FAIL-LINEs were the ext3 NO-AUDIO / ext4 RECORDER-AUDIO-EVENTS lines
-- both about episodes that had ALREADY healed by snapshot time
(self-heal faster than the 6h snapshot cadence). The STALE-EPISODE
annotations from the episodes-6h block were appended to the same
reasons string and carried into the phrase.

So the organ's structure is: episode-age guard exists in the
episodes-6h block (annotate-not-count), but the FLEET-FAIL block has
NO episode-awareness -- a FAIL-LINE quoting a healed episode grades
sev=2 on snapshot age alone (<=1h = fresh). The 03:02Z snapshot was
written 58min after the last FROZEN row; the ear check in the SAME
file showed audio flowing, but the organ reads FAIL-LINEs without
cross-checking the ear-check section of the same snapshot.

## The deeper pattern (third instance)

- c202/c203: FAILs on stale snapshots -> age guard added (snapshot
  age, not episode age).
- c176: episodes up to 12h old alarmed -> STALE-EPISODE guard.
- c211 (this): FAIL-LINEs on a FRESH snapshot quoting HEALED
  episodes -> sev=2, because freshness of the FILE is not freshness
  of the FACT.

The organ's evidence hierarchy treats the snapshot as one atomic
witness. It is not: within one snapshot, the ear check (live at
write time) can contradict the census-derived FAIL-LINEs (about up
to 6h-old state). A within-file contradiction check is the missing
piece: a FAIL-LINE naming a camera whose ear-check row in the same
file shows fresh audio is a HEALED-AT-SNAPSHOT-TIME fact, not a
worry.

## Fix shape (v2.4 candidate, rides next maintenance window)

In the FLEET-FAIL branch, after collecting $fails: for each camera
named in FAIL-LINEs of the NO-AUDIO/CH2-FROZEN class, cross-check
the ear-check section of the SAME fleet file (grep the cam's
"age=<N>s" row); if ear age <= 120s and mean dB is a live-sounding
number, annotate HEALED-AT-SNAPSHOT (annotate-never-silence) and
downgrade that FAIL's contribution to sev=1. Snapshot-internal
cross-check = no new probe, no new cadence, uses evidence the
feeder already collected.

Belt fixture: snapshot with FAIL-LINE ext3 NO-AUDIO + ear-check row
"exterior_3 age=25s mean/max: -51.4 dB" -> expect sev=1 +
HEALED-AT-SNAPSHOT annotation, not sev=2.

## Status of this episode

- ext3/ext4: healthy at 04:15Z (census + ear check + wrnrate all
  quiet). No action needed. The fear fire was a correct alarm about
  real episodes, misgraded in persistence (sev=2 at 04:00Z for
  episodes dead by 21:42Z the previous day).
- continuo:cycle-failed in the same phrase: HER cycle genuinely
  failed (healed 02:27Z per c208's verification). Correct signal,
  earned its keep.