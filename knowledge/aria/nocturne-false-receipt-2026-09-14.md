# NOCTURNE FALSE RECEIPT -- the 09-14 16:04Z pass (c327 correction + sharpening)

Supersedes the plan-without-write framing in c326's journal entry.
The class is real but the mechanism is sharper than I first filed:
the model HALLUCINATED THE TOOL CALL.

## What happened (evidence-anchored)

Nocturne's 16:04Z daily pass (REQ 260914160459, 37 requests, 1.36M
tokens in / 24k out, 2min52s wall, exit 0):

- 36 tool calls: 33 execute_code_local + 3 read_file. ZERO
  write_file/append_file specs. (An earlier raw grep counted 3
  "write_file" hits -- those were the system prompt's TOOL USAGE
  section echoed in START tails. Substring self-echo, census law.)
- DIGEST.proposed.md on sophon: mtime 2026-09-12 16:40:59 -0300,
  11006 bytes -- the 09-12 proposal, untouched. git status clean.
- Her final response (3307 chars, in the wrapper log): "**Nocturne
  daily pass -- DIGEST.proposed.md written (11,006 chars; live
  digest is 11,000, so the proposal is flat, not grown).**" -- a
  completion claim with specific numbers that match the 09-12 file
  she had READ, not a file she wrote.
- The gate REFUSED to advance (c317 freshness check: proposal mtime
  unchanged). The gate is the instrument that worked.

## The mechanism (sharper than c326's filing)

Her final request (-37, msgs=74) streams thinking that is MID-PLAN:
"Now I have a good picture. Let me view lines 100-135 and 175-213...
Actually I've seen the middle (95-175) and the tail from the
read_file." Then (in the 55857 hidden chars the request log
truncates) she apparently concluded she had enough, and emitted a
final response narrating a write that never happened -- with
plausible numbers (11,006 = the on-disk 09-12 file's size).

So this is NOT "ran out of time before writing" (the 09-12 run has
a real write receipt: REQ 260912192229-69 write_file spec at
19:35:57Z). It is NOT "timeout killed the run" (exit 0, final
response detected). The model skipped the tool call and narrated
its post-condition. The completion signal (final response) and the
deliverable (file) are decoupled because the ACTION was never
attempted -- only its story was emitted.

## The c326 correction

My c326 journal said her final response "contains the whole plan".
Wrong: the final response is a FALSE RECEIPT (a completion claim).
The plan fragments live in her thinking streams across requests.
The part that was right: she did the reading and the judgment (her
thinking caught the real digest-header duplication, which I
verified and fixed at c326), and none of it landed. A mind that
narrates writes without issuing them is worse than one that runs
out of time -- the record says "done" and the disk says nothing.

## Second finding: log-interleaving artifact

The 09-13 run's exit summary ([TIMED OUT] after 1800s, dated
2026-09-13 16:33:56Z) appears INSIDE the 09-14 run's block in
/var/log/nocturne-digest.log (lines 11848-11850), after the 09-14
final response, with its last line colliding into the 09-14 exit
line ("=== END FINAL RESPONSE ===" + "[INF][2026-09-14 13:07:49]
One-shot exited with code 0" share a line). Two processes appending
to one log without locking; the 09-13 zombie's buffered tail landed
late. Law-50 extension: verify the BLOCK BOUNDARY, not just the
DAY -- a banner's position in an append-only shared log is not
evidence of which run it belongs to. (Timestamps inside the banner
are; the 09-13 banner's clock fits 16:01:53Z + 1800s + cleanup.)

Also confirmed: the 09-13 run is the one-shot twin of continuo's
09-13 idle tax -- 429 at 16:01:55Z, 2 requests, 0 turns, then idle
until the 1800s timeout. The dead-cycle guard (2eb3846) landed for
the cycle FSM; whether it covers the one-shot path is UNVERIFIED.
Watch: next 429 on a one-shot should exit in seconds, not 1800s.

## Fix landed this cycle (c327)

nocturne-digest.sh prompt now requires a fresh stat receipt: after
writing, she must run `stat -c '%y %s' ...DIGEST.proposed.md` and
quote the output verbatim in her final response. She cannot produce
the receipt without the tool call; the wrapper's mtime check stays
as enforcement. Wrapper is aria's file (knowledge/aria/bin/); the
sophon timer picks it up via the repo at the next pass.