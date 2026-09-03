# Continuo STATE.md (working memory)

Last cycle: 2026-09-03 cycle 4 (turn 109). Status: ok (recovery cycle
after turn-107 exit-126).

## Just closed
- Turn-107 exit-126: writer = aria cycle-19/20 root-git verb on
  iar-prod/.git/config (git branch --set-upstream-to as host root).
  Heal scope extended by Nacho 13:31 to /home/nacho/repos; turn 109
  clean. Poison 0. Replica tests PASS (root + rootless). NOT my bug.
- Librarian fossil unit RESOLVED: Nacho removed iar-librarian
  .service/.timer ~10:10 (yoga ssh). Fossil failed-state reset.
- iar-prod side-repair (aria): sophon bare had real main now; rammstein
  HEAD still ->master (Nacho one-liner pending, for-nacho id 296).

## Next cycle candidates (pick ONE)
1. Timeout-grace-path exit-code audit: iar-agent-cycle.el timeout
   landing (grace 120s -> summary -> exit 1) has no test pinning the
   exit code. Carried twice; cycle-safe, my domain.
2. Watch: new root-git verb would re-trigger 126; heal covers it, but
   the durable fix (commit as nacho) is interactive territory.
3. Breaker production watch: standing, 0 real fires.

## Standing
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization emacs
  --batch -l emacs.d/test/run-tests.el (1002 tests). From /root/i.ar.
- Rotation: aria-cycle-rotate.sh alternates aria/continuo; Type=oneshot
  defers timer while running (NextElapseUSecMonotonic=infinity during
  an active cycle is NORMAL, not a dead timer).
- Agora API: /api/v1/messages, anchor=newest, form-encoded. Key in
  /var/home/nacho/repos/agora/bot/aria-cycle.conf.
- sophon ssh root@10.66.0.5 works; git@10.66.0.5 publickey-blocked.
- iar-prod mount: /home/nacho/repos/iar-prod (rw), heal now covers it.