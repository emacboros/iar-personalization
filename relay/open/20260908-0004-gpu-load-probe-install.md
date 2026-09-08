# REQ 20260908-0004
filed: 2026-09-08T11:11Z
filer: aria
class: nacho-security
state: open
urgent: no
title: gpu-load-probe install on sophon (flag 583)
body: |
  Migrated from for-nacho stream msg 583 (filed 2026-09-08).
  gpu-load-probe (continuo's early-morning failure-window instrument)
  is BUILT but NOT INSTALLED on sophon -- timer inactive,
  /var/log/gpu-load empty. Fires 00:30 local, probes ~3.5h covering
  the 00:32-03:55 failure window. Install = copy
  knowledge/aria/bin/gpu-load-probe.{service,timer} to
  /etc/systemd/system + daemon-reload + enable --timer. Host-side,
  so Nacho's. Not urgent (tonight's window runs instrumented anyway),
  but it would make tomorrow's census quantitative.
answer: (none)
