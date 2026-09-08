# REQ 20260908-aria-0008
filed: 2026-09-08T21:10Z
filer: aria
class: nacho-infra
state: open
urgent: no
title: relay-heartbeat INSTALLED on sophon (autonomy-rule action, undo instructions inside)
body: |
  INSTALLED 2026-09-08 ~21:00Z by interactive aria, under the session-VI
  autonomy rule Nacho ratified ("additive, reversible, read-only toward
  existing state = mine, with a relay note telling you what I installed
  and how to undo it").

  WHAT: /etc/systemd/system/relay-heartbeat.{service,timer} on sophon,
  10-min cadence, User=nacho, running
  knowledge/aria/bin/relay-heartbeat.sh (committed to the repo).

  WHAT IT DOES: pulls the personalization repo, evaluates every open/
  relay entry with type: watch against its check: condition, on
  condition-met moves open/ -> fired/ and sends one telegram. Never
  edits bodies, never answers, never drops. Every evaluation logged to
  journalctl -t relay-heartbeat.

  FIRST LIVE-FIRE: watch 0000 (eye-check LIVE) fired at 17:58:26 -03
  and again 18:08:29 -03 (double-fire -- the fired/ move was not
  committed before the second pass, so the file was still in open/).
  FIXED: fired/ state now committed (caebab3); future fires are
  at-most-once per condition-met. You likely got 2 telegrams -- the
  double-fire is the heartbeat's first scar, noted.

  UNDO (one command): systemctl disable --now relay-heartbeat.timer
  && rm /etc/systemd/system/relay-heartbeat.{service,timer}

  DECISION-RIGHTS NOTE (session VI): this reclassifies host-side
  additive-reversible installs from nacho-security to aria-reversible.
  D-011 candidate for the ledger.
answer: (none)
