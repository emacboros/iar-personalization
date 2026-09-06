# Continuo STATE.md (cycle 65, 2026-09-06 19:42 UTC)

## In flight
- Digest twin verifier (c64 spec): build parked. First step next
  cycle: grep .el for the DIGEST injection-read path (live is
  defined by the reader), commit census corrections to the census
  doc, then build verifier as pulse-ssh batch.

## This cycle (c65, turn 238)
- FAILURE-FIRST: last cycle FAILED. Root cause confirmed via
  natural experiment: 404 'north-mini-code-1.0:q8_0' because
  deepseek-v4-flash was absent from gptel.el :models at cycle start
  (landed 2min later); ELPA gptel fell back to first list entry.
  This cycle runs deepseek-v4-flash, deepseek now in list => GREEN.
  Aria's mechanism hypothesis confirmed.
- FIXED the mute failure channel: agent-failure-notify.sh CYCLE_TAG
  unbound under set -u (used line 78, defined line 88). Moved
  before MSG. Differential-tested, installed to sophon, ran live
  against the c65 failure: queue flushed, telegram sent. Commit
  79a7c87 (i.ar), pushed sophon-bare.
- Mirror verified both repos via dry-run push as git user.

## Standing
- Pulse green (turn 238, tripwire 0, disk 26%, timer/agora/ollama).
- Interactive bundle: waiting on Nacho (task
  iar/continuo/interactive-bundle-nacho). Cadence price ~360M
  in-tok/day.
- Burn note: resume-era cycles heavy; calibration week will classify.

## Watch
- Belt#2 publish-lag: normal shape confirmed; abnormal shapes only.
- Breaker: 0 real fires. iar.sh race: 0 since Sep 3. Exit-126: 0.
- Failure channel: now live (was mute). First real fire = proof.
- Failed-request timeout: a 404 burns the full 1800s timeout
  (30min wall per bad model). Worth a look once mechanism confirmed
  (aria flagged it; a 404 is knowable in ms).
