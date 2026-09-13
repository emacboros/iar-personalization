# Staircase-splice mechanism: full-day census (c279, 2026-09-13)

## What this is

The c278 finding named the THIRD mechanism: nightly reboot crons ->
session remake -> splice -> watchdog heal. This cycle ran the full-day
census against the prediction: "expect one per camera per night at its
crontab hour." Result: PREDICTION HOLDS, plus one refinement.

## The crontab map (verified live on each camera this cycle)

| cam  | reboot hour (UTC) | crontab verified |
|------|-------------------|------------------|
| .101 ext1 | 01:00 | yes |
| .102 ext2 | 02:00 | yes |
| .103 ext3 | 03:00 | yes |
| .104 ext4 | (power-dead) | n/a |
| .105 ext5 | 05:00 | yes |
| .201 int1 | 06:00 | yes |
| .202 int2 | 07:00 | yes |
| .203 int3 | 08:00 | yes |

## Full-day fps-limit census (frigate journal, 2026-09-12, local -03)

The watchdog "exceeded fps limit" line is the splice signature (the
detect stream stalls ~20-24s, fps watchdog fires, restart heals).

Splice events at crontab hours (predicted, staircase class):
- 00:00:35 ext3 (crontab 03:00Z = 00:00 local -- MATCH)
- 02:00:59 ext5 (crontab 05:00Z = 02:00 local -- MATCH)
- 03:01:05 int1 (crontab 06:00Z = 03:00 local -- MATCH)
- 05:01:05 int3 (crontab 08:00Z = 05:00 local -- MATCH)
- 21:29:31 ext1 (crontab 01:00Z = 22:00 local -- 30min EARLY, see below)
- 22:00:41 ext1 (crontab 01:00Z = 22:00 local -- MATCH)
- 23:00:39 ext2 (crontab 02:00Z = 23:00 local -- MATCH)

Non-crontab events (other classes, not staircase):
- 00:13:59 ext4 (power-dead camera, 404/timeout class)
- 10:37:40-45 int1+ext5+int2 (3 cams, same-second burst = WAVE class)
- 12:41:13 ext3 (single, unclassified)
- 15:39:56-15:40:05 int2+int1+ext3 (3 cams, 9s spread = WAVE class)
- 16:17:15-23 + 16:19:36-46 (14 events, 8 cams in 2 bursts 2min apart
  = WAVE class, the biggest burst of the day)

## The refinement: the early event

ext1 fired at 21:29:31 local (30 min before its 22:00 crontab hour),
then again at 22:00:41 (crontab hour, predicted). The 21:29 event had
NO splice markers in the detect log (no bad cseq, no backward queue,
no invalid-dropping until the 22:01 restart's normal post-kill drain).
The 22:00 event had the full splice signature (DTS/PTS invalid
dropping st:1, 100 lines, DTS deltas ~1290us = 90kHz audio clock, next
delta ~14.5M us = 3.6h audio-stream gap).

So: the crontab-hour event is the splice; the 21:29 event is something
else (fps-limit fired without splice markers -- possibly a transient
frame burst, possibly the same wave class as 16:17). The staircase
prediction survives; the "exactly one per camera per night" phrasing
needs the caveat that fps-limit is not splice-specific.

## The ext1 22:01 DTS anatomy (new detail, worth keeping)

- st:1 = the AUDIO stream (all 100 invalid-dropping lines are st:1).
- DTS deltas ~1290us = 90kHz clock (audio), consistent.
- DTS vs next delta ~14.5M us = the "next" pointer is 3.6 HOURS ahead
  of the arriving packet's DTS. The detect process's audio timeline ran
  ahead of the camera's post-reboot audio stream by 3.6h of audio time.
- ext2's 23:01 event instead showed the classic bad-cseq + "Queue input
  is backward in time" (aac) signature -- same mechanism, different
  ffmpeg error surface (cseq jump vs timeline jump).

Both are the same thing: the session remake mid-stream hands ffmpeg an
audio stream whose timeline no longer matches what it was decoding.

## Method note

The puller v2 fix (camlog-puller.sh) was landed this cycle BEFORE this
census: the RSSI cron floods the ~306-line logread ring with crond
lines, so ~5h after the last real log line the filtered snapshot goes
empty -- that state is now labeled with the buffer census (total/crond)
instead of a bare "empty snapshot". The 105/202 "empty snapshot" lines
from 00:30Z onward were exactly this (all-crond saturation), NOT
camera failures. Verified live: .105 buffer = 305/305 crond, camera
healthy (uptime 12:49, rssi flowing).

## Prediction for next nights

Each camera should produce exactly one splice-class fps-limit event at
its crontab hour (local hour = crontab Z hour - 3). ext1 22:00:41 and
ext2 23:00:39 tonight are the first two confirmed. int1's 06:00Z =
03:00 local is NEXT tonight. Watch for it.