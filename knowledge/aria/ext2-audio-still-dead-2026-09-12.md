# ext2 audio still dead + 0049 amendment (cycle 235, 2026-09-12 ~05:26 UTC)

## Purpose

c234 corrected c233's journald-wedge claim (TZ artifact) but the
correction lived only in my journal and roadmap. Relay 0049 still
carried the wedge claim and the moot journald-restart candidate.
This cycle: verify both 0049 claims against primary sources, amend
the record, and confirm the .105 boot (staircase 5/8).

## Findings

1. JOURNALD HEALTHY (live-verified 05:26Z): journalctl last entry
   = NOW. No wedge. 0049's restart candidate WITHDRAWN via 0050.
2. ext2 AUDIO STILL DEAD: latest segment (05:24Z,
   recordings/2026-09-12/05/exterior_2/24.15.mp4) aac nb_frames=1
   (empty) vs ext3 control nb_frames=250 (real). OLD record
   ffmpeg (pid 636056, since Sep 11 14:53L) still running. The
   restart candidate STANDS (falsifier unchanged: restart ->
   n_samples>0 = mechanism holds).
3. .105 BOOT CONFIRMED 05:00:03Z: uptime-derived (live /proc/uptime
   1557.95s at 05:26:01Z), camlog S94rc.local "Ciao" 05:00:28, RSSI
   series clean through the seam (no drop, no flap). Staircase 5/8
   on-boot confirmed (.101-.105); .201/.202/.203 expected 06/07/08Z.
4. RECORDINGS PATH CORRECTION: /var/lib/frigate/recordings does not
   exist on the sophon host. Real path (podman inspect):
   /home/nacho/containers/frigate/storage/recordings/<YYYY-MM-DD>/
   <hour>/<cam>/<seg>.mp4. c233/c234 ffprobe commands that "worked"
   ran against a path that resolved differently than I believed --
   the nb_frames=1 result itself is unchanged (re-verified at the
   real path this cycle), but the path in the record was wrong.

## Method notes

- Camera access: thingino JSON login /x/login.cgi (thingino/thingino)
  -> /x/run.cgi?cmd=<base64>. .105 crontab read directly: nightly
  reboot at 05:00 (matches the staircase hour exactly), plus my
  ntpd and rssi cron lines from 2026-09-11.
- .105 boot epoch: first rssi.log line (uptime 29742 at
  1789149600) => boot 1789119858 = Sep 11 09:44:18Z (pre-window);
  live uptime => boot 05:00:03Z today. Both consistent with the
  05:00 cron.
- .105 camlog has NO Sep 12 lines before 05:00:28 -- the puller's
  syslog sink starts at boot (the pre-boot log is the old boot's
  ring). Expected shape, not a gap.

## Relay

0050 filed (nacho-test): journald healthy, ext2 restart stands,
.105 5/8. 0049 remains open for the ext2 restart decision.