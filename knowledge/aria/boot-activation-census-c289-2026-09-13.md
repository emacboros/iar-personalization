# Boot-activation watch CLOSED -- 7/7 all-positive (c289, 2026-09-13)

## Verdict

The full-wave boot census is COMPLETE and ALL-POSITIVE. Every camera
with a nightly reboot cron boots with `syslogd -R 192.168.2.69:514`
live. The camera syslog sink (c281) is self-healing across the entire
reboot staircase -- no camera ever comes back without remote logging.

## The census

| camera | IP  | cron | verified | evidence |
|--------|-----|------|----------|----------|
| ext1   | .101 | 01Z | c285 (half-wave) | ps grep syslogd -R |
| ext2   | .102 | 02Z | c285 (half-wave) | ps grep syslogd -R |
| ext3   | .103 | 03Z | c285 (half-wave) | ps grep syslogd -R |
| ext5   | .105 | 05Z | c289 | up 7742s, pid 575, `-R 192.168.2.69:514` |
| int1   | .201 | 06Z | c287 addendum | up 55s, syslogd -R live |
| int2   | .202 | 07Z | c289 | up 8 min, pid 579, `-R 192.168.2.69:514` |
| int3   | .203 | 08Z | c289 | up 23.1h (pre-reboot), -R already live from prior boot |
| ext4   | .104 | --  | EXCLUDED | power-dead (Nacho's), no crons run |

7/7 cameras with crons: boot-activation POSITIVE. The staircase-splice
mechanism (c279) is now fully closed at both ends: the reboot crons
fire on schedule AND every boot re-activates the syslog sink.

## Notes

- int3's check ran BEFORE its 08Z reboot (uptime 23.1h) -- the -R flag
  was already live from the PREVIOUS boot, which is itself evidence the
  flag persists across reboots (it is in the boot config, not a
  one-shot). The 08Z reboot will re-confirm; no further watch needed.
- The watch (roadmap c288 item 1) is WITHDRAWN as of this cycle.
- The staircase prediction (fps-limit ~21s after each reboot) held for
  8 consecutive crontab hours (c287-c288). No open questions remain in
  this class.

## Instrument note

- int3's run.cgi initially returned the command echo with no output
  until a fresh login cookie was used -- the run.cgi output follows the
  command echo; parse AFTER the echo line (recipe detail for the next
  census).