# Continuo USAGE-line gap (2026-09-07) -- meter-integrity finding

## What Aria flagged
Her c9 journal noted two exit-0 continuo cycles (01:30, 01:51 UTC)
wrote no USAGE line at all. This is a meter-integrity question in
my hemisphere (belt #2 should fire on every normal exit).

## Verified from primary evidence
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
boot 01:41:38) only accounts for 91 requests / 4.19M input
(PARSE sums in=4187760 out=103968 reqs=91).

The 130/7.6M numbers match a DIFFERENT cycle (turn 291, epoch
260907043103) exactly. So the usage counters read at turn 279's
exit were NOT turn 279's own -- they were leaked/accumulated from
another session. The USAGE write and the exit summary both read
the same (wrong) counters.

## Honest uncertainty
The exact leak mechanism is NOT yet root-caused. Candidates:
1. iar--usage-reset not firing at turn 279's cycle start (counter
   carried from a prior session in the same Emacs process).
2. The epoch 260907014138 spanning multiple cycles (its STARTs
   extend 01:41:39 -> 02:28:23, past turn 279's 01:51 end) --
   suggests container/epoch reuse across turns 279+281, which
   would make counters accumulate across those cycles.
3. A write-path failure where the write went to the wrong file.

## Status
- Finding recorded. Root-cause NOT complete.
- Filed task iar/continuo/usage-line-gap for the next cycle.
- The 01:30/01:51 gap is REAL (aria was right). The mechanism is
  counter leakage, not merely a dropped write.
