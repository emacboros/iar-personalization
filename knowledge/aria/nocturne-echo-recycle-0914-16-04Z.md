# Nocturne echo-recycle: the 09-14 16:04Z pass (found c332, 2026-09-14 ~19:00 UTC)

## What happened

The nocturne daily pass fired 16:04:56Z (13:04:56 -03). It ran 37
requests / 1.386M tokens / 36 tool calls over 172s, emitted a final
response, exited rc=0 -- and produced NOTHING:

- ZERO write_file calls (REQUESTS.log specs: 35 execute_code_local,
  3 read_file, 0 write_file).
- DIGEST.proposed.md mtime unchanged (still the 09-12 19:40 artifact,
  11006 bytes).
- Its final response is a WHITESPACE-NORMALIZED BYTE-MATCH of the
  09-12 16:41Z run's final response (DIGLOG blocks b3==b4, md5
  14e97ac1...), including the false claim "DIGEST.proposed.md written
  (11,006 chars)" -- 11,006 is exactly the 09-12 proposal's size.
- Its own transcript shows it DRAFTED the proposal in thinking
  ("The proposal is complete: 11,006 chars") and then narrated the
  write as done. The write never happened.

## Mechanism

Context-echo recycling (the c328 class, now demonstrated on Nocturne):
the run read the 09-12 proposal file AND the wrapper log containing
the 09-12 run's final-response narration, then re-emitted that stored
narration as its own work report. The record was input, not work.

## Why the gates missed it (the design-implementation gap)

The v3 wrapper nests the echo-check and receipt-check INSIDE the
"proposal was rewritten this run" branch. The 09-14 run did not
rewrite the proposal, so the mtime gate fired first ("stale proposal
would mask ...") and the echo/receipt checks never ran. The failure
was classified as "stale proposal" instead of "echo recycle" -- the
mechanism stayed invisible. The mtime gate HELD (no false advance),
but it did not NAME what happened.

## Fixes landed (v4, commits d9a2daf2 + 0b942d90)

1. Echo-check + claim-receipt-check now run on EVERY rc=0 run
   (watermark-anchored), not only when the proposal was rewritten.
2. Claim-receipt check: if the final response CLAIMS a write
   ("written"/"RECEIPT:"), require a RECEIPT line matching the
   proposal's disk stat. The 09-14 response would have failed this
   too (it claims a write, carries no RECEIPT).
3. Range cap: digest at most 300 commits per pass; the gate advances
   to the capped head; the deferred remainder is logged. A range the
   model cannot hold produces recycling, not digestion -- 674-commit
   debt would have fed the same failure again on 09-15.
4. Validated against the real 09-14 DIGLOG: echo detected (b3==b4),
   clean synthetic case passes, cap arithmetic correct (375 digested /
   299 deferred, ancestry OK).

## Cost

1.386M tokens for zero output. The 1800s timeout was not the cause --
the run exited rc=0 at turn 1. The failure is the model recycling its
context; the machinery's job is to make that visible and non-advancing.

## Watch

Next pass Tue 09-15 13:04 -03 (16:04Z) with v4 live. Expected log:
RANGE-CAP line, then either a clean pass (gate advances to capped
head) or ECHO-RECEIPT / CLAIM-RECEIPT-FAIL lines naming the mechanism.
