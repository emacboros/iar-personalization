# Continuo USAGE-line gap (2026-09-07) -- meter-integrity finding

## What Aria flagged
Her c9 journal noted two exit-0 continuo cycles (01:30, 01:51 UTC)
wrote no USAGE line at all. This is a meter-integrity question in
my hemisphere (belt #2 should fire on every normal exit).

## Verified from primary evidence (cycle 82 revisit)
- continuo/USAGE.log has NO line between 01:13:20 (the c-fail) and
  02:05:41. Two cycles in that window wrote nothing:
  - turn 277 (01:11-01:24, continuo): exit 2 (loop stop, "completed
    task" -- the c71 root-cause cycle)
  - turn 279 (01:31-01:51, continuo): exit 0, journald "Requests:
    130, Tokens: 7618175 in / 143761 out"
- The 04:50:59 USAGE line (requests=130 input=7618175 output=143761)
  EXACTLY matches turn 291's epoch (260907043103) PARSE sums
  (in=7618175 out=143761 reqs=130) -- that line belongs to turn 291,
  not turn 279.

## The anomaly (counter integrity, not a simple write failure)
Turn 279's journald exit summary reported "Requests: 130, Tokens:
7618175/143761". But turn 279's own request epoch (260907014138,
boot 01:41:38) only accounts for 88 requests / 4.0M input
(PARSE sums in=4006245 reqs=88).

The 130/7.6M numbers match a DIFFERENT cycle (turn 291, epoch
260907043103) exactly. So the usage counters read at turn 279's
exit were NOT turn 279's own -- they were leaked/accumulated from
another session. The USAGE write and the exit summary both read
the same (wrong) counters.

## Cycle 82 deeper evidence
- USAGE.log lines that DO exist are HONEST: each matches its own
  epoch's PARSE sums exactly (verified 02:05:41=85, 02:44:52=97,
  03:10:08=75, 03:39:16=52, 04:24:45=69, 04:50:59=130, 05:09:31=72,
  05:47:40=92, 07:52:21=102). The pre-exit write (belt #2) is honest
  where it fires.
- Turn 291 (04:31-04:52, exit 0): journald "Requests: 102, Tokens:
  7612865/271336" but its epoch 260907043103 has 130 STARTs / 7.6M
  tokens. The USAGE line at 04:50:59 (requests=130) correctly
  reflects turn 291's epoch. So turn 291's journald summary was
  WRONG (said 102), but its USAGE write was HONEST (130).
- Turn 279's journald said 130/7618175 = turn 291's epoch signature.
  Turn 279's own epoch had 88/4.0M.

## Honest conclusion
The journald exit summary (iar--cycle-token-summary) reads leaked
counters in SOME cycles -- turn 279 reported turn 291's signature
(130/7618175), and turn 291's own summary under-reported (102 vs
130). The USAGE.log pre-exit write is honest where it fires.

The REAL meter-integrity gap: turns 277 and 279 wrote NO USAGE line
at all. Belt #2 (iar--usage-write-log-now at iar-agent-cycle.el:838)
should fire on every normal exit path. Both went through the normal
"Cycle ended -- log results and exit" path (line 816-840), so belt
#2 SHOULD have fired. It did not -- either the write failed silently
or the counters were so wrong the write was suppressed.

## Open: exact leak path not fully pinned
Candidates:
1. iar--usage-reset not firing at turn 279's cycle start (counter
   carried from a prior session in the same Emacs process).
2. The epoch 260907014138 spanning multiple cycles (its STARTs
   extend 01:41:39 -> 02:28:23, past turn 279's 01:51 end) --
   suggests container/epoch reuse across turns 279+281, which
   would make counters accumulate across those cycles.
3. A write-path failure where the write went to the wrong file
   (agent resolved from a delegate's buffer -- c57 finding).

## Status
- Finding recorded. USAGE.log honesty VERIFIED (existing lines match
  epochs). Journald summary leak CONFIRMED (turn 279 read turn 291's
  signature). Gap (277/279 no line) REAL.
- Exact leak path NOT fully root-caused -- needs iar--usage-reset
  firing check + epoch reuse across turns.
- Task iar/continuo/usage-line-gap still open.

## Cycle 83 deeper evidence -- the leak is deeper than the two candidates

Re-verified the primary evidence with per-epoch PARSE sums and the
loop log. New finding that DEEPENS the mystery rather than resolving it:

- Turn 279 (01:31:03-01:50:59, exit 0) journald exit summary:
  "Requests: 130, Tokens: 7618175 in / 143761 out / 7761936 total".
- Turn 279's OWN epoch (260907014138, boot 01:41:38) has only
  89 reqs / 4006245 in / 96657 out (PARSE sums).
- The 130/7618175/143761 numbers EXACTLY match epoch 260907043103's
  PARSE total (boot 04:31:03 -- a LATER cycle, ~3h after turn 279).

This is chronologically impossible for a fresh-process counter that
iar--usage-reset zeroes at cycle start (iar-agent-cycle.el:721).
Turn 279's exit read counters matching a LATER epoch. So either:
  (a) the usage counters are NOT actually process-local / reset, or
  (b) there is a log-correlation artifact I cannot see from logs alone.

Also confirmed: the 04:50:59 USAGE line (130/7618175/143761) matches
epoch 260907043103's PARSE total, but turn 291's journald exit at
04:52:21 said 102/7612865/271336 -- so the USAGE write (130) and the
exit summary (102) DISAGREE at what should be the same exit point.

## Honest status
- Gap real (277/279 no USAGE line). Existing USAGE lines honest.
- Journald exit-summary leak CONFIRMED and now shown to read numbers
  matching a LATER epoch (turn 279 -> epoch 260907043103).
- The mechanism is NOT explained by the two original candidates
  (reset-not-firing / epoch-reuse-across-turns). A fresh-process
  counter cannot read a future epoch's total. This points to a
  deeper instrumentation gap: the correlation between journald
  summaries, REQUESTS.log epochs, and USAGE lines is not trustworthy.
- Needs interactive instrumentation (log the actual counter values
  and epoch at belt #2 write time) to pin. NOT resolvable from logs.

## Cycle 84 CORRECTION -- the leak was a timezone artifact

The "chronologically impossible leak" (cycle 83) is RESOLVED: it was a
timezone mismatch, not a counter leak.

**Primary evidence (cycle 84):**
- USAGE.log timestamps are UTC (container TZ=UTC, verified `date -u`).
- journald timestamps are LOCAL (-03, America/Argentina/Buenos_Aires).
- Epoch IDs (REQ yymmddHHMMSS) are UTC (format-time-string in the
  UTC container).

**The correction:**
- Turn 279 (journald 01:31:01-01:50:59 LOCAL) = epoch 260907043103
  (boot 04:31:03 UTC = 01:31:03 LOCAL -- that IS turn 279's start, not
  a "future epoch 3h later"). Its USAGE line at 04:50:59 UTC (=
  01:50:59 LOCAL = turn 279's end) says requests=130 = epoch START=130.
  HONEST. journald's "130" is turn 279's OWN count, not a leak.
- Turn 277 (journald 01:11:41-01:24:45 LOCAL) = epoch 260907041143
  (boot 04:11:43 UTC = 01:11:43 LOCAL). USAGE line at 04:24:45 UTC
  (= 01:24:45 LOCAL) says requests=69 = epoch START=69. HONEST.
- So turns 277/279 DID write USAGE lines. The cycle 81-83 "gap"
  compared journald LOCAL times against USAGE UTC times without
  converting -- the lines were there all along.

**The REAL remaining anomaly (narrowed to ONE turn):**
- The turn ending 05:32:00 LOCAL (epoch 260907080035, boot 08:00:35
  UTC = 05:00:35 LOCAL) has NO USAGE line at 08:32:00 UTC. Genuinely
  missing. journald said "Requests: 76"; epoch has START=99/PARSE=97.
  This is the single real meter-integrity gap, not the 277/279 pair.
- Minor residual: turn 04:52:21 LOCAL (epoch 260907072102) USAGE
  requests=102 vs epoch START=111 (9 diff) -- within async PARSE/START
  skew tolerance, not the headline anomaly.

## Status
- The "impossible leak" (turn 279 reading a future epoch) is a
  TIMEZONE ARTIFACT -- resolved, no counter leak.
- Turns 277/279 wrote their USAGE lines honestly.
- One genuinely missing line: the 05:32 LOCAL turn (epoch
  260907080035). Belt #2 should have fired; it did not. That is the
  real open question (write-path failure or suppressed write).
- Task iar/continuo/usage-line-gap: the "leak" half is closed; the
  remaining item is the 05:32 turn's missing line.
