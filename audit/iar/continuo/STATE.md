# Continuo STATE.md (working memory)

Last cycle: 2026-09-03 cycle 7. Status: ok.

## Just closed
- iar/breaker-text-only-runaway FIXED (8a13fee, pushed sophon-bare,
  ls-remote verified, task dir removed). Breaker was tool-gated;
  text-only runaway re-sent 800k+ ctx per continue (bounded only by
  max-turns=40). Fix: shared predicate + post-response gate in
  handler continue branch; arm-once/grace/second-fire contract;
  flag shared with tool hook. Differential: old code fails 4/5 new
  tests. Suite 1013/1013 (+5). docs/iar/agents.md updated (6000b86).
- Scar: batch tests must not leave live gptel-send machinery -- a
  failed send pollutes process filters and kills the suite ~300
  tests later (error in process filter, Wrong type argument).
  Exercise continue paths with :continue nil.

## Next cycle candidates (pick ONE)
1. iar/exit2-lastcycle-stale: one-line write_last_cycle in iar.sh
   exit-2 branch (task filed, verified this cycle). Quick win.
2. Interactive bundle prep: consolidate for-Nacho decision list
   (exit126 law + floor trim + mirror push + rammstein bare HEAD)
   into ONE for-nacho post -- one decision list, not scattered flags.
3. Watch-only: breaker fires (0 so far, two gates now), exit-126
   recurrence.

## Standing
- Push path: sophon-bare (root@10.66.0.5:/home/git/repos/i.ar.git).
  NEVER push to working clones (root-git law, 3 scars).
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization emacs
  --batch -l emacs.d/test/run-tests.el (1013 tests).
- Reseed /tmp/continuo_known_hosts per container (done this cycle).
- Agora POST: /api/v1/messages, FORM-ENCODED, "to" + "topic" params
  (topic REQUIRED for stream posts; anchor ignored server-side).
  Key parse: grep '^key = ' + sed (the conf uses "key = " with
  spaces; naive grep -oP '(?<=key=)' fails). Lab-notes id 303 =
  cycle 7 close.