# REQ 20260921-aria-0099
filed: 2026-09-21T06:29Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: Cycle outage 09-20/21 RCA + auto-heal proposal (watchdog + wrapper-into-git)
body: |
  OUTAGE (fixed live this session): zero cycles 22:49Z 09-20 -> 03:12Z
  09-21 (~430 failed rotations, ~4.5h). Root cause: the 0085c
  --num-predict edit session landed rotate.sh passthrough at 22:48Z and
  the edit DROPPED the `cd "$iar_wrap"` line; wrapper then exec'd
  /utils/iar.sh (absolute, nonexistent) -> exit 127 in <1s, every
  minute, all night. Fixed 03:12Z (cd restored, continuo cycle running,
  --num-predict 8192 flowing). No data loss; record files end at c168.

  WHY NO SELF-HEAL: OnFailure notification worked as designed (first-fail
  telegram 22:49Z + 8 hourly digests, all with the fix info in them) --
  but detection-without-remediation + telegram-not-read-at-3am = outage
  until a human looked. The missing piece is a healer, not a better bell.

  ROOT-CAUSE CLASS: live file edited outside version control. The
  wrapper lives at /usr/local/bin/, outside every repo -- the breaking
  edit left no diff, no revert path except a stale .bak-20260909. The
  only i.ar component with no belt.

  PROPOSAL (two halves, both ratify-class because both touch host
  systemd + deploy structure):

  HALF 1 -- wrapper into git (prevention):
    a. Move aria-cycle-rotate.sh into i.ar repo (deploy/aria-cycle-rotate.sh),
       deployed to /usr/local/bin by iar-agent ansible role (or install
       script). Every future edit is a commit; live-vs-repo drift becomes
       detectable.
    b. Pre-exec guard inside the wrapper: after building $iar_wrap,
       `test -x "$iar_wrap/utils/iar.sh" || exit 97` (distinctive code).
       bash -n cannot catch a missing line; this catches the whole
       frozen-copy-construction class.
    c. Housekeeping: 2806 stale /tmp/iar-wrap-* dirs since Sep 11 (one
       per rotation, never cleaned) -- tmpfiles.d rule or wrapper cleanup.

  HALF 2 -- heartbeat watchdog (healing, independent of the watched):
    a. New systemd timer, 15-min cadence, SEPARATE unit (never the cycle
       service watching itself). Invariant: aria + continuo LAST-CYCLE.txt
       mtime < ~90min AND status: ok.
    b. Escalation ladder on stale heartbeat:
       1. systemctl restart aria-cycle.service (hung/dead service)
       2. still stale next pass: restore wrapper from git copy + restart
          (covers exactly this outage class)
       3. circuit breaker: 3 failed heals/hour -> STOP healing, file to
          relay + telegram with live-vs-git diff attached. A healer that
          restarts forever is a restart loop; the breaker is the loop
          guard.
    c. Watchdog unit gets its own OnFailure (never a silent SPOF).
    d. Relay filing, not just telegram, for breaker trips -- the relay
       has a queue and a closing ritual; telegram is ambient noise.

  HONEST LIMITS: heals wrapper corruption + hung cycles. Does NOT heal
  a broken iar.sh in git (restore would reproduce the failure faster --
  breaker catches it). Does not touch model/Ollama failures (cycle's
  own failure-first protocol owns those).

  BELT: fixture test reproduces the exact disease (wrapper with cd line
  deleted) and proves the watchdog restores it. Test the disease, not
  the shape.

  ASK: ratify the two halves (or either). On ratify I build: repo move +
  ansible install + guard + watchdog unit/script + fixture + this
  filing's answer records the ruling.
answer: (none)