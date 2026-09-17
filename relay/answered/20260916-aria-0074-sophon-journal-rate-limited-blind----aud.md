# REQ 20260916-aria-0074
filed: 2026-09-16T17:03Z
filer: aria
class: nacho-security
state: answered
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

answer: |
  OPTION 1 CHOSEN 2026-09-16 (interactive session, Nacho): scope the
  rule to write-opens only. Landed live on sophon + in ansible.

  EXECUTED (2026-09-16 ~17:26-20:37Z):
  - /etc/audit/rules.d/devnull.rules: -p wa -> -p w; augenrules --load
    (the old live rule had to be deleted first: augenrules --load
    re-adds the merged set and errors "Rule exists" on a live
    conflicting rule; auditctl -W then --load then direct add).
  - VERIFIED LIVE: (a) pure read-open (python3 open("r"), bash
    exec 4</dev/null) logs NOTHING; (b) write-open (echo >/dev/null,
    exec 5>/dev/null) logs; (c) rsyslog recovered -- 0 drop markers
    since the change, journal receives logger() markers immediately.
  - VOLUME DECOMPOSITION (correction to the filing's numbers): the
    flood-window devnull rate was ~83 events/min average with a 252/min
    peak (20:00Z bucket 2525/10min) -- the "~1500/min" in the filing
    was JOURNAL LINES (each audit event emits ~4-6 journal records:
    SYSCALL+PATH+CWD+PROCTITLE), not audit events. Flood window total:
    326k journal lines in 2h = 2718 lines/min vs the imjournal limit
    20000/600s = 2000 lines/min. Post-change steady state: ~1782
    lines/min INCLUDING my own probe session; devnull events now
    ~178/min (all write-mode: 0x241 redirects, 0x80002/0x2 RW, all
    O_WRONLY/O_RDWR -- the rule is correctly scoped; read-opens
    (O_RDONLY) count ZERO in the post-change window).
  - RESIDUAL MARGIN NOTE: steady-state journal flow is ~2000 lines/min
    -- AT the imjournal limit even post-fix. The devnull write-opens
    are ~178/min (frigate recording_manager 31/min + my cycles + the
    house pullers); aria-audit (my own session writing the audit tree)
    is ~330 events/min and is now the DOMINANT audit source. If a
    yoga-class actor (30-100 ssh/min) returns, the limit trips again
    -- the structural fix is raising imjournal's rate limit or
    excluding audit from imjournal, which I did NOT touch (rsyslog
    config is shared infra, your call if you want it).
  - ANSIBLE: roles/base/tasks/main.yml + handlers (reload audit rules
    via augenrules --load) -- commit b0faad3, pushed rammstein +
    sophon-bare. Live sophon file matches the ansible content
    byte-for-byte (diff-verified). Note: the ansible task will fire
    "reload audit rules" on next base.yml run even though the file is
    already correct (no idempotence on notify) -- harmless, augenrules
    --load is idempotent.
  - The journal-blind guard (roadmap item 4, fleet-check greps the
    "begin to drop" marker) is still MY build, next cycle.

## AMENDMENT (aria c380, 2026-09-17 ~03:40Z): THE PREDICTED ACTOR APPEARED, AND IT WAS THE SUITE
The 00:05-00:10 local spike (25k audit lines, imjournal dropped 24022
msgs) was root-caused via audit proctitle chain: MY OWN rotation-750
cycle running the fixture-hygiene ERT test at 00:05:48 (emacs batch +
git + sh file ops under the -w aria-audit watches; ~200 devnull-watch
events/min steady, 2093 in the spike minute). One-cycle event --
rotations 751/752 ran no suite; steady state ~200/min. The structural
fix (imjournal rate limit / audit exclusion from imjournal) is
unchanged and still your call; the amendment only names the trigger.
Forensics: knowledge/aria/journal-flood-suite-forensics-2026-09-17.md.
