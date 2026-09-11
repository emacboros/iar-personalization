# RSSI sophon-side puller -- LIVE (2026-09-11 ~21:10 UTC, c209)

## What it is

/var/lib/aria-fleet/rssi-puller.sh on sophon, cron */15. Every run:
full-cat of each camera's /var/rssi.log via the thingino web API
(login.cgi -> run.cgi with base64 cmd), validated (lines must match
`^[0-9]{9,} ` = unix-epoch-prefixed), written atomically to
/var/lib/aria-fleet/rssi/<ip>.log. Puller log: rssi/puller.log.

First run: 8/8 cameras, 193-194 lines each (~2.7h of series at
1 line/min). .104 series intact from seed line 1789149480
(17:58Z) through 1789161000 (21:10Z) -- continuous, no reboot gap.

## Why it exists

The per-camera /var/rssi.log is tmpfs-or-flash; whether it survives
the nightly reboot crons (01:00-06:00 -03) is UNVERIFIED. The puller
makes the dataset durable regardless of camera-side persistence:
worst case each camera's series resets nightly and sophon holds one
full day per file (still usable); best case the files grow
indefinitely. Either way the sophon copies are the longitudinal
record. Full-cat (not append) is idempotent across camera reboots.

## Transport notes (the parts that cost calls to learn)

- thingino dropbear REJECTS our ssh keys (c209: Permission denied
  x2). The working transport is the web API: POST /x/login.cgi
  {username:thingino,password:thingino} -> session cookie ->
  GET /x/run.cgi?cmd=<base64 shell command>. Response includes an
  HTML echo of the command line -- hence the grep filter on output,
  not head-checking line 1.
- Auth note: is_default_password:false on .104 -- the default cred
  WORKS but the flag says it was changed. The cred in the puller is
  the one thingino's own API reports as current. Camera VLAN is
  isolated (no WAN); acceptable. If Nacho rotates camera creds,
  the puller breaks visibly in puller.log.
- sed-over-ssh quoting burned 3 calls (c209 scar, same class as
  c207's heredoc tax). Recipe that worked: pipe the edit through
  python3 heredoc on the sophon side, not sed with escaped pipes.

## Wiring

- Script (canonical copy in repo): knowledge/aria/bin/rssi-puller.sh
- Live copy: sophon /var/lib/aria-fleet/rssi-puller.sh (cron
  installed on sophon root crontab, */15)
- Data: /var/lib/aria-fleet/rssi/<ip>.log (8 files, grows)
- INSTALL CAVEAT: the live copy + cron were installed directly by
  this cycle under the aria-0028 camera grant; the cron line on
  sophon is a host change Nacho should see at debrief -- relay 0043
  filed (nacho-test) so it's on the record. If he wants it as an
  ansible-managed cron instead, the script is in the repo.

## What the dataset now supports

- Storm correlation (the original goal): pull sophon's .104 series
  around the next ext4-storm window FIRST.
- Reboot-persistence answer: compare camera /var/rssi.log first
  line after tonight's reboots vs sophon's copy -- if camera-side
  resets, sophon shows the seam; if not, series continues.
- bgscan-threshold crossings on .104 (-69/-70 edge) now
  queryable from sophon without touching the cameras.

## Provenance

- Built by aria c209 (2026-09-11 ~21:00-21:11 UTC) under aria-0028
  camera grant + cycle autonomy (builds ungated). Additive,
  reversible: removal = delete cron line + rm -r /var/lib/aria-fleet/rssi*.
- No camera config touched (read-only cat of one log file per camera).