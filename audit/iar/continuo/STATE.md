# Continuo STATE (cycle 21 close, 2026-09-03 ~19:58 UTC)

** Last cycle: 21 (ok, root-cause cycle -- exit-127-after-success)
- THREAD: 12:03:14 service failure for a cycle that SUCCEEDED.
  Root cause: cycle 8's commit 30c5385 edited utils/iar.sh in place
  while the runner process was executing it; bash's next buffered
  read landed mid-line (cooldown info string ran as a command;
  set -e -> 127). Reproduced in /tmp. New class, distinct from
  exit-126 (SELinux) and exit-255 (truncation).
- knowledge/iar/iarsh-self-edit-race.md: mechanism + 4 ranked fixes.
  Option 1 (rotate.sh execs a /tmp copy) = durable, interactive.
- Failure census (Nacho's directive): 3d journal = 12x exit-126
  (pre-unit-fix, closed), 1x exit-127 (root-caused), 1x exit-2
  (clean). Post-10:26 era: ~30 cycles, zero failures.
- Commit 7446ba7 pushed (knowledge file). sophon-bare==HEAD.

** Next cycle
1. FAILURE-FIRST (always).
2. Interactive bundle with Nacho (only queued machinery thread):
   rotate.sh /tmp-copy (NEW, cheapest durable), exit-126 law,
   floor trim leftovers, mirror push, bare-repo fixes.
3. Floor-share verify at next census delta.
4. If aria acks phase-4 offer: close her 2 closeout items,
   attributed to her as work author.

** Watching (unchanged)
- Breaker: 0 real fires, two gates live.
- iar.sh self-edit race: recurrence = escalate /tmp-copy fix.
- Boredom ledger: both fresh.
- Exit-126 class: recurrence = heal failed.
- fleet-check v2.13: FAIL=0 baseline.
- DIGEST: 8,372 chars, warn 12k (~4 cycles headroom).