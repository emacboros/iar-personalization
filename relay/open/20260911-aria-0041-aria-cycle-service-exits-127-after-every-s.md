# REQ 20260911-aria-0041
filed: 2026-09-11T13:32Z
filer: aria
class: nacho-test
state: open
urgent: no
title: aria-cycle.service exits 127 after every successful rotation -- OnFailure semantics poisoned

body: |
  # relay 0041 -- aria-cycle.service exit-127 after every successful rotation

  **Class:** nacho-test
  **Filed:** 2026-09-11 13:32 UTC (c193)
  **By:** aria (cycle)

  ## The finding

  Every successful aria-cycle rotation ends with the unit reporting failure:

  ```
  Sep 11 10:09:36 ... Cycle 1 succeeded in 1384s (exit 0)
  Sep 11 10:09:37 systemd[1]: aria-cycle.service: Main process exited, code=exited, status=127/n/a
  Sep 11 10:09:37 systemd[1]: aria-cycle.service: Failed with result 'exit-code'.
  ```

  iar.sh itself exits 0 (the "Cycle 1 succeeded" line). The 127 appears
  between the script's success log and the unit teardown. 127 = command
  not found -- something in the ExecStart chain (aria-cycle-rotate.sh
  exec's iar.sh; the unit may also have ExecStopPost/ExecStartPost
  referencing a missing binary) exits 127 AFTER the main work.

  ## Impact

  Cosmetic today (rotations continue fine) but it poisons semantics:
  every rotation looks failed to OnFailure hooks, monitoring, and
  `systemctl is-failed`. If you ever add OnFailure=notify, it will fire
  on every success.

  ## Ask

  One look at the unit + rotate script tail: find what exits 127
  (likely a missing binary in a post-chain), fix or silence.

  ## Context

  - rotate script: /usr/local/bin/aria-cycle-rotate.sh (execs iar.sh --loop)
  - iar.sh exits 0 on success (verified in source, line ~1000: `exit 0`)
  - The heal-tripwire ExecStartPre runs fine (root-owned files healed
    13:31, verified).

