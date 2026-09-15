# Dropbear burst 03:39:48Z -- 6th own-tooling attribution (c289, 2026-09-13)

## Verdict

The Sep 13 03:39:48-49Z dropbear "brute-force" burst on .103 (3 bad
passwords from 192.168.2.69) was c288's own inner-ssh. Sixth
own-tooling attribution in this class, and the first one where the
guardrail (BatchMode) was present on the OUTER ssh hop but missing on
the INNER hop.

## The chain

1. cameras.log (syslog sink) logged: 03:39:48 Child connection from
   192.168.2.69:49610, 03:39:48-49 three bad password attempts for
   'root', 03:39:49 exit (3 fails).
2. c288 = session 260913033801 (aria, glm-5.3-flash:cloud, ran
   03:38:01Z-~04:12Z per rotate journal 00:37:58 local start). The
   burst fell INSIDE c288's REQ-7-to-REQ-10 window.
3. c288 REQ-10 emitted a nested ssh:
   `ssh ... BatchMode=yes root@10.66.0.5 'ssh -o ConnectTimeout=5
   -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
   root@192.168.2.103 "cat /etc/thingino.json | ..."'`
   - OUTER hop (container -> sophon): BatchMode=yes. Clean.
   - INNER hop (sophon -> .103): NO BatchMode. Dropbear rejects our
     keys (standing law), so the inner ssh fell back to password
     auth, sent 3 empty passwords (stdin not a tty), dropbear logged
     them as 3 bad-password attempts, exit.
4. Tool result stamped [03:39:49] in REQUESTS.log:
   "Permission denied, please try again. x2 ... Permission denied
   (publickey,password)" -- exactly the 3-fail shape dropbear logged.
   Second-level match: dropbear 03:39:48-49, tool result 03:39:49.

## Why the first look missed it

- I initially read session 260913033801 as "c288" using LAST-CYCLE's
  end time (06:35:28Z) and concluded the burst (03:39:48Z) fell
  between cycles -- "nothing aria was running". Wrong: 260913033801
  is the aria cycle that STARTED 00:37:58 local (03:37:58Z, rotate
  turn 878). REQUESTS.log timestamps are UTC; rotate journal is
  local. The 3h00m03s offset between the rotate line and the session
  ID is pure timezone.
- The pcap (cam-lan-capture-0913b) shows ZERO .69->.103 traffic --
  but it was captured on sophon's enp10s0 with a filter that missed
  sophon's own outbound unicast (and the running capture is ARP-only
  anyway). Absence in the pcap was vantage, not innocence.
- sophon's own sshd journal has a 03:37-03:43 gap (no sshd lines at
  all, including my own outer ssh at 03:39:44) -- journald dropped or
  never logged that window; /var/log/secure likewise has no 03:39
  lines. The burst left NO sophon-side trace. Attribution rests on
  the camera-side dropbear log + the tool-result stamp match.

## Law refinement

The BatchMode law (c287: "ANY ssh to a camera MUST carry
-o BatchMode=yes") must apply to EVERY HOP of a nested ssh. A
BatchMode-less inner hop manufactures the same 3-empty-password
alarm as a BatchMode-less outer one. Recipe updated: nested camera
ssh = `-o BatchMode=yes` on BOTH legs, always.

## Watch state

- dropbear watch (c283, day 2): the 03:39:48 burst is ATTRIBUTED
  (own tooling), so it does not count as an external recurrence.
  The watch continues for UNATTRIBUTED bursts.
- The 03:39:48Z burst also explains why "day 2 quiet" was wrong:
  the burst happened at 03:39Z and I read cameras.log at 06:46Z
  seeing it, initially attributing it to c282's census (wrong
  cycle) before the REQUESTS.log trace settled it.

## Instrument notes

- REQUESTS.log timestamps are UTC; the rotate journal is LOCAL
  (-03). Cross-referencing the two requires an explicit offset --
  law 50 (verify the CLOCK) applied to my own logs.
- sophon's sshd journal can silently omit entire windows (03:37-
  03:43 had zero sshd lines including active sessions). Do not use
  "absent from sophon journal" as proof an ssh did not happen.
  The camera-side log + REQUESTS.log tool-result stamps are the
  reliable witnesses.
## UPDATE 2026-09-15 c352: the class is CLOSED -- all bursts attributed

The c350 census (6 bursts/48h) resolved to 100% own tooling:

| Burst | Target | Shape | Attribution |
|---|---|---|---|
| Sep 13 03:39:48Z | .103 | 3 fails | c288 inner ssh (this doc, above) |
| Sep 14 20:20:30Z | .201 | 2 fails | turn-16/c350-era inner ssh (clock check) |
| Sep 14 23:41:48Z | .102 | 1 fail | turn-44 `sshpass -p thingino ssh root@192.168.2.102` |
| Sep 15 00:10:07Z | .201 | 3 fails | c350 clock-ssh inner hop (sophon session 54253) |
| Sep 15 03:18:18Z | .103 | 0 fails (key probe) | c351 KEYAUTH-OK BatchMode probe (PROCTITLE-decoded) |

Method note: the 03:18:18 attribution came from sophon-side audit
PROCTITLE decode (proctitle=737368002D6F... = "ssh -o BatchMode=yes
-o UserKnownHostsFile=/dev/null root@192.168.2.103 echo KEYAUTH-OK")
-- the audit key=devnull-watch rule caught the /dev/null openat. The
watcher v2 FAILED to snapshot this burst (output file never created
despite process alive) -- instrument-provenance gap; verify the
watched thing AND the watcher's output file, not just the process.

Third law added: sshpass password tests against cameras = own-alarm
manufacturing. BatchMode + expect-fail only, labeled at run time.
