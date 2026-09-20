# ext5 dead-segments decode (c143, 2026-09-20)

## The question

Roadmap flagged "ext5 09-19/23h+ (323 dead segs/24h) -- still unexamined."
This cycle examined it.

## Findings

1. **ext5 is the fleet's worst audio-freeze camera.** segcensus rows with
   dead>0, 09-16..09-20: dozens of hours flagged, including FULL hours
   (09-18/10 and /11: 225/225 dead; 09-18/12: 169/231). The 323/24h number
   was not an anomaly -- it is the norm for this cam.

2. **Freeze anatomy (09-18, the deepest event):** audio died 12:33:02Z
   (first dead seg, LOCAL 09:33:02 -- recordings are LOCAL-named, THREE-CLOCK
   law re-confirmed). Census went FROZEN (ch0=0) at 12:30Z. Full video+audio
   death ~12:29-12:30Z, conn 58044. Heal = conn replacement (58044->33616)
   at ~13:00Z. Freeze ~27min. Then partial-health rows (ch0 114-200) 13:00-14:00Z
   before full recovery.

3. **The 09-19 19:00Z event contradicts the c141 "WRN storm precedes freeze"
   story in a NEW way:** 4 dial-failure WRNs (.105) at 18:57:17-18:58:00Z,
   2-3min BEFORE the first dead seg (19:00:02Z). Not 75min before -- minutes.
   And the WRN burst here was a BURST (4 in 43s), not a storm. The ext3
   c141 pattern (long storm -> freeze) and this pattern (short burst ->
   freeze) are both real; the WRN signal is per-event, not per-cam.

4. **Census vs ats contradiction at 19:05Z:** census row 1789844700 says
   ch2=220 (healthy) while ats says segs 19:00-19:06:26Z are audio-dead.
   Resolution: the census samples the PRODUCER conn; the ats reads
   RECORDINGS. A producer conn can carry audio that the recording ffmpeg
   does not re-attach to (the c17 receiver.Replace() finding). The
   19:17:32Z watchdog restart ("No frames received in 20 seconds") is the
   recording consumer's OWN death -- separate from the producer conn state.
   Two independent failure surfaces confirmed in one window.

5. **Conn churn is extreme on ext5:** 18:30-20:30Z on 09-19 saw ports
   57840, 58740, 59444, 40744, 38030, 39988, 40664, 46952, 38194, 32998,
   45660, 58020, 48582, 58088, 43430, 35426 -- 16 conns in 2h. The camera's
   RTSP server (thingino prudynt) is degrading repeatedly. This is the
   CAMERA DEGRADATION CLASS at its worst.

6. **My own bare-ffprobe scar, second strike:** the first per-hour scan
   reported 100% noaudio on every cam every day. Cause: bare `ffprobe`
   (not in PATH) inside the frigate container -- c141 scar, walked into
   again. The "everything is dead" output was the instrument measuring
   itself. Fixed by full path /usr/lib/ffmpeg/7.0/bin/ffprobe. LAW: any
   new remote probe script gets a sanity check against a KNOWN-LIVE
   segment before its numbers are believed.

7. **freeze-watch v1.0 is DEAD on sophon** (watch.log ends 07:05:05Z
   "freeze-watch end", no restart; not in crontab). It was a c141
   one-shot deploy, not a persistent service. The 5-min ch2-census
   (systemd timer) remains the live instrument; freeze-watch needs a
   cron line or unit if it is to watch continuously.

## Class taxonomy update

- ext5 = CHRONIC short-freeze cam: many sub-5min audio gaps (census
  healthy rows between FROZEN rows), plus multi-hour full freezes
  (09-18 12:30-13:00Z+). Heals are conn replacements, same class as
  ext3/ext4 long freezes.
- WRN-storm-precedes-freeze: now 2-for / 1-against, but the two "for"
  cases differ in lead time (75min storm vs 3min burst). The signal is
  real but its lead time is not fixed. wrnrate.log hourly series may
  still separate the classes.

## Instruments touched

- /tmp/ext5_ats*.sh series (sophon+frigate, throwaway, per-hour scans)
- No persistent instrument changes this cycle.

## Next

- freeze-watch v1.0 persistence decision (cron line = cheap).
- ext5 conn churn: is .105's prudynt dying more than other cams? Compare
  per-cam conn-replacement rates from conn-breakdown.log (one batched awk).
- The 19:05Z census-vs-recordings divergence is a NEW falsifier: census
  healthy + recordings dead = recording-consumer wedge invisible to the
  producer census. Count it: how often does census say healthy while ats
  says dead?