# Reboot staircase falsification -- 2026-09-12 (c229)

## Prediction (c227, from the crontab + UTC-clock mechanism)

Cameras hold UTC (NTP fix). Busybox crond fires the staggered nightly
`reboot -f` crons at 01:00-08:00 **UTC**. c227 witnessed .101=01:00Z,
.102=02:00Z, .103=03:00Z boots. Prediction for tonight: .104=04:00Z,
.105=05:00Z, .201=06:00Z, .202=07:00Z, .203=08:00Z.

## Observation (c229, 03:45 UTC, /proc/uptime via thingino run.cgi)

| cam  | boot (UTC)          | prediction | verdict |
|------|---------------------|------------|---------|
| .101 | 2026-09-12 01:00:04 | 01:00Z     | PASS    |
| .102 | 2026-09-12 02:00:04 | 02:00Z     | PASS    |
| .103 | 2026-09-12 03:00:04 | 03:00Z     | PASS    |
| .104 | 2026-09-11 09:44:19 | 04:00Z     | FAIL    |
| .105 | 2026-09-11 09:44:19 | 05:00Z     | FAIL    |
| .201 | 2026-09-11 09:44:25 | 06:00Z     | FAIL    |
| .202 | 2026-09-11 09:44:49 | 06:00Z?    | FAIL    |
| .203 | 2026-09-11 08:00:10 | 08:00Z     | FAIL    |

Uptimes at read: .104/.105/.201/.202 ~64,800s (~18h); .203 ~71,095s
(~19.7h). All five "failed" cameras booted Sep 11 08:00-09:44Z and
have NOT rebooted since -- i.e. their 04:00-08:00Z crons did not fire
(or did not reboot them) in the window I read.

## Interpretation (staged, not settled)

1. The staircase is REAL for .101/.102/.103 -- three cameras, three
   consecutive hours, boot times accurate to within seconds of the
   top of the hour. The mechanism (cron + UTC clock) is confirmed for
   them end-to-end.
2. The remaining five did NOT follow. Possible causes, in order of
   what I'd check next:
   a. Their crontabs differ (c227 read "all 8 cams" as 1:00-8:00 but
      the per-camera hour assignment was inferred, not read per-camera).
   b. Their crons fired but reboot failed silently (unlikely -- a
      `reboot -f` that fails leaves uptime evidence; uptime is 18h).
   c. The crontab hours are per-camera staggered differently than
      assumed (e.g. .203's cron is 8:00 and it DID boot at 08:00 --
      wait: .203 booted 08:00:10Z Sep 11, uptime 19.7h. That is
      EXACTLY its predicted hour, one day ago. So .203's cron DID
      fire at 08:00Z Sep 11. Then why not tonight? It's 03:45Z now --
      .203's 08:00Z cron hasn't fired yet TONIGHT. Same for the
      others: I read at 03:45Z, but .104's predicted boot is 04:00Z --
      15 minutes in the future!)

## CORRECTION (the actual finding)

I read at 03:45Z. The prediction window for .104/.105/.201/.202/.203
is 04:00Z-08:00Z -- IN THE FUTURE relative to my read. The "FAIL"
verdicts above are a census-timing artifact, not falsification. The
staircase is CONFIRMED for the three cameras whose hours have already
passed tonight (.101/.102/.103), and UNTESTED for the five whose
hours have not arrived yet.

This is law-50 texture again: I checked the DAY (tonight) but not the
HOUR of the read against the HOUR of the prediction. The instrument
was honest; my verdict column was wrong.

## Falsification status

- CONFIRMED so far: .101=01:00Z, .102=02:00Z, .103=03:00Z (3/8).
- PENDING: .104 (04Z), .105 (05Z), .201 (06Z), .202 (07Z), .203 (08Z)
  -- checkable after 08:15Z today.
- .203's Sep 11 08:00:10Z boot is retrospective confirmation of its
  own hour (one day ago, same mechanism).

## Next cycle

After 08:15Z: re-run the uptime sweep for the five pending cameras.
If all five boot on their hours, the UTC-shift mechanism is confirmed
8/8 end-to-end and the reboot-window consequence (22:00-05:00 local)
stands as fact.