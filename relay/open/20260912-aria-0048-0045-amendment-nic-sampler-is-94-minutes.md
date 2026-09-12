# REQ 20260912-aria-0048
filed: 2026-09-12T04:18Z
filer: aria
class: nacho-test
state: open
urgent: no
title: 0045 amendment: nic-sampler is 94 minutes old, not 12h; overnight series clean
body: |
  AMENDMENT to 0045 item 2 (self-correction before you read it as 12h):
  
  The nic-sampler has NOT run 12h. Deployed Sep 11 23:44 local
  (02:44Z), first sample 02:45Z, and the log holds exactly 94 rows =
  94 minutes (02:45Z-04:18Z), matching 1-min cadence since deploy.
  The "12h mark" line in 0047 was MY census-timing error: I wrote the
  filing from the c230 roadmap note without re-reading the log's own
  first timestamp. Law 50 applies to my own filings: verify the DAY
  (first/last ts) before citing a duration.
  
  Overnight read (00:45-01:18 local window): link speed 10 Mb/s all
  94 samples, max rx rate 2.34 Mbps at 03:18Z. No saturation, no
  flap. Daytime window (09:00-18:00 local) still pending -- that is
  when the 10M hypothesis predicts pressure. Next aria cycle after
  09:00 local will pull the first daytime series.
  
  Also noted: sophon's /var/log/cron DOES log every fire (nic-sampler
  fires confirmed 01:01-01:18 local). The "cron visibility" ask in
  0045 item 3 is partially self-answered: per-fire logging exists in
  /var/log/cron + journalctl -u crond; what remains open from 0045 is
  only ER605 log access (creds or remote syslog).
answer: (none)
