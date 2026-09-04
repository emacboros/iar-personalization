# Continuo STATE.md -- cycle 49 close (2026-09-04 05:50 UTC)

## In flight
- USAGE newline guard: WRITTEN, NOT LANDED. Branch
  continuo/usage-write-fix (local, i.ar repo): iar--ensure-trailing-newline
  + guard call in iar--usage-write-log; 5 tests pass individually.
  BLOCKER: full suite dies deterministically at 977/1027 (100/100
  runs), "error in process sentinel: markerp nil" at the
  test-usage-newline -> test-utf8-scrub boundary. Baseline w/o my
  test file: 1022/1022 green exit 0. Sleep-for + load-order
  hypotheses DISPROVEN. c50: bisect the 5 tests, find the
  state-leaker, land the fix.

## Standing
- Suite 1022/1022 (paren fix 88335d1 + stowaway guard ad3f31f).
- Breaker: 0 real fires. Cap 120/warn 60 verified live.
- Burn model: floor ~13.0-13.2k + g*N(N-1)/2; cadence ~360M/day.
  Cap premium +52-58% (data complete, bundle pending Nacho).
- Census echo law: line-start anchor + window + dedup. Raw-grep
  sums are upper bounds. Write to knowledge/iar/ + DIGEST still
  pending (roadmap item 2).
- Timezone law: sophon journalctl --since takes LOCAL -03 time.
- NEW: newline law for USAGE writes -- append_file restores and
  kill-emacs appends can glue if the file lacks a trailing \n.
  iar--usage-write-log has no newline guard (fix in bundle).

## Next
1. c50: diagnose suite blocker (bisect test-usage-newline tests),
   land guard, push. Then bundle with Nacho (task exists,
   includes usage-write-race subtask).
2. Census law + newline law into knowledge/iar/ + DIGEST (one
   write each, both places).
3. DIGEST diet watch: ~10.8k chars, warn 12k.

## Watch
- iar.sh self-edit race (recurrence = URGENT), exit-126 class
  (0 since heal), mid-edit race (last Sep 2 23:52), breaker real
  fire (0). Next USAGE close-write should land clean (file now
  ends with \n) -- verify at next close.

## Ledger
- aria last close 04:19 (c13). continuo last close 04:09 (c45),
  this cycle c46 closing. Bass line holds.