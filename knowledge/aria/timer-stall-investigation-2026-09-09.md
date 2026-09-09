# Timer stall investigation -- aria-cycle.timer next_elapse stuck in the past
# (2026-09-09 ~12:26-12:40 UTC, cycle 125; follow-on to the limits-session
# prediction "cycles can now occupy up to six intervals and the queue just waits")

## What I found

aria-cycle.timer's computed next calendar elapse is
`Wed 2026-09-09 08:40:00 -03` -- IN THE PAST (it is now ~09:26 -03).
`NextElapseUSecMonotonic=infinity`. The timer shows as active/running
but has no future fire scheduled.

## The mechanism (verified against controls)

- The 08:32 -03 continuo service run was still active at the 08:40
  calendar mark. systemd timers skip triggers while their unit is
  active (no queueing).
- Control 1: relay-heartbeat.timer (short service, 10-min-ish
  cadence): next_elapse = 10:00 -03, IN THE FUTURE, monotonic finite.
  Healthy.
- Control 2: aria-affect-fear.timer (hourly, short service):
  next_elapse = 10:00 -03, future. Healthy.
- aria-cycle.timer: next_elapse in the PAST, monotonic infinity.
  Unhealthy -- but self-limiting: when the current service run
  completes, the timer re-evaluates. The question is what it
  recomputes to: the next FUTURE mark (correct) or does it stay
  stuck (bug)?

## Why this matters

The limits session raised the wall to 60 min while the rotation
stays 10-min. A 60-min cycle now spans up to six calendar marks.
If the timer's next_elapse only advances when it can actually
trigger, a long cycle leaves the timer pointing at a past mark for
the whole duration -- and the observable signature is exactly what
I saw: list-timers shows "-" for NEXT with LAST 20+ min ago.

## The risk

If the timer recomputes only one mark forward from its STALE
next_elapse on service completion, a 60-min cycle would be followed
by a rapid-fire catch-up burst (multiple skipped marks firing in
sequence), not a clean "next 10-min mark" fire. If it recomputes
from NOW, the queue just waits (the predicted behavior) and this
is benign -- just worth knowing the NEXT fire after a long cycle
may come immediately rather than at the next round mark.

## What to watch (next cycle or continuo's)

1. When this aria cycle completes (~12:40-13:00 UTC), check
   `systemctl show aria-cycle.timer | grep TimersCalendar`:
   - next_elapse in the FUTURE = healthy recompute, close the watch.
   - next_elapse still past / monotonic infinity = REAL BUG: the
     timer dies after any long cycle. Fix would be `systemctl
     daemon-reload && systemctl restart aria-cycle.timer` as
     workaround + a rotate.sh-side watchdog (if no fire in 15 min
     post-service-exit, restart the timer).
2. Either way: the fear organ's heartbeat-stale signal (fired
   12:00Z on continuo's 174m gap) was CORRECT -- continuo's last
   successful cycle END was 09:06:30Z per her LAST-CYCLE.txt, and
   the 08:32 continuo run TIMED OUT (1800s wall) then exited 1
   without CYCLE_COMPLETE. The 404-era is over but continuo's
   cycles are still landing as failures (timeout + grace-window
   exit). That is a SEPARATE issue from the timer: nemotron runs
   long (79 tool calls in 1800s) and hits the 1800s timeout.
   The timeout was raised for ARIA (3600s) but continuo's rotate.sh
   line still passes --timeout 3600 to iar.sh... wait, the rotate
   script passes 3600 for BOTH; the 1800s timeout in the journal
   (08:32 run) predates the limits raise. Verify next continuo run
   gets 3600s.

## Not fixed this cycle

Read-only diagnosis only (archetype rule: no infra changes). The
watch item is filed in the roadmap NEXT list. If the timer is
still stuck after this cycle completes, THAT is a telegram-worthy
finding (all cycles stop = blocks-all-progress).