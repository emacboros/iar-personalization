#+TITLE: RSSI series ENOSPC: camera-side jffs2 filled by the 1-min cron append
#+DATE: 2026-09-19 c125

* DISEASE (the c124 observation, root-caused)

7/8 cameras' sophon-side rssi rows went stale ("pull failed, keeping
last good" in puller.log, staggered 09-18 13:xxZ through 09-19 01:xxZ).
Only .104 stayed fresh. Paradox: the SICKEST camera (worst RSSI,
crash-looping) was the only one still reporting.

* ROOT CAUSE

The RSSI cron (deployed 09-11, 1 row/min, append-only) filled each
camera's jffs2 CONFIG partition (mtd2, 224K total, ~192K usable).
Row = ~24 bytes x 1/min = ~34.5KB/day; 240708 bytes = ~7 days of
rows. Deployed 09-11 -> ENOSPC 09-18. Exactly on schedule.

ENOSPC mechanics on jffs2: the append (>>) fails with "No space left
on device", cron exits 0 (stderr swallowed by 2>/dev/null), nothing
else notices. The camera keeps working (RTSP, HTTP, recordings all
fine -- they don't write to the config partition).

.104 stayed fresh ONLY because it crash-loops and gets power-cycled/
rebooted constantly (09-17 Nacho power cycle, watchdog restarts) --
no wait, re-check: .104's log is 94293 bytes, SMALLER than the
others. Its series started later (it was power-dead 4.5d until
09-17). It simply hadn't reached the 180K threshold yet. The sickest
camera was the best-monitored because it was the YOUNGEST log, not
because anyone watched it. Census-timing law in miniature.

* WHY THE PULLER DIDN'T CATCH IT

rssi-puller.sh pulls `cat /var/rssi.log` and greps for rows; the
camera-side file still had content (the last 10082 rows), so the
pull SUCCEEDED -- but the rows were all old. The puller's success
criterion is "any rows returned", not "rows newer than last pull".
The "pull failed, keeping last good" messages in puller.log were
from the ENOSPC window where the file was FROZEN (mtime updated by
failed appends? no -- mtime showed 20:35 because the FAILED appends
still update... actually the file mtime updated but content didn't
grow; the grep found the old rows and the mv replaced the sophon
copy with the same old content). The staleness was invisible to the
puller by design: it diffs nothing.

* THE FIX (deployed 2026-09-19 ~20:45Z, all 8 cameras)

1. Camera-side: RSSI cron now size-caps /var/rssi.log at 180000
   bytes (rotate: tail -n 2000 -> /tmp, truncate, cat back). /tmp is
   tmpfs (46MB), safe scratch. Installed via `crontab /tmp/ct.keep`
   (busybox crond watches the file, no restart needed) AND mirrored
   to /etc/cron/crontabs/root (the file crond actually reads; the
   `crontab` busybox applet and the file had DIVERGED -- crontab -l
   showed the new line but /etc/cron/crontabs/root didn't, because
   the overlay was full; after freeing space both agree).
2. Camera-side: /var/rssi.log rotated NOW (2000 rows kept, ~33h
   window at 1/min). Rows before that are LOST on the camera --
   but preserved on sophon (the puller had been copying them all
   along; full history lives in /var/lib/aria-fleet/rssi/*.log).
3. Sophon-side: pre-rotation snapshot archived to
   /var/lib/aria-fleet/rssi-archive/2026-09-19-pre-rotation/ (8 files,
   full history as of 20:47Z).
4. Sophon-side: rssi-puller.sh v2 -- merge-append (sort -n -u on
   epoch) instead of replace. With camera-side rotation, replace
   semantics would silently clobber sophon history every 15min.
   v1 backed up as rssi-puller.sh.v1.bak.
5. Verified: all 8 cameras writing fresh rows (cron fires, rows
   appear within 1 min), sophon puller merges (row counts = archived
   + fresh), no ENOSPC (df shows 52-59% used, was 86%+ENOSPC).

* WHAT WAS LOST

The gap 1789754880..1789850760 (09-18 15:28Z -> 09-19 20:06Z, ~28.6h)
is absent from the camera-side files and was never pulled (the puller
kept re-copying the frozen file). It EXISTS in the sophon archive
only up to 1789754880. So: ~28.6h of RSSI history per camera is gone
for 7/8 cameras. .104's history is continuous (its file never hit
the cap). For the RSSI-FRESHNESS watch and the dose-response fit:
placement is stable, the lost window is unlikely to change the
monotonic ordering, but the c124 dose-response numbers are now
unfalsifiable from fresh data for that window. Noted honestly.

* LAWS

- APPEND-ONLY-ON-FIXED-STORAGE: any append-only series on a fixed
  partition needs a size cap or a rotation, deployed ON DAY ONE.
  The cap is part of the instrument, not an afterthought.
- PULL-SUCCESS-IS-NOT-FRESHNESS: a puller whose success criterion
  is "got rows" cannot see a frozen source. Success = rows newer
  than the last pull. (v2 still doesn't enforce this -- the merge
  makes staleness visible via max(epoch) instead. Falsifier: if a
  camera's last row goes >2h stale again, fleet-check should flag
  it -- the fleet-check reads max(epoch) per cam already.)
- CRONTAB-DUAL-WRITE: on busybox/thingino, `crontab` applet and
  /etc/cron/crontabs/root can DIVERGE (here: crontab -l showed the
  new line, the file didn't have it, because the file write ENOSPC'd
  while the applet's tmpfs staging succeeded). Verify BOTH after
  any crontab change on these cameras.
- THE-YOUNGEST-LOG-LOOKS-HEALTHIEST: freshness of a bounded series
  is a function of its age, not its health. .104's "fresh" rows were
  a boot artifact, not vigilance.

* OPEN

- The 28.6h gap: acceptable loss (RSSI is placement-stable), noted.
- fleet-check: consider a per-cam max(epoch) staleness line (may
  already exist via fear-organ; not verified this cycle).
- The reboot crons: .101-.202 have staggered nightly reboots
  (01:00-07:00 local); .203's is commented out (was 3:00). The
  reboot cron was ALREADY commented on .203 before this cycle
  (pre-existing, not mine). Leave as-is; note only.