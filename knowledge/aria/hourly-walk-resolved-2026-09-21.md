# RESOLVED (aria c174, 2026-09-21 ~09:20Z): the "hourly sequential walk" = the camera reboot schedule itself

## Verdict

The c173 open question -- "what iterates cameras hourly at :00
(22:00-04:01Z display, one camera per hour, index order), died after
the 05:02Z reboots" -- is RESOLVED. The walk IS the nightly staggered
reboot schedule. There is no separate hourly iterator.

## The chain (all verified live this cycle)

1. **The reboot crons are real and staggered (UTC):** .101@01:00,
   .102@02:00, .103@03:00, .104@04:00, .105@05:00, .201@06:00,
   .202@07:00, .203@08:00 (now disabled). Verified per-camera via
   thingino run.cgi `crontab -l` (the real crond dir is
   /etc/cron/crontabs, NOT /etc/crontabs -- the first probe read the
   wrong path and returned "No such file"; the c169/c243-era records
   used crontab -l and were right).
2. **Each reboot manufactures the walk signature:** at HH:00:05Z the
   camera's stream dies -> go2rtc producer WRN i/o timeout (2 per cam:
   read timeout + dial timeout) -> corrupt segment discard (sometimes)
   -> fps-limit -> ffmpeg restart -> reboot completes at HH:02Z.
   Verified for ext1: WRN 22:00:06Z, corrupt segment 22:00:19Z,
   fps-limit 22:01:02Z, reboot 01:02:00Z... (display-local vs UTC
   anchored via date -u on the rssi uptime ledger).
3. **It recurs nightly.** The 09-19->09-20 night shows the same
   :00-hourly fps-limit pattern (22:00, 23:00, 00:00, 01:00, 02:00,
   03:01, 04:01 display). c173's "the walk stopped after the 05:02Z
   reboots" was an artifact of the stagger ENDING at 07:02Z (202 cam):
   after 07:02Z no camera reboots again until the next night's 01:00Z.
   The walk didn't stop; the night did.
4. **Why c173 saw it as new:** the NIC-degraded epoch (100Mbps,
   09-17..09-20) made pre-reboot stream deaths VISIBLE as corrupt
   segments + fps-limit events at a rate the healthy-link nights didn't
   show. The walk was always there; the degraded link turned it into
   recorder casualties.
5. **.203's stopped-rebooting question (relay ask #2):** .203 rebooted
   daily at 08:02Z through 09-18 (rssi uptime ledger, 7 consecutive
   days). Its crontab line `0 3 * * * reboot -f` is commented out
   (#0 3) -- and per c125 (b1dc2e06, 09-19): "ALREADY commented before
   this cycle (pre-existing, not mine)". The 08:00Z entry documented in
   c243-era records (416682aa: ".203: 0 8 * * * reboot -f") is GONE
   from the current crontab -- the crontab was last modified Sep 19
   20:45 cam-clock (c125's RSSI size-cap deploy touched it). So: the
   08:00Z reboot entry was removed/commented between 09-18 08:02Z (last
   reboot) and 09-19 20:45 (crontab mtime). c125's doc says the 03:00
   line was already commented pre-cycle -- meaning the 08:00 entry
   disappeared in that same window. WHO edited it is unknown; the
   edit predates my c125 deploy by minutes-to-a-day. Nacho question
   stands: did he disable .203's reboot on 09-18/19?

## Corrections to c173

- "The pattern died after the 05:02Z camera reboots" -- WRONG. It
  ended because the stagger's last cam (.202) reboots at 07:02Z; the
  pattern resumes nightly at 01:00Z. c173's window (22:00-04:01
  display) simply didn't include the tail cams' hours.
- "No sophon timer matches; camera-side hourly task is the suspect" --
  confirmed camera-side, and now identified: the staggered reboot
  crons themselves.

## Operational consequences

- The nightly 01:00-07:00Z window = 7 expected producer WRNs + up to 7
  fps-limit events + occasional corrupt segments. Any WRN-rate or
  freeze census must mask 01:00-07:10Z nightly (the c169 reboot-window
  masking already does this for wrnrate; extend the same mask to
  EPISODES/at analysis when attributing).
- .203 (no nightly reboot) is the fleet's long-uptime control cam.
- The pre-reboot producer timeout is a NORMAL camera-side mechanism,
  not a wedge. The debug-witness should not spend itself on reboot
  windows (already the plan: check reboot schedule first).

## Open

- WHO commented/removed .203's 08:00Z reboot entry between 09-18 and
  09-19 20:45 (Nacho? a thingino UI action? unknown). Filed as a
  question for the next session notes; low stakes.