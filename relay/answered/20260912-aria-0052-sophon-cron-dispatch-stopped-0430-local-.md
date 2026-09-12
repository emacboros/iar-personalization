# REQ 20260912-aria-0052
filed: 2026-09-12T07:31Z
filer: aria
class: nacho-external
state: answered
urgent: no
title: sophon cron dispatch stopped 04:30 local -- puller family blind
body: |
  Finding, not incident: the entire /var/lib/aria-fleet/ puller family
  (nic-sampler, rssi-puller, camlog-puller) went SILENT at 04:30 local
  (-03) on sophon and has not run since.
  
  Evidence:
  - nic log: 285 samples, last epoch 1789198200 = 04:30:00 local.
    Per-hour census: 00/01/02/03 = 60 each, 04 = 31 (stops exactly at
    04:30), 23 = 15 (deployment time). No samples after 04:30.
  - rssi + camlog logs: all mtimes 04:30:01-04:30:04 local. Same stop.
  - CROND journal: last CMDEND for all three pullers = 04:30:00-04.
    ZERO CROND entries after 04:30 for these (or anything else --
    journalctl -t CROND tail ends at 04:30:04).
  - crond service: active, no restarts, sophon uptime-s = Sep 1 (no
    reboot). Cron file intact (3 lines, no dupes).
  
  So: cron is alive, the jobs are registered, the 04:30 batch RAN --
  and nothing has fired since. The 05:00, 05:15... 07:30 slots are
  simply absent from the journal. That is not a script failure (the
  scripts ran fine at 04:30; puller.log has no errors); that is the
  scheduler not dispatching.
  
  This looks like the same signature family as the 01:59Z journald
  wedge (c233-c234): something on sophon stalls around 04:30 local
  and the system stops doing background work. The journal itself
  (fleet-check v2.21 journal-freshness) should be catching this --
  if fleet-latest is fresh, the journal is being written, and the
  failure is narrower: cron dispatch specifically.
  
  Two asks:
  1. If you see this before I do next cycle: check
     `systemctl status crond` and any 04:30-local jobs that might
     block the queue (a hung cron child can serialize some cron
     implementations).
  2. No urgency beyond the instruments being blind -- nic-sampler is
     the daytime-falsification instrument (0045) and it is now
     missing the morning ramp-up data.
  
  I will re-check from my next cycle (~08:30Z) before escalating
  further. If it self-heals, this filing becomes the record of the
  second unexplained sophon background-work stall in 24h.answer: SELF-ANSWERED (c239, 07:31Z, minutes after filing): FALSE ALARM --
    TZ artifact. The pullers never stopped: sophon's LOCAL time was 04:30
    (-03) when I read the logs; I read those timestamps as UTC. Actual UTC
    at read time was 07:30. Sampler verified live through 07:43Z (log
    current, 299 samples, 1/min cadence intact). Third CLOCK-family scar
    (c234 TZ wedge, c236 heartbeat gap, c239 this). Law 50 extension:
    epoch-anchor or TZ-convert remote timestamps BEFORE they enter an
    argument, not after.
