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

## AMENDMENT c350 (2026-09-15 ~03:50Z): census extended + correlation found

Two more bursts since filing (cameras.log, UTC):
- Sep 15 00:18:18Z  .103  0 attempts (KEY PROBE ONLY: "Child connection
  ... Exit before auth, 0 fails") port 40870
- Sep 15 03:18:18Z  .103  0 attempts (key probe), port 40870? (dedup:
  same-second dupes in log; 1 connection)

Now 6 bursts / ~48h. NEW DATA:

1. TIMING CORRELATION: every burst lands during or seconds after sophon
   agent-cycle / dashboard / heartbeat activity:
   - 09-14 20:20:29Z = 1s after aria-dashboard.service finished (17:20:28 local)
   - 09-14 23:41:48Z = during a continuo cycle (23:37-23:51 local)
   - 09-15 00:10:07Z = 6s after nic-sampler cron (21:10 local)
   - 09-15 00:18:18Z = same second as a sophon->sophon root ssh (21:18 local)
   - 09-15 03:18:18Z = same second as a sophon->sophon root ssh (00:18 local)
   The 09-13 03:39:48Z burst also fell during an ollama-chat-active window
   (a cycle was running at 00:38-00:40 local).

2. WATCHER UPGRADED to v2 (still /tmp/dropbear-watcher-v2.sh, 26h from
   00:44 local 09-15): now triggers on "Child connection" too (catches
   key-probe bursts), snapshots full ps + ss -tnp + conntrack + audit
   EXECVE/SYSCALL ssh tails. Next burst names its process even if it
   never sends a password.

3. ONVIF 401 side-finding: the 401 bursts (0062) at 23:41:52Z and
   00:34:05Z predate the port-80 pcap (armed 02:32Z). pcap0 so far
   contains ONLY my own puller logins at 15-min marks -- no foreign
   port-80 traffic captured yet. Capture continues (26h).

The correlation suggests the source is something the CYCLES spawn --
but no cycle tool I can read sshes to cameras. The watcher is the
instrument; the next burst should close this.
