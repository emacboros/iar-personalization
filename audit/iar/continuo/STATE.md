# Continuo STATE.md -- cycle 44 close (2026-09-04 03:51 UTC)

## In flight
- MISSING USAGE LINE (epoch 022143 = c40): attribution FIXED this
  cycle (was labeled c41 in c43's records). c40 exited CLEAN per
  sophon journal (131 tool calls, exit 0, 715s). Timeout-kill
  hypothesis DEAD. Leading hypothesis: iar--usage-write-log
  (kill-emacs-hook, iar-tool-call.el:214) resolves agent/project
  from current-buffer at exit time; wrong context -> line lands in
  audit/iar/unknown/ or audit/nil/ or dies silently.
  NEXT CYCLE FIRST CALL (one compound grep):
    grep -rn "requests=13[0-9]" /root/personalization/audit/iar/*/USAGE.log
    grep -rn "2026-09-04 02:33" /root/personalization/audit/iar/*/USAGE.log
    ls /root/personalization/audit/iar/
  If found elsewhere -> fix resolution (bind agent/project at cycle
  start). If not -> write failed silently; check hook ordering.

## Standing
- Suite 1022/1022 (paren fix 88335d1 + stowaway guard ad3f31f live).
- Breaker: 0 real fires. Cap 120/warn 60 verified live.
- Burn model: floor ~13.0-13.2k + g*N(N-1)/2; cadence ~360M/day.
  Cap premium +52-58% (data complete, bundle pending Nacho).
- Census echo law REFINED: anchor "REQ <epoch>-N PARSE" at LINE
  START (echo lines carry their own epoch id -> excluded
  structurally). Raw-grep sums are upper bounds.
- Timezone law: sophon journalctl --since takes LOCAL -03 time.
  UTC-shaped windows = vacuous "No entries". A vacuous result is an
  answer: your window is wrong. Check the clock before the 10th
  window.

## Next
1. USAGE-line grep (above) -> root-cause -> fix -> suite -> push.
2. Census law into knowledge/iar/ + DIGEST (one write, both).
3. Lab-notes close post (deferred from c44, cap).
4. Interactive bundle items: all Nacho's call, task exists.

## Watch
- iar.sh self-edit race (recurrence = URGENT), exit-126 class
  (0 since heal), mid-edit race (last Sep 2 23:52), DIGEST ~10.8k
  chars (warn 12k).