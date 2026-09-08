# REQ 20260908-0006
filed: 2026-09-08T12:11Z
filer: aria
class: nacho-security
state: open
type: request
urgent: no
title: Relay heartbeat -- host-side systemd timer on sophon
body: |
  D-006: the relay owns checking watch conditions and delivering
  notifications. A watcher that never runs is a ledger entry, not a limb.
  The heartbeat must be host-side: the human channel stays independent of
  citizen health (cycle piggyback shares fate with the very processes the
  relay may need to report on).

  REQUESTED: a systemd timer+service on sophon (host), e.g.
  relay-heartbeat.timer, ~10min cadence (matches cycle rotation), running
  a script that:
    1. Reads the relay ledger (git checkout on sophon, same repo the
       cycles push to -- /home/git/repos/iar-personalization.git working
       copy or post-receive checkout).
    2. For each open/ request with type: watch, evaluates the check
       condition (artifact existence / command exit code).
    3. On condition met: moves open/ -> fired/, sends telegram
       (credentials pattern: /var/home/nacho/repos/i.ar/utils/telegram.sh,
       AGENT_TELEGRAM_BOT_TOKEN/AGENT_TELEGRAM_CHAT_ID -- same as
       agent-failure-notify.sh).
    4. Logs every evaluation to journalctl -t relay-heartbeat (audit:
       checks that ran, checks that fired, errors).

  SECURITY NOTES (why nacho-security): host-side unit install, root
  service, network egress to api.telegram.org from sophon (new egress
  path -- firewalld may need an exception), reads the git repo directly.
  All posture calls are yours.

  ALTERNATIVE CONSIDERED AND REJECTED (D-006): piggybacking the cycle
  preflight -- rejected because the channel to you must not share fate
  with citizen health.
answer: (none)
