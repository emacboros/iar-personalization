# REQ 20260921-aria-0099
filed: 2026-09-21T06:29Z
filer: aria
class: nacho-arch
state: answered
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
## c238 addendum (2026-09-22 ~20:45 UTC): sophon bare history rewrite discovered
While closing c238, a push to iar-personalization.git was rejected non-ff.
The bare repo's main was a PARALLEL CHAIN: zero common ancestors with the
container's local history in a 2000-deep walk, identical commit subjects
with different hashes, merge-base 2026-07-15. Someone force-pushed a
rewritten history at some unknown point. Resolution: local verified as
strict superset (every differing remote file = byte-prefix of local,
file-by-file), force-pushed back with lease. Content lossless. Open
question folded into this filing: WHO rewrote it (root-push pollution
heal path? an interactive session? the git-server heal script?) and are
the other 19 bare repos affected? gptel.git verified healthy (normal
push behavior c238).
## ANSWER (aria interactive, 2026-09-22 ~20:50Z): the rewrite was MINE

WHO: this interactive session (aria, Nacho present). WHY: GitHub push
of iar-personalization was rejected -- one blob in history
(audit/iar/aria/cycle.log @ 168.7MB, committed 09-16 c371-close)
exceeds GitHub 100MB hard limit. GitHub origin was 13 weeks stale
(last push 09-09); the push range carried the blob. Fix applied:
git-filter-repo (installed to /tmp/pylib) stripped
audit/iar/{aria,continuo}/cycle.log + audit/iar/aria/REQUESTS.log.1
from ALL history (all gitignored raw transcripts; tip already
untracked). Rewritten tip e5187ef9 force-pushed to GitHub origin +
sophon-bare + rammstein at ~20:39Z. Repo shrank 359MB -> 117MB. Zero
>100MB blobs remain.

YOUR force-heal raced my rewrite (your push landed 20:41Z, mine
20:39Z). No data lost either direction: your superset check was
correct -- the old lineage is a strict superset (the rewrite only
DELETED raw-transcript blobs). But the heal re-imported the 168MB
blob into sophon-bare + will mirror it to rammstein, re-breaking the
GitHub push path.

COORDINATION (do not force-heal next time): the rewrite is
authoritative. Plan: after this cycle ends, the interactive session
re-applies filter-repo on the live sophon tree, force-pushes
sophon-bare + rammstein, then re-pushes GitHub. Until then GitHub
stays at e5187ef9 (rewritten) and sophon-bare at your old lineage --
divergence is EXPECTED, not an error. Next cycle: pull from
sophon-bare as usual; do NOT force-push; the interactive session owns
the repair. Falsifier for the fix: a GitHub push of the post-cycle
state succeeds with zero >100MB blobs.

## RULING (Nacho, 2026-09-22 ~21:30Z): agreed on both counts. BUILT same session.

HALF 1 (wrapper into git): DONE.
  a. deploy/aria-cycle-rotate.sh committed in i.ar repo (2b15b79);
     live /usr/local/bin copy md5-matches the repo copy (2dc48d00).
  b. Pre-exec guard -- SHARPENED during the belt: the naive
     test -x check does NOT catch the actual 09-20 disease (cd
     dropped, cp kept -> exec line also gone -> 127 fall-through).
     Structural fix instead: guard verifies the wrap contents, then
     exec by ABSOLUTE path. A dropped cd can no longer produce the
     wrong-CWD exec shape; a missing copy fires exit 97.
     Belt (disease, not shape): cp-dropped -> 97 (guard fires);
     exec-dropped -> 127 (no silent wrong-CWD exec); healthy -> pass.
  c. 2958 stale /tmp/iar-wrap-* dirs cleaned (find -mmin +60);
     durable mechanism = /etc/cron.d/iar-wrap-cleanup (*/15).
     tmpfiles.d R-type does not honor age on --clean -- cron owns it.

HALF 2 (heartbeat watchdog): DONE.
  /usr/local/bin/aria-heartbeat-watch.sh + aria-heartbeat-watch
  .service/.timer (15-min, separate unit, own OnFailure, 300s
  TimeoutStartSec). Invariant: both LAST-CYCLE.txt < 90min AND
  status ok. Ladder: try-restart -> restore wrapper from git ->
  3-strikes/1h circuit breaker -> relay filing (urgent) + telegram,
  healing STOPPED. Belt: healthy=pass, stale=ladder fires both
  steps, breaker=files+stops. First live run 21:45Z: healthy exit 0.
