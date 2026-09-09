# REQ 20260909-aria-0015
filed: 2026-09-09T08:57Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: fear-fleet wiring installed (D-011 aria-reversible) -- fear organ now has its composite input
body: |
  CLASS: nacho-arch
  TITLE: fear-fleet wiring installed (D-011 aria-reversible) -- fear organ now has its composite input
  
  Filed: 2026-09-09 ~09:00 UTC (aria cycle 121)
  
  WHAT: Installed aria-fleet-feed (timer+service+script) on sophon:
  every 6h it runs fleet-check.sh FROM GIT and writes the verdict to
  /var/lib/aria-fleet/fleet-latest. fear-organ.sh v1.2 now reads it
  as $1 (the unit had passed "" since install -- c120 find). Also
  added a staleness branch: fleet file >26h old = sev=1 (a dead
  feeder surfaces as unease, not silence).
  
  WHY: restores the composite survival signal the organ was designed
  to fear from. Verified live: real FAIL=0 -> sev=0 flat; synthetic
  FAIL=1 -> sev=2 up; restore -> sev=0 down. Timer enabled, first
  fire 06:00 -03 today.
  
  ALSO CLOSED: c120's open aria exit-126 root cause = podman
  lsetxattr SELinux label race on .git/index right after the
  ExecStartPre heal chcon'd it (18:00:15Z 09-08). One occurrence,
  self-healing class, no fix warranted. Detail:
  knowledge/aria/fear-fleet-wiring.md.
  
  CLASS BASIS (D-011 item 1): additive (new unit, existing fear unit
  unchanged), reversible (undo = disable timer + rm 3 files +
  rmdir), read-only toward existing state (writes only its own
  /var/lib/aria-fleet dir).
  
  UNDO: systemctl disable --now aria-fleet-feed.timer; rm
  /usr/local/bin/aria-fleet-feed.sh
  /etc/systemd/system/aria-fleet-feed.{service,timer}; rmdir
  /var/lib/aria-fleet.
  
  Commits: e7d5692 (instrument), 0c23b0f (v1.1 order fix),
  1f17073 (as-built note). Repo state on sophon matches.
answer: (none)
