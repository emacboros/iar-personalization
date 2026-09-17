# Journal flood 09-17 00:05-00:10 local -- the suite as audit producer

## What happened

imjournal rate-limited at 00:05:58 local (dropped 24022 messages by
00:13:44, "20000 allowed within 600 seconds"). Journal volume
00:05-00:10 local: ~25k lines, 90% audit. The 0074 residual flag
predicted "a yoga-class ssh actor" would trip the limit. The actor
was me -- but not via ssh probing.

## The forensic chain (proctitle method, c372 playbook)

1. Journal per-minute counts: spike 00:05 (11165), decay through
   00:10. Top comm: emacs (2689 events), sh (1734), git (1503).
2. Audit logs rotate at 8MB; window spanned audit.log.2/.1. TZ trap:
   audit.log line dates are LOCAL -03; the epoch in msg=audit(...) is
   UTC. Convert epochs, don't trust the date prefix.
3. devnull-watch events per minute: 2093 at 00:05, ~200/min steady
   state. Top writers: emacs pid 1605730, git pid 1605729.
4. Event 5315465: CWD=/root/i.ar/emacs.d, PROCTITLE decodes to
   `emacs --batch -L .../gptel-20260826.2228 -L test -l
   test/run-tests.el --eval (ert-run-tests-batch "fixture-h...)`.
5. Parent pid 1605729 = same emacs (self-fork for subprocess).
   Grandparent = crun proctitle, container 6f57609fdb3cff2d (gone --
   rotation containers are ephemeral).
6. Rotation identity: aria-cycle-rotate turn 750 = agent aria,
   00:02:29-00:10:34 local. The 00:05:48 fixture-h test run is inside
   that window. My own c379 cycle ran the pin test.

## Root cause

The c379 fixture-hygiene pin test (and every full-suite run) does
hundreds of file operations under the -w aria-audit watched paths
(audit/, .git/) plus ~200 /dev/null write-opens per minute (Emacs
stderr redirections). Every op is an audit event. One suite run =
~25k audit lines in 5 minutes = imjournal rate limit trip.

## What is true now

- One-cycle event, not standing: rotations 751/752 ran no suite;
  steady state ~200 audit events/min.
- The tripwire is working correctly; the suite is just loud.
- Structural fix (imjournal rate limit / audit exclusion from
  imjournal) remains relay 0074, Nacho's call.
- Suite cadence is already right: runs on builds, not per cycle.

## Laws

- PROCTITLE-CHAIN LAW (reaffirmed): for "who did this" on sophon,
  audit PROCTITLE + CWD + ppid chain is ground truth. Decode with
  python bytes.fromhex (xxd not installed).
- TZ TRAP (audit edition): audit.log date prefixes are LOCAL; the
  audit( epoch is UTC. Always convert the epoch.
- ausearch with --raw on a 10-min window can hang (600s timeout
  killed one call); direct awk on audit.log files is the fast path.
