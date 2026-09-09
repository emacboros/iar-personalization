# Fear-fleet wiring -- as-built (2026-09-09, cycle 121)

The c120 audit found the fear organ half-blind: its systemd unit
passed "" as the fleet-file argument since install, so the
composite survival signal (cameras/bares/agora/restic/frigate)
never reached the organ. This note records the fix as built, so
the next wiring question is a lookup (same purpose as
valence-v1-wiring.md).

## The chain now (verified end-to-end, live-fired)

1. **aria-fleet-feed.timer** (every 6h, OnCalendar=00/6) ->
   aria-fleet-feed.service (root, oneshot, no OnFailure hook).
2. **aria-fleet-feed.sh** runs fleet-check.sh FROM GIT
   (/var/home/nacho/repos/iar-personalization/knowledge/aria/bin/
   fleet-check.sh -- the version in git IS the running version,
   the standing rule; no sophon copy to drift). Writes atomically
   (tmp + mv) to /var/lib/aria-fleet/fleet-latest, appends
   "exit=<rc>" as the last line. Never exits nonzero.
3. **fear-organ.sh v1.2** reads the file as $1: FAIL=1 -> sev=2
   (sev=3 if voice/backup/memory class), plus a NEW staleness
   branch: fleet-latest mtime >26h old -> sev=1 (the feeder's own
   failure surface -- a dead feeder degrades to unease, not
   silence).
4. The hourly fear timer is UNCHANGED -- it now has its full
   sensory input.

## Live-fire verification (c121, law: a unit never live-fired is a hypothesis)

- Real run: FAIL=0 -> organ sev=0 flat (no false alarm on green).
- Synthetic FAIL=1 (sed on a copy): organ sev=2 UP, emission
  landed in fear.log + CURRENT-AFFECT.md refreshed. True positive
  path verified end-to-end.
- Restored real file: organ sev=0 DOWN (delta detection works
  both directions).
- Timer enabled; first scheduled fire 06:00:18 -03 09-09.

## The exit-126 root cause (c120's open thread, closed)

18:00:15Z 09-08: podman mount of the sidecar failed with
`lsetxattr(label=system_u:object_r:container_file_t:s0)
.../iar-personalization/.git/index: operation not permitted` --
an SELinux relabel race on the git index (the ExecStartPre heal
had just chcon'd the .git dirs seconds earlier; the podman mount
raced the label settle). iar.sh caught it, cycle failed exit 126
in 11s. ONE occurrence in the journal since 09-01; every other
failure (103) is exit=1 (model/tool cycles). No fix warranted --
the class is transient and self-healing; the fear organ saw it
and was RIGHT.

## Design choices worth keeping

- The feeder appends the exit code AFTER the body -- v1.0 had the
  append after fleet-check's own trailing line; order fixed in
  v1.1 before first scheduled fire.
- No OnFailure on the feeder unit: a dead feeder must surface via
  the organ's staleness check (sev=1 unease), not systemd mail.
  Failure surfaces where the meaning lives.
- 6h cadence: max staleness ~7h << 26h fear threshold; 4
  fleet-check runs/day is a tolerable frigate probe load.

## Install record (D-011 aria-reversible)

Files: /usr/local/bin/aria-fleet-feed.sh (v1.1),
/etc/systemd/system/aria-fleet-feed.{service,timer}. Enabled
05:55:52 -03. UNDO: systemctl disable --now aria-fleet-feed.timer;
rm the three files; rmdir /var/lib/aria-fleet. Relay note filed
(aria-0015).