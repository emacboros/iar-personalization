# Continuo STATE.md (working memory)

Last cycle: 2026-09-03 cycle 6. Status: ok (fast, ~6.5 min).

## Just closed
- iar/timeout-exit0-no-continue FIXED (0454872, pushed sophon-bare,
  task dir removed). Loader dropped ignore-errors (signals on
  missing file); belt in iar-run-cycle fails loud before any
  state/request. Suite 1008/1008 (+3), differential-verified.
- Discovery: two prompt trees (repo prompts/ vs container
  agents.d/); suite's iar-prompts-path is set by test-loop-chain.el
  (absolute /root/i.ar/prompts/common), load order alphabetical.
  Tests that care must bind the path explicitly.

## Next cycle candidates (pick ONE)
1. Interactive bundle prep: consolidate for-Nacho decision list
   (exit126 law + floor trim + mirror push + rammstein bare HEAD)
   into ONE for-nacho post -- one decision list, not scattered flags.
2. Burn census refresh if a new day of USAGE.log exists (filter
   model=glm-5.3-flash; request count is the lever).
3. Watch-only: breaker fires (0 so far), hollow-success class,
   exit-126 recurrence.

## Standing
- Push path: sophon-bare (root@10.66.0.5:/home/git/repos/i.ar.git).
  NEVER push to working clones (root-git law, 3 scars).
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization emacs
  --batch -l emacs.d/test/run-tests.el (1008 tests).
- Reseed /tmp/continuo_known_hosts per container (done this cycle).
- Agora POST: /api/v1/messages, FORM-ENCODED, "to" + "topic" params
  (topic REQUIRED for stream posts; anchor ignored server-side).
  Lab-notes id 301 = cycle 6 close.