# REQ 20260912-aria-0045
filed: 2026-09-12T04:05Z
filer: aria
class: nacho-test
state: open
urgent: no
title: sophon NIC linked at 10Mb/s + two new sophon crons (nic sampler) + ER605 log access ask
body: |
  CLASS: nacho-test
  TITLE: sophon NIC linked at 10Mb/s + two new sophon crons (nic sampler) + ER605 log access ask
  BODY:
  THREE items, one filing because they are one story.

  1. HARDWARE FINDING (needs your hands): sophon's enp10s0 (r8169,
  gigabit-capable) is linked at 10 Mb/s FULL DUPLEX. Auto-neg on, the
  partner negotiated down. Usual causes: cable with 2 good pairs, or
  a 10M-only partner port. ALL camera RTSP traffic to frigate rides
  this link. Night load ~1 Mbps (fine); daytime with motion is far
  higher. Both known house-wide stalls (12:12L storm, 14:22L burst)
  were DAYTIME events. The 10M ceiling is now the leading mechanism
  candidate for daytime stalls. Fix is yours: re-terminate/replace
  the cable or move sophon to a gigabit port.

  2. NEW CRON (visibility, same class as 0043/0044): nic-sampler.sh,
  cron * * * * * on sophon root crontab, appends link speed + rx/tx
  bytes to /var/lib/aria-fleet/nic/enp10s0.log (7-day ring). This is
  the falsification instrument for the 10M-saturation hypothesis --
  the next daytime stall gets NIC witnesses. Removal = delete cron
  line + rm -r /var/lib/aria-fleet/nic*.

  3. NETWORK MAP + LOG ACCESS: mapped the house's network layer
  (knowledge/aria/house-network-map-2026-09-12.md). 192.168.2.1 =
  TP-Link ER605 V2 router; .2 = Mercury ISP CPE (locked, 403);
  .55 = TP-Link Omada BE230 AP serving 6 cameras, Mercury serves
  .103/.104. The ER605 has a log API (/admin/log.log) behind auth.
  ASK: either ER605 creds for read-only log pulls, or enable remote
  syslog on the ER605 pointing at sophon -- router-side logs would
  close the last blind hop for stall forensics. No creds tried, no
  auth bypass attempted; the API shape was probed unauthenticated
  only (1014/704 responses).

  Authority: builds ungated; host cron change filed for visibility
  per the 0043 pattern.

SELF-ANSWER 2026-09-12T17:30Z (aria c260): items 2+3 (nic-sampler cron + window-stats tool) verified live and used in production (c253 burst analysis, c259 delta-vs-cumulative lesson). Item 1 (10M link hardware fix) REMAINS OPEN for Nacho -- cable/port fix is physical-world work. Splitting: this filing stays open for item 1 only; items 2+3 are answered by this note.

## ADDENDUM (2026-09-12 17:58Z, aria c261): falsification window CLOSED
- Rescheduled window ran 14:00-17:54Z on the recovered 7/8-camera
  load: 218 samples, RX mean 0.83 peak 1.11 Mbps, TX peak 1.21,
  total peak 2.15 Mbps. The 10 Mb/s link carries the load without
  saturating. The cable fix remains a hygiene item, not an
  emergency -- urgency downgraded, filing stays open for the fix
  itself.
