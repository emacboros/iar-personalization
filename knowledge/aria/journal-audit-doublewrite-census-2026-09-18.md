# JOURNAL-AUDIT DOUBLE-WRITE CENSUS (2026-09-18, aria c78)

Follow-up to relay 0087 (JOURNAL-BLIND, c77). Tonight's census
re-measured the flood with proper epoch extraction and found the
STRUCTURAL cause, which changes the 0087 recommendation.

## The headline

The journal is now an AUDIT MIRROR. Measured 20:30-20:41 local
(-03), 10-min window:

- journal total: ~3067 lines/min
- journal audit-source (`-t audit`): ~2961 lines/min = ~97%
- imjournal rate limit: 2000/min (default 20000/600s)
- drop events tonight: 4 (15912, 476, 1184, 1299 messages lost,
  19:44 through 20:34 local)

The journal is drowning in our own audit events. rsyslog's imjournal
chokes on a feed that is ~97% audit.

## Where the audit journal lines come from

Keyed SYSCALL lines per 10min: devnull-watch 4447, aria-audit 2223.
Each audit event = ~4 journal lines (SYSCALL + PATH + CWD +
PROCTITLE); only the SYSCALL line carries key=. So:

- devnull-watch: ~435 events/min -> ~1740 journal lines/min
- aria-audit: ~222 events/min -> ~890 journal lines/min
- remainder: unkeyed audit plumbing (CONFIG_CHANGE, SERVICE_*,
  CWD/PATH/PROCTITLE continuations)

Native /var/log/audit/audit.log is healthy and complete (7.7MB,
live, rotating ~16min at current volume). The journal copy is
REDUNDANT WEIGHT. Nothing reads audit from the journal; the
fleet-check JOURNAL-BLIND detector reads the drop MARKERS.

## Who opens /dev/null (the rule's real composition)

16-min window (audit.log.1, 20:23-20:39 local), devnull-watch
SYSCALL events by comm:

git 1078, bash 925, frigate.recordi 532, emacs 531, awk 432,
sshd-session 177, sshd-auth 118, ssh 80, nic-sampler 48, curl 36.

uid split: 1000 (nacho) 11387, 0 (root) 6201, unattributed 2485,
1002 522. The c77 story ("root-bash cron redirects") was HALF the
picture: nacho-uid processes (git, emacs, frigate) out-number root
~2:1. The rule watches EVERYONE's /dev/null, not root's.

Frigate detail: frigate.recording_manager + camera maintainer
(python3, pid 439245, up since Sep 16 15:48) opens /dev/null at
32/min STEADY = 8 cameras x 1 open/15s. Frigate's own plumbing
(redirecting child output), not a fault. Largest single steady
contributor. Bursty contributors: git (618/min in one minute during
a push burst), bash/emacs riding cycle phases.

Steady-state devnull rate: ~250-260 events/min (audit.log.1 window
257/min; .2 window 239/min; .3 206/min; .4 251/min). The c77
"700-1800/min" was BURST peaks riding this ~250/min floor. The
09-17 "178/min" was a quiet-window sample (c43 census-timing, third
sighting of the same scar).

## What this changes about relay 0087

Original rec: remove the devnull-watch rule (canary check is the
primary tamper detector). The census CONFIRMS the rec but shows it
is INSUFFICIENT:

- Removing the rule drops journal audit flow to ~1200/min. Under
  the 2000 limit, but only ~40% headroom. aria-audit growth or a
  busy git day re-floods it.
- The structural fix is to stop the audit->journal duplication
  entirely (disable the audisp journal plugin / journald audit
  forwarding -- one config line) and let audit live ONLY in
  /var/log/audit/audit.log, where it already lands natively and
  completely.

REVISED RECOMMENDATION for 0087: do BOTH.
1. Remove the devnull-watch rule (belt that strangles; canary is
   primary).
2. Exclude audit from imjournal (structural; makes the journal a
   journal again).

Option 2 alone also fixes the flood, but leaves the rule generating
250 events/min of noise in audit.log for zero marginal value.

## Instrument scars (mine, tonight)

1. FAKE-CLEAN CENSUS: first rate query compared `awk '{print $1+0}'`
   against an epoch cutoff -- but $1 is "type=PATH", so every row
   failed the comparison and returned 0. Law 50 (verify COLUMN)
   caught it because the total was 0 while the file was visibly
   hot. The epoch lives in msg=audit(...), not column 1. Census
   source law (c294-97) extends: enumerate the FIELD, not just the
   source.
2. exit=45 is an FD NUMBER, not an exit code: openat's return value
   in the SYSCALL record. I briefly narrated "exit codes 45" --
   the field is `exit=` but its SEMANTIC is return-value/fd for
   syscall=257. Schema law applies to field semantics, not just
   names.
3. frigate attribution: first pass said "frigate.recordi 532" --
   the comm is the recording_manager's PARENT (camera maintainer,
   python3) whose children include recording_manager. ppid census
   confirmed: all 532 events carry ppid=439245 (the maintainer).
   Classify by process TREE, not by comm string alone.

## Falsifiers

- If the rule is removed and the duplication stopped, JOURNAL-BLIND
  should stay silent for 48h including one continuo marathon.
- If only the rule is removed, watch for the next flood with
  aria-audit growth (predicted headroom ~40%).
- frigate maintainer 32/min: if it ever goes to 0, a frigate
  component died; if it doubles, a 9th stream appeared. Cheap
  standing signal.