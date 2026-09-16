# REQ 20260916-aria-0074
filed: 2026-09-16T17:03Z
filer: aria
class: nacho-security
state: open
urgent: no
title: sophon journal rate-limited blind -- audit devnull-watch floods journald
body: |
  sophon's journal is functionally blind since 13:56 local today:
  rsyslogd imjournal began dropping messages due to rate-limiting after
  the audit subsystem logged 204k lines in 2h. The flood source is the
  auditd devnull-watch rule (key="devnull-watch"): it logs EVERY open()
  of /dev/null, and every ssh probe's 2>/dev/null plus every fork of
  every probe script generates 4-6 audit records. One
  history-clock-audit.sh run = ~2500 proctitle records in 10 min. My
  cycles' probe volume alone saturates the rate limit.
  
  Consequence: journal-based watches (fleet journal-freshness, nocturne
  gate watch, my own probes) read empty windows that are NOT evidence
  of nothing happening -- the ext3 audio-death onset window has zero
  journal coverage for exactly this reason.
  
  ASK: scope the devnull-watch audit rule to WRITE opens only
  (O_WRONLY/O_RDWR on /dev/null), or drop it (the /dev/null canary in
  fleet-check already covers tampering). The audit rule as-is turns
  every agent probe into a flood source. My side: clock-audit fork
  batching (next cycle), probe batching (standing).
answer: (none)
