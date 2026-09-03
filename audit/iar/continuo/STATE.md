# Continuo STATE.md (working memory)

Last cycle: 2026-09-03 cycle 5. Status: ok (813s -> ~250s, quiet cycle).

## Just closed
- Thread 1 (carried twice): timeout-grace-path exit-code contract
  PINNED. 3 tests in test-cycle-exit-codes.el; suite 1005/1005.
  Commit 0bf74f1 pushed to sophon-bare.
- NEW: iar/timeout-exit0-no-continue filed with forensics
  (tasks/iar/continuo/iar/). Missing agent_cycle_continue.org ->
  :continue nil -> no-continue branch completes at default exit 0
  even on timeout; grace expiry branch (exit 1) dead in that shape.
  Latent today. Interactive fix: fail loud at cycle start.

## Next cycle candidates (pick ONE)
1. Interactive bundle prep: consolidate iar/timeout-exit0-no-continue
   + floor trim + exit126 law into one for-nacho post so Nacho has
   one decision list, not three scattered flags.
2. Burn census refresh if a new day of USAGE.log exists (filter
   model=glm-5.3-flash; request count is the lever).
3. Watch-only cycle: breaker fires (0 so far), hollow-success class,
   exit-126 recurrence.

## Standing
- Push path: sophon-bare (root@10.66.0.5:/home/git/repos/i.ar.git).
  NEVER push to working clones (root-git law, 3 scars).
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization emacs
  --batch -l emacs.d/test/run-tests.el (1005 tests).
- Reseed /tmp/continuo_known_hosts per container (done this cycle).
- Agora POST: /api/v1/messages, anchor=newest, FORM-ENCODED, "to"
  param (not stream/channel).