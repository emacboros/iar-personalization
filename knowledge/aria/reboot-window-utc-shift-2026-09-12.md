# Reboot window shifted: the NTP fix moved the camera reboot crons into UTC (aria c227, 2026-09-12 ~03:05 UTC)

## The observation that started it

Fleet-wide /proc/uptime census (03:04Z, direct thingino API):

| cam | boot (UTC) | uptime |
|-----|-----------|--------|
| .101 | 09-12 01:00:09Z | 2.1h |
| .102 | 09-12 02:00:08Z | 1.1h |
| .103 | 09-12 03:00:08Z | 0.1h |
| .104 | 09-11 09:44:20Z | 17.3h |
| .105 | 09-11 09:44:20Z | 17.3h |
| .201 | 09-11 09:44:26Z | 17.3h |
| .202 | 09-11 09:44:48Z | 17.3h |
| .203 | 09-11 08:00:10Z | 19.1h |

A perfect on-the-hour staircase (01:00Z, 02:00Z, 03:00Z) for the
first three, and the rest clustered at 09:44Z the previous morning.
The staircase shape looked like a new failure mode: hourly reboots.

## The mechanism (verified on-camera, /etc/cron/crontabs/root)

Every camera carries a nightly `reboot -f` cron, staggered one hour
apart: .101 @ 1:00, .102 @ 2:00, .103 @ 3:00, .104 @ 4:00, .105 @
5:00, .201 @ 6:00, .202 @ 7:00, .203 @ 8:00. These are pre-existing
(thingino default pattern, present before my RSSI cron lines; no
aria comment on the reboot lines).

The clock those crons fire against CHANGED. c24 (Sep 4) read the
schedule as "01:00-08:00 LOCAL" -- but the cameras had no RTC and
their clocks were unsynced then, so the reading was anchored to
whatever the camera clock showed. The camera-clock-race fix
(camera-clock-race-2026-09-11.md) added a 30-min `ntpd -q -N` cron
to all 8 cameras; now every camera holds UTC (verified live: all 8
report identical `date` = sophon UTC).

Busybox crond has no TZ handling: the cron hours are UTC hours.
The rolling reboot window has MOVEN from 01:00-08:00 local
(04:00-11:00Z) to 01:00-08:00 UTC (22:00-05:00 local).

## Consequences

1. **The .101 reboot-cause watch (roadmap item c) is ANSWERED: cron,
   not hardware/power.** The 01:00Z boot c225/c226 watched was the
   camera's own nightly reboot firing three hours earlier than the
   old local-time expectation. Same for .103's 03:00Z reboot caught
   live this cycle (RSSI counter reset at 1789182120, uptime 208s
   when read at 03:03:32Z).
2. **The camera-clock-race doc's verification watch is stale**: it
   predicted reboots "01:00/02:00/06:00 local" -- those are now UTC
   times. The SEG-TAIL sawtooth expectation must shift accordingly.
3. **The reboot window now overlaps the evening block hours**
   (21:00-00:00 local = 00:00-03:00Z): .101's reboot lands at 22:00
   local, mid-block for the e3 motion series. The e3 midnight-cut
   series (03Z bucket) is unaffected (reboot at 01Z/02Z lands in
   the 00-02Z pre-cut buckets -- a possible small motion
   perturbation in the 00Z/01Z buckets on reboot nights; the 03Z
   post-cut bucket is clean).
4. **The 14:22L stall class is UNAFFECTED** (daytime, 17:22Z, no
   reboot in window; the reboot crons are all 01-08Z).
5. **Prediction to falsify**: .104 boots at 04:00Z, .105 at 05:00Z,
   .201 at 06:00Z, .202 at 07:00Z, .203 at 08:00Z tonight. If the
   boots land on those UTC hours, the mechanism is confirmed
   end-to-end. (The 09:44Z cluster on .104/.105/.201/.202 was
   yesterday's pre-sync drift state -- clocks had synced ~09:44Z
   after boot one-shot delays, so crons fired late; expect clean
   on-the-hour fires now that the 30-min ntpd cron holds sync.)

## Laws

- A fix that changes a clock changes every schedule that reads that
  clock. The NTP fix was correct and its side effect was invisible
  until the reboot census surfaced the staircase.
- A cron schedule has no timezone of its own; it inherits whatever
  the machine's clock believes. Documenting "reboots at 01-08 local"
  baked a clock assumption into the record that the next fix broke.
- The staircase pattern (successive on-the-hour boots across
  sibling devices) is a signature of staggered schedules, not of a
  spreading fault. Differential first: read the crontabs before
  theorizing about power.