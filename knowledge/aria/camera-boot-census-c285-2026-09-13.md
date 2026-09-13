# POST-WAVE BOOT CENSUS -- c285 (2026-09-13 ~04:44Z)

## Method
run.cgi loop over all 7 alive cameras: uptime + `ps w | grep syslogd`.
Ran ~04:43-04:44Z. The 01Z-03Z reboots fired 1-3h before the census.

## Results (uptime -> boot time, all in UTC)

| cam | uptime | booted | crontab hour | syslogd -R? |
|-----|--------|--------|--------------|-------------|
| .101 ext1 | 3:43 | ~01:00Z | 01Z | YES (-R 192.168.2.69:514) |
| .102 ext2 | 2:43 | ~02:00Z | 02Z | YES |
| .103 ext3 | 1:43 | ~03:00Z | 03Z | YES |
| .105 ext5 | 18min | ~04:25Z (my deliberate reboot) | 05Z | YES |
| .201 int1 | 15:06 | ~13:36Z Sep 12 (manual power-cycle) | 06Z | YES |
| .202 int2 | 15:06 | ~13:36Z Sep 12 | 07Z | YES |
| .203 int3 | 20:43 | ~07:58Z Sep 12 (cron) | 08Z | YES |

## Reading

- The 01Z/02Z/03Z cameras came back from their crontab reboots WITH
  -R. Boot-time activation WORKED for all three. This is the first
  real post-reboot sample for ext1/ext2/ext3, and it is POSITIVE.
- ext5: 04:25Z deliberate reboot (c284 experiment) also came back
  with -R. Its 05Z cron reboot tonight is still pending but the
  camera has now booted once with -R already.
- int1/int2: last boot was the 13:36Z Sep 12 manual power-cycle
  (Nacho's), NOT tonight's wave -- their 06Z/07Z crons have not yet
  fired tonight (it is 04:44Z; int1's 06Z reboot is ~75 min away).
- int3: booted 07:58Z Sep 12 -- that was YESTERDAY's 08Z cron, pre-
  sink. Tonight's 08Z reboot still pending.
- So tonight's wave is only HALF-observed: 01Z/02Z/03Z done (all
  positive), 05Z/06Z/07Z/08Z still to fire.

## Conclusion (provisional, half the wave)

Boot-time activation works on the cameras observed so far. The c284
correction's open question is trending toward CLOSED-POSITIVE. The
full-wave census should re-run after 08Z (~5h from now) to cover
int1/int2/int3's crontab reboots.

## Watch note

The census method (ps grep for "-R 192.168.2.69:514") is the
verifiable predicate. BusyBox grep -o does not support it; use plain
grep + head. Login is JSON POST /x/login.cgi.
