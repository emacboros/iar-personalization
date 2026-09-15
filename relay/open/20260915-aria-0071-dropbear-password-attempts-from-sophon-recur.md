# REQ 20260915-aria-0071
filed: 2026-09-15T03:30Z
filer: aria
class: nacho-security
state: open
urgent: no
title: dropbear password attempts from sophon to cameras -- RECURRENCE (4 bursts, 3 cameras, source still unidentified)
body: |
  RECURRENCE of c283's open watch (tasks/iar/aria/sink-watch). The
  c283 watch said: "if recurrence, capture timestamps + target
  cameras, file relay nacho-security with multi-sample data."

  CENSUS (current cameras.log rotation, all from 192.168.2.69 = sophon):
  - Sep 13 03:39:48-49Z  .103  2 attempts, port 49610
  - Sep 14 20:20:30-31Z  .201  2 attempts, port 44548
  - Sep 14 23:41:48Z     .102  1 attempt,  port 50688
  - Sep 15 00:10:07-08Z  .201  3 attempts, port 55714
  6 failed 'root' password attempts total, 4 bursts over ~45h,
  3 distinct cameras, no success (all "Exit before auth").

  WHAT I RULED OUT:
  - BatchMode key-only ssh (my pullers are HTTP login.cgi, not ssh).
  - fleet-check / dashboard / rssi+camlog pullers: no ssh to cameras.
  - sophon root's key does NOT auth to cameras (live-tested .103:
    Permission denied publickey,password).
  - sshpass IS installed on sophon but no script references it.
  - auditd covers the bursts' windows only from 23:55Z 09-14 (retention
    gap); the 3 earlier bursts are unaudited. The 58 audit-visible ssh
    execs (23:55Z+) are uid 1000/1002 interactive/git traffic, none at
    burst times.

  PATTERN: 1-3 attempts per burst, spread out, different cameras --
  looks like a script with a WRONG password (thingino default root
  password on dropbear?) retrying occasionally, or a human typo
  pattern. Not a brute force (no escalation).

  ACTION TAKEN: dropbear-burst-watcher v1 armed on sophon /tmp
  (26h, tails cameras.log, on trigger snapshots ps/ss/conntrack/
  audit tail -> /tmp/dropbear-snapshot-<ts>.txt). Next burst names
  the process.

  DECISION NEEDED (yours): if the watcher catches a legit process
  (e.g. something you run), no action. If the source stays
  unidentified or looks foreign, next step is a firewall rule on
  sophon (block outbound :22 to the camera subnet) -- your call,
  your host. The cameras' root password is also worth rotating if
  it's still a default.
answer: (none)
