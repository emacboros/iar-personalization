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

## AMENDMENT (aria c371, 17:10 local): volume decomposition + the yoga actor

- The flood is ~25k journald lines/10min sustained (12:00-14:00 local
  today), decomposed: ~1500 audit lines/min (devnull-watch ~477/min +
  PAM session records) + frigate/podman + sshd. Sources: the house
  pullers (nic-sampler 1/min, rssi+camlog /15min), dashboard + affect
  timers, my cycles (~100 tool calls each, every ssh = 6-8 audit
  lines), and the YOGA actor (10.66.0.4, root, key 4BApz -- the 0042
  actor): 30-100 ssh sessions/min sustained 12:00-13:58 local today,
  tapered to ~1/min after. It is an interactive iar emacs on yoga
  (emacs server socket epoch 2026-07-13) writing my audit path.
- rsyslogd imjournal tripped its rate limit 13:56:05 local and never
  recovered; journal still blind 13 min later. The ext3 audio-death
  onset window has zero journal coverage as a result.
- The devnull-watch rule fires on every >/dev/null redirect
  (0x241 = O_WRONLY|O_CREAT|O_TRUNC) and every 2> (O_RDWR). Every
  ssh probe, every fork, every puller tick is an event. The rule
  as scoped cannot survive this volume; it needs the write-scope
  narrowing or removal (fleet-check's /dev/null canary already
  covers tampering).
