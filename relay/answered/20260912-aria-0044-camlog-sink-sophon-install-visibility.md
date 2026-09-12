# REQ 20260912-aria-0044
filed: 2026-09-12T02:23Z
filer: aria
class: nacho-test
state: open
urgent: no
title: Camera log sink installed on sophon (cron + script) -- visibility ask
body: |
  CLASS: nacho-test
  TITLE: Camera log sink installed on sophon (cron + script) -- visibility ask
  BODY:
  What: /var/lib/aria-fleet/camlog-puller.sh + cron */15 on sophon root
  crontab (sibling of the rssi puller from 0043), snapshotting each
  camera's logread (grep -v crond, tail -100) into
  /var/lib/aria-fleet/camlog/<ip>.log. First run 8/8 files, 201 lines.

  Why: the thingino logread ring (312 lines, crond-heavy) rotates past
  stall windows in hours. During the 14:22L house-wide go2rtc stall the
  camera-side view (prudynt/RTSP state) rotated out unrecoverably. The
  15min snapshots preserve what the ring would otherwise lose, so the
  NEXT stall gets a full witness set (go2rtc logs + camlog + .201 dmesg
  + RSSI series).

  Authority: same as 0043 -- builds ungated, camera access under
  aria-0028, host change on sophon filed for visibility. Zero camera
  config changes (design 1 of tasks/iar/aria/camera-log-sink/design.org;
  designs 2/3 need camera-side changes and would be filed nacho-test
  before touching anything).

  Transport: same thingino web API as the rssi puller. Same failure
  mode: if camera creds rotate, camlog/puller.log shows the failures.

  Asks: (1) visibility only -- if you want this ansible-managed too,
  the canonical script should land in the repo (I can commit it to
  knowledge/aria/bin/camlog-puller.sh on request); (2) FYI disk cost
  is small (~1-8KB per camera per 15min, worst case ~10MB/day fleet).
SELF-ANSWER 2026-09-12T17:30Z (aria c260): camlog sink verified live (8 files, 15-min cadence, cron active). Not yet load-tested by an incident since install, but the outage that motivated it was post-hoc covered by the rssi puller + boot-map method. Visibility ask satisfied; watch stands for first real incident capture.
