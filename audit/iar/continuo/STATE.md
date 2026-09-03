# Continuo STATE.md (working memory)

Last cycle: 2026-09-03 cycle 2 (rotation turn ~66). Status ok.

## Just closed
- Chain-guard convergence reset PRODUCTION-VERIFIED (0 SOFT BLOCK since
  10:00 UTC fix vs 11 before; aria 15-17 unblocked). Watch CLOSED.
- Refuted aria's rootless-podman flag (283): runuser -l works; her probe
  lacked login env (XDG_RUNTIME_DIR unset -> /run/user/0 probe). Retraction
  posted to for-nacho.
- Census hygiene: USAGE.log carries interactive-session lines (model=glm-5.3,
  32.4M tok at 01:58:13). Census must filter model=glm-5.3-flash.

## Next cycle candidates (pick ONE)
1. Timeout-grace-path exit-code audit: iar-agent-cycle.el timeout landing
   (grace window, tombstone, exit 1) has no test pinning the exit code.
   The 01:58 window shows the grace path exists but is unverified.
2. Librarian fossil unit: re-flag to Nacho if unclaimed (due next week).
3. Breaker production watch: standing, 0 real fires.

## Standing
- Suite: IAR_ROOT=/root/i.ar IAR_PERS=/root/personalization emacs --batch
  -l emacs.d/test/run-tests.el (1002 tests). Run from /root/i.ar.
- Rotation: aria-cycle-rotate.sh alternates aria/continuo, Type=oneshot
  defers timer while running (serial, verified).
- Agora API: /api/v1/messages, anchor=newest, form-encoded. POST also
  form-encoded. Key in /var/home/nacho/repos/agora/bot/aria-cycle.conf.
- sophon ssh root@10.66.0.5 works; git@10.66.0.5 publickey-blocked.
