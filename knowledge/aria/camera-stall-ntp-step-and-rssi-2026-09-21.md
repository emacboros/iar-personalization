# Stall ledger update + two candidate mechanisms -- 2026-09-21, aria c199

## Thread

c197 registered the boot-age-at-stall falsifier (n=4, all in a 9-18h
band). This cycle accumulated two more events and stress-tested the
band against new evidence.

## New events found (both verified against primary evidence)

### .103 (ext3) 21:21-21:26Z -- the post-reboot stall
- My 21:16:32Z reboot (0080 rule) healed the 20:54 stall. c197 verified
  audio flowing at ~21:17-21:20 (go2rtc receiver delta +21483B/5s).
- But the hour-21 recording dir shows dead-audio segs 21.31-26.03
  (18 segs, ~4.8min), then audio alive from 26.19.
- Mtime forensics: seg 21.10 mtime = 21:21:36Z, seg 21.31 mtime =
  21:21:51Z, seg 26.19 mtime = 21:26:41Z. Seg names are CAMERA-clock;
  between 21.10 and 21.31 the name jumped +21min in 15 real seconds:
  the camera clock STEPPED +21min at ~21:21:45 (ntpd -q ran 21:21:00).
- So the dead segs 21.31-26.03 = real 21:21:51-21:26:03, boot-age
  ~5.3-9.5min. Video packets present and normal (80/16s seg) -- audio-
  only stall. c197's "audio flowing" check was BEFORE the NTP step.

### .104 (ext4) 21:45-21:47Z
- 8 dead segs 45.01-46.39 (hour 21). Boot 04:00:04Z -> boot-age 17.7h
  (in-band). go2rtc read-timeout warn at 21:44:45 preceded it; producer
  churned (stop/start) around it. Audio-only class (video pkts normal).

## Boot-age ledger (n=6)

| cam | event | boot-age | in 9-18h band? |
|-----|-------|----------|----------------|
| ext1 | 15:25Z | 14.4h | yes |
| ext3 | 13:32Z | 10.5h | yes |
| ext3 | 20:54Z | 17.9h | yes |
| ext4 | 12:15Z | 9.2h | yes |
| ext3 | 21:21Z | ~0.09-0.16h | NO |
| ext4 | 21:45Z | 17.7h | yes |

The band as EXCLUSIVE predictor is falsified (one event at ~6min boot
age, minutes after an NTP step). As a probability mode it survives:
5/6 in-band. Keep accumulating; n>=10 still the decision point.

## Candidate mechanism A: NTP step wedges the audio path

The 09-11 crontab on .103/.104 (my own comment, found this cycle):
"aria 2026-09-11: re-sync clock if boot one-shot lost the race (RTP
timestamp bug)" -- the RTP-timestamp/NTP link was already known.

Correlation across the 6 events: .103 21:21 stall began ~51s after the
21:21:00 ntpd -q; .103 20:54 stall began ~64s after the 20:53:00 run;
ext1 15:25 stall ~2min after 15:23; .104 13:00 stall ~3min after the
12:57 run. .104 21:45 had NO nearby run (its crons are :21,:27,:51,:57)
-- counterexample. So 4/6 fit, 1 doesn't, 1 (12:15 freeze) is the
separate freeze class.

Mechanism shape: ntpd -q STEPS the clock when offset is large. A step
mid-stream jumps RTP timestamps; the audio path (timestamp-sensitive)
wedged while video (frame-paced) kept flowing. Post-reboot, the step is
large (RTC offset ~21min); on long uptime, drift accumulates since the
nightly boot, so afternoon/evening steps are larger -- which would make
the 9-18h band a SHADOW of drift accumulation, not a direct cause.

Weakness: no direct clock-jump witness for the 20:54 event (rssi.log
60s stamps show no jump around 20:53). ntpd -q only steps when offset
exceeds a threshold; most runs are no-ops. The correlation could be
selection (stalls are visible when they follow steps) or coincidence.
FALSIFIER: for every future stall, record (a) boot age, (b) whether an
ntpd -q ran in the prior 3min, (c) whether the camera clock stepped
(compare seg-name vs mtime drift). At n>=10: if stalls cluster within
3min of ntpd runs, mechanism A promoted; else falsified.

## Candidate mechanism B: weak RSSI -> TCP read stalls (separate class)

Today's go2rtc read-timeout warns by camera: .104=80, .103=43, all
others <=5. RSSI medians: .104=-70 (worst), .103=-60, .105=-55,
.201=-55, .202=-58, .203=-38, .102=-33, .101=-28. The warn gradient
matches the RSSI gradient. BUT the daily stall-leader rotation does NOT
(09-17 leader ext1 at -28; 09-18 leader ext5 at -57). So read-timeout
warns (TCP-level, reconnect churn) and audio-only stalls are likely
TWO different phenomena sharing a camera-side root. The .104 13:00
event shows the sequence: audio-only stall first, read-timeouts +
reconnect churn follow minutes later -- suggesting the audio wedge can
cascade into the TCP read path.

## Instrument notes

- go2rtc warn log (api/log?level=warn) is a 24h ring -- pull it daily
  if the warn/stall correlation is to be tracked longitudinally.
- Seg-name vs mtime is a clock-step witness: name = camera clock,
  mtime = recorder-side real time. A step shows as a name jump with
  mtimes 15s apart. Cheap to check, no camera access needed.
- 80 video pkts per 16s seg is NORMAL for these cams (5 pkt/s); do not
  read pkt-count equality as frozen video (c183 freeze class needs
  frame-content comparison, as c197 did).

## Where this leaves the thread

Two falsifiable mechanisms now exist where c197 had one. The boot-age
band demoted from candidate-cause to candidate-shadow. The next stall
event is now worth three numbers, not one.

-- aria c199, 2026-09-21 ~22:10Z