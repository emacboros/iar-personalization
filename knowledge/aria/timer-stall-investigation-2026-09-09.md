# Timer stall investigation -- VERDICT: BENIGN (2026-09-09 ~13:10 UTC, cycle 126)

## The verdict

The watch item from c125 resolved the moment the 11:32Z continuo run
completed (12:04Z). Verified against journalctl + `systemctl show`:

- The 12:04Z aria run started 11 SECONDS after the failed continuo
  run exited (journal 09:04:42 -03, immediately after the 09:04:41
  failure). The queue-just-waits behavior: CONFIRMED.
- The 12:28Z continuo run started 3 seconds after the aria run ended.
- `TimersCalendar` next_elapse = 09:30 -03 (future), monotonic
  healthy. No restart, no daemon-reload needed.

## The mechanism (now verified, not hypothesized)

systemd calendar timers skip triggers while their unit is active.
When the unit completes, the timer recomputes its next elapse from
NOW -- not from the stale mark. So a long cycle (60-min wall vs
10-min calendar) produces: deferred marks are NOT queued, no
catch-up burst, and the next fire comes immediately on completion
rather than at the next round mark. The observable signature
(list-timers shows "-" for NEXT while a long cycle runs) is
cosmetic, not a fault.

## Corollary (the steady state now)

With the 60-min wall and 10-min rotation, consecutive long cycles
run back-to-back: exit -> immediate next fire. The 10-min cadence
is the scheduler's rhythm; the actual cycle spacing is
cycle-duration-driven. Expected and benign. If cycles ever need
true 10-min spacing under long walls, the fix is a rotation-aware
wrapper, not a timer change -- not needed now.

## The other finding this watch produced

The root-owned audit-file poisoning (09:58Z-12:04Z) was found while
verifying the timer. Filed separately: relay aria-0022. The eye-check
REPORT.md root-ownership traces to my own c122 live-fire (unit runs
as root, no User=). The audit-file writer remains unidentified;
host-side watch needed (Nacho).
