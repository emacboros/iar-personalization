# Continuo STATE.md (working memory)

Last cycle: 2026-09-03 cycle 9. Status: ok (in flight).

## Just closed
- Bare-repo root-push pollution VERIFIED + REFINED (aria cycle 25
  mechanism confirmed live). The 6 root-owned files in
  iar-personalization.git were cycle-8's OWN pushes (mtimes 15:02:51
  UTC; cycle 8 ended 15:03:14). Heal is REACTIVE: each root push
  sweeps the previous push's leftovers; its own housekeeping
  (multi-pack-index, info/refs) lands root-owned for the next push.
  Pollution bounded, never zero, while root pushes continue.
- Mirror leg verified end-to-end: sophon bare + rammstein mirror
  carry identical rev-parses for my pushes (b70f317, 576d5cd).
- NEW finding: 19/20 sophon bare repos HEAD->master with only main
  (dangling HEAD; empty ls-remote HEAD). rammstein inverse patchwork
  (iar-prod HEAD->master stale = for-nacho 296).
- Deliverables: knowledge/iar/bare-repo-root-push-heal.md (+addendum),
  task iar/bare-repo-root-push-fixes (continuo tree), for-nacho id
  306, lab-notes id 307. No code landed -- diagnosis cycle.

## Next cycle candidates (pick ONE)
1. Re-orient from the world (aria journal, USAGE census, breaker
   fires). No solo machinery thread is open.
2. If a breaker fire or exit-126 recurrence appears: failure-first.
3. Interactive bundle with Nacho (exit-126 law, floor trim, mirror
   push, bare-repo fixes) -- needs Nacho online.

## Standing
- Push path: sophon-bare (root@10.66.0.5:/home/git/repos/i.ar.git).
  NEVER push to working clones (root-git law, 3 scars). Pushes leave
  reactive-heal residue in the bare repo -- known, bounded, Nacho's
  to fix durably.
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization emacs
  --batch -l emacs.d/test/run-tests.el (1013 tests).
- Reseed /tmp/continuo_known_hosts per container (done cycle 9).
- Agora POST: /api/v1/messages, FORM-ENCODED, "to" + "topic" params.
  Key parse: grep '^key = ' + sed. Lab-notes id 307 = cycle 9 close.
- Loop guard chain-walk warning is live and correct: batch journalctl
  probes into ONE ssh call, never page windows.