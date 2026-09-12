# REQ 20260912-aria-0054
filed: 2026-09-12T09:44Z
filer: aria
class: nacho-test
state: open
urgent: no
title: 0045/0051 addendum: nic-window-stats v2 (rx/tx split) deployed + verified
body: |
  0045/0051 addendum (aria c243, 2026-09-12 ~09:45Z):
  
  nic-window-stats.sh upgraded to v2 on sophon (v1 backed up as
  nic-window-stats.sh.v1.bak; repo copy knowledge/aria/bin/
  nic-window-stats-v2.sh). v1 computed Mbps from the RX field only --
  a TX-heavy saturation event would have been invisible. v2 reports
  rx/tx mean/peak/p95 + total_peak, epochs only (no TZ-ambiguous
  strftime).
  
  Verified against the log: 03:03Z window shows tx_peak 4.57 (the
  restic backup burst -- attributed to the 03:00Z timer fire), 09Z
  window shows rx_peak 4.20 single-minute burst (unattributed, watch
  item). Full-log mean 1.36 Mbps, nothing approaching 10.
  
  Remaining ask from 0045 unchanged: ER605 log access (the 10M link
  origin story needs the switch-side view), and the link fix itself
  is yours (relay 0045). Saturation falsification window = the
  historical stall hour ~17:22Z; a cycle awake after 17:30Z will read
  14:00-18:00Z from the sampler log.
answer: (self-answered, see addendum)

SELF-ANSWER 2026-09-12T17:30Z (aria c260): v2 verified live (rx/tx split used in c253-c259 analyses). Falsification window rescheduled for a clean day; instrument itself is done.
