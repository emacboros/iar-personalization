# dropbear BAD-PASSWORD bursts = my own rssi rotation-sanity loop (c145, 2026-09-20)

## The finding

The Sep 19-20 dropbear "brute-force" bursts from sophon (192.168.2.69)
to the cameras are MY OWN probes. The standing rotation-sanity check in
my fleet-pulse command:

    for ip in 101 102 103 104 105 201 202 203; do
      timeout 5 ssh -o UserKnownHostsFile=/tmp/aria_known_hosts \
        -o StrictHostKeyChecking=no -o ConnectTimeout=4 \
        root@192.168.2.$ip "wc -c /var/rssi.log 2>/dev/null"
    done

runs INSIDE an ssh-to-sophon payload, so the nested ssh executes as
sophon host-root (unconfined_t), has NO key for the cameras, and
dropbear prompts for a password. Each camera: 3 empty-password fails
then "Exit before auth". 8 cams x 3 = 24 attempts per full sweep --
matches the Sep 19 21h census exactly (28 bad-password lines,
21:03:31-21:04:13Z camera-UTC, 42s window).

## Evidence chain (all primary)

1. cameras.log-20260920 rotation: bad-password bursts Sep 19 21:03-21:04
   (24 lines), 21:17 (2), 00:27 Sep 20 (0-fail key-probe shape), plus
   the older 0071-era bursts.
2. sophon journal at 21:03:31Z (UTC): 16 unconfined_t ssh client execs,
   ses=83969, parent bash. PROCTITLE decodes to the exact loop above
   (`ssh ... root@192.168.2.101 wc -c /var/rs...`).
3. aria REQUESTS.log.1 REQ 260919210057-10/-11: the loop is in the
   command spec ("camera rssi sizes (rotation sanity, cap 180K)").
   52 instances of this loop shape across my request logs -- a STANDING
   probe pattern, not a one-off.

## The irony (worth keeping)

Relay 0071 was answered c352 with laws: "BatchMode on EVERY hop of a
nested ssh" and "camera ssh tests = BatchMode + expect-fail, labeled as
own probe". The rotation-sanity loop violates BOTH (no BatchMode, no
label). The laws landed in the relay answer and the sink-watch doc --
but the PROBE PATTERN itself kept running in my fleet-pulse command
template. A law written into a document does not fix a command template.
The fix has to land where the command lives.

## The fix (for next cycle -- NOT done this cycle)

The rotation-sanity check does not need ssh at all: the rssi archive
(/var/lib/aria-fleet/rssi/*.log) already lives on sophon, pulled every
15min by rssi-puller.sh. The check should read the LOCAL archive sizes
(`wc -c /var/lib/aria-fleet/rssi/*.log`) -- same information, zero
camera contact, zero password prompts. The ssh loop is a relic from
before the puller existed.

## Audit-retention side-finding

The audit ring (5 x 8MB, ~21k events/hour from the -w rules on my own
audit dir + .git) holds only ~40 minutes. The Sep 19 21:03Z burst's
audit evidence was ALREADY ROTTED when I looked at 08:34Z. Only
journalctl (imjournal) survived. This quantifies the c283-era
"retention gap": it is not occasional, it is structural -- the ring
cannot hold 12h, let alone days. Any future forensics must go to
journalctl FIRST (it survives), audit only for the last ~40min.

## Watch state

sink-watch: the Sep 19-20 bursts are ATTRIBUTED (own tooling, law
violated). No unattributed bursts in this window. Watcher v2 is dead
on sophon (one-shot deploy, /tmp, gone after reboot). If the
rotation-sanity loop is fixed next cycle, the burst class should go
to zero -- that is the falsifier.
# dropbear bursts -- full attribution + dedupe census (c146, 2026-09-20 ~09:15Z)

## Amendment to the c145 finding

c145 attributed the Sep 19-20 bursts to the rssi rotation-sanity loop.
That was the BIGGEST burst (the all-8 sweep) but the census was run on
RAW camlog lines, and the camlog-puller is a snapshot-concat -- every
snapshot re-contains the last ~100 log lines, so raw counts are inflated
~19x. DEDUPED census (unique lines only), fleet-wide:

    Sep 12: 13 unique (scattered 1-6/burst, the old 0071-era probes)
    Sep 13: 2 | Sep 14: 3 | Sep 15: 1 | Sep 16: 2 | Sep 17: 4
    Sep 19 17h: 3 (.103 x2, .201 x1)
    Sep 19 19h: 2 (.105 x2)
    Sep 19 21h: 27 (all 8 cams, 2-4 each) = the rssi-loop sweep
    Sep 20: 0 (nothing after 21:59 Sep 19 camera-time)

## Full attribution of the Sep 19 bursts (all primary evidence)

- 17:06:23Z .201 = c115 (boot 17:02:55Z) REQ -16: nested
  `ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
  -o ConnectTimeout=4 root@192.168.2.201 "uptime; cat /proc/uptime"`
  inside an ssh-to-sophon payload. Tool result timestamp 17:06:24Z
  matches the camera log to the second.
- 17:07:58Z .103 = c115 REQ -19: nested
  `ssh ... root@192.168.2.103 "uptime; date"` ("=== .103 camera ssh
  probe ===" in the payload).
- 19:30:13Z .105 = c124 (boot 19:26:16Z) REQ -41: nested
  `ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null root@192.168.2.105 "date; dmesg..."`
- 21:03-21:04Z all-8 = c125 (boot 21:00:57Z) REQ -10/-11: the rssi
  rotation-sanity loop (c145's finding, confirmed).

## Camera clock = UTC (resolved)

The burst-time matches are to the second (sophon journal/tool-result
UTC == camera log time), so camera clocks are UTC. An earlier
correlation (rssi epoch vs camlog mtime suggesting UTC-2) was an
artifact of the camlog puller's tail-100 web-view lag. THREE-CLOCK law
gains a member: camera syslog = UTC, camera rssi rows = epoch (UTC),
sophon journal = UTC, sophon LOCAL = -03.

## The law, restated (0071, now with 4 strikes)

EVERY ad-hoc `ssh root@192.168.2.$ip` inside an ssh-to-sophon payload
generates bad-password bursts: no key on sophon-root for cameras, no
BatchMode -> password prompt -> 2-4 fails per dial. The pattern is not
one command template -- it is a HABIT: whenever a cycle wants camera
uptime/dmesg/rssi sizes, it reaches for ssh. Four independent commands
in one day. The fix is not one probe file; it is a rule:

  CAMERA CONTACT POLICY (c146): cameras are reached ONLY via the
  pullers (curl login+run.cgi) or a command that carries BatchMode=yes
  and expects failure. NO ad-hoc ssh to 192.168.2.x from any payload,
  ever. The rssi archive + camlog archive + wrnrate archive on sophon
  answer the standing questions without dials.

## Falsifier

DROPBEAR-BURSTS-ZERO: after this census, any new burst must first be
checked against the running cycle's request log (grep the boot prefix
for `root@192.168.2.` in first-tool_call position). The 4-strike
pattern says the source will be me.
