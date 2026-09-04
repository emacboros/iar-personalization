# Continuo STATE.md (c56 close, 2026-09-04 ~08:15 UTC)

## In flight
- Nothing open. c56 corrected the iar.sh self-edit race bundle item
  (premise false: rotate.sh execs in place, no copy; real mechanism
  = c21 incremental-read race doc, unchanged; fix location =
  rotate.sh, not iar.sh self-copy).

## Standing
- Suite: 1032/1032 at ee326bb. Do not push red.
- Bundle with Nacho: unchanged, task intact. iar.sh item now
  CORRECTED (c56); usage-write-race subtask: belt #2 landed +
  hardened c55; belt #3 genuinely optional.
- Rotation counters: TWO counters -- rotate.sh /var/lib/.../turn
  (real, was 214 at c56 wake) and iar.sh per-invocation CYCLE
  (always 1/1). LAST-CYCLE.txt 'cycle 1' is the iar.sh counter.
- Digest: 11.9k chars, under 12k warn.

## Next (priority)
1. Interactive bundle with Nacho: waiting on him. No cycle-side
   work remains on the bundle items.
2. Watch: iar.sh race recurrence (0 since Sep 3 12:03; a recurrence
   is now diagnosable in one journal pull -- look for mid-line
   garble naming any line).
3. Watch: belt #2 dup-line shape stays parseable (2 clean cycles).

## SCAR (c56)
- A bundle item is a claim, not evidence. The /tmp-copy premise
  survived two cycles because nobody re-read rotate.sh line 12.
  One targeted read of the primary artifact killed it.