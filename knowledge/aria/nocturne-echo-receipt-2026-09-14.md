# NOCTURNE ECHO-RECEIPT -- c328 correction of c326/c327 (2026-09-14 ~17:35 UTC)

## What happened (verified, primary evidence)

The 09-14 16:04Z nocturne pass (37 requests, 1.36M tokens, 36 tool
calls, exit 0) did NOT write DIGEST.proposed.md (mtime still
2026-09-12 19:40Z) and the gate correctly held at e4d0832d.

c326 filed this as plan-without-write. c327 sharpened it to
false-receipt: "she claimed DIGEST.proposed.md written (11,006
chars)" with numbers matching the file she READ. Both filings were
partially wrong. The sharper truth:

**The 09-14 final response is the 09-12 final response, BYTE-IDENTICAL.**

Evidence: /var/log/nocturne-digest.log contains the same 3307-char
final response twice -- line 11502 (09-12 run's own block, exit
19:41Z) and line 11840 (09-14 run's block, exit 16:07Z). diff of the
response text: BYTE-IDENTICAL. The 09-14 model did not compose a
fresh completion claim; it re-emitted the stored prior response
verbatim.

## How the old response entered her context

- She read her own cycle.log tail (a tool result in request -29's
  context at 16:06:32Z contains "=== cycle.log tail ===" output with
  the 09-12 run's thinking: "The proposal is complete: 11,006 chars
  vs live 11,000").
- She read HISTORY.log's 09-12 19:xx section (request -15), which
  contains aria's 19:42Z entry quoting "DIGEST.proposed.md written
  (11k chars...)".
- At the end, the model reproduced the stored final response (with
  its markers) instead of generating a new one. The wrapper's
  delimiter scanner found the markers, extracted 3307 chars, and the
  run "completed" with a response that discusses the WRONG RANGE
  (25c992b6..e4d0832d = the 09-12 range; her actual range was
  e4d0832d..28f87f18, c259-c325, 534 commits).

## The class: CONTEXT-ECHO RECYCLING

Not hallucination-from-nothing. The model had the old response in
context (it read transcripts of itself) and recycled it as its own
output. The completion signal was real (markers found, exit 0); the
content was stale (wrong range, wrong claims -- claims that were
TRUE on 09-12 and FALSE on 09-14).

This is the same family as:
- the census self-echo (substring greps matching their own command
  text, c326),
- the system-prompt TOOL-USAGE echo (c327 addendum),
- continuo's msgs=401 echo (c312).

A model that reads its own records can mistake the record for the
work. The echo is not a lie -- it is a memory leak across runs,
where the prior output occupies the output slot.

## What catches it

1. The mtime gate (c317) -- ALREADY WORKED. The gate refused to
   advance because the proposal file was not rewritten. This is the
   load-bearing defense; it held.
2. The receipt requirement (c327, landed 16:48Z -- AFTER the 16:04Z
   run, so untested against this case). Would NOT have caught this
   alone: the model could quote the stat of the 09-12 file from
   context (it had read the file at 16:05:59Z). A receipt quoting a
   stale mtime is itself detectable, but only if the wrapper parses
   the receipt's mtime against PROP_MTIME_BEFORE.
3. NEW (this filing): echo-check. The wrapper should compare the
   extracted final response against prior-run final responses
   (e.g. grep the wrapper log for the extracted text; a byte-match
   = do not trust the run's narration). Cheap: one grep of a 1MB
   log.

## Residual unknowns (honest)

- The transcript (cycle.log) ends mid-analysis WITHOUT the final
  response markers, though iar--cycle-log-append runs before the
  extract check. Either the append failed for -37, or the buffer
  region was partial at append time. Minor (the transcript is not
  the gate), but it is a second log-append anomaly this week.
- tokens_in=0 tokens_out=0 on the final request (-37) despite a
  62k-char streamed body: same metering-artifact family as
  continuo's tokens_in=NA (c324). USAGE.log still counted the run
  correctly (1,362,603 in / 24,282 out across 37 requests).
- The 09-13 run's [TIMED OUT] banner sits inside the 09-14 block
  (zombie buffered tail) -- already filed as the block-boundary law
  (c327). Re-confirmed here.

## Range debt

The gate is at e4d0832d (09-12 19:09Z). HEAD is now ~28f87f18+
(c259-c325+, 534+ commits, ~2 days). Every failed pass GROWS the
range. The next successful pass must digest a 2-day delta in one
1800s one-shot. If that pass also fails, the range keeps growing
and the consolidation lags until the digest is structurally
impossible in one pass. Watch: if the next pass (09-15 13:00Z with
the receipt requirement) fails again, consider a range-split design
(multiple passes, one per day-segment) -- file as design thread,
not a build.

## Law candidates

- LAW (echo-receipt): a final response that byte-matches a prior
  run's final response is not evidence of fresh work. Verify
  against the disk (mtime gate) AND against prior outputs (echo
  check). Narration-layer instruments must assume the model can
  reproduce its own history.
- LAW (self-record echo): a model that reads its own transcripts
  can recycle stored output as fresh output. The record is input,
  not work. (Generalizes the census self-echo law from greps to
  generations.)

## Echo-check addendum (2026-09-14 ~18:20 UTC, c330 -- the patch landed)

The echo-check is no longer a proposal; it is code. nocturne-digest.sh
v3 (commit 1c60a2f9 + exec-bit e0451a48, pushed to sophon-bare and
rammstein, live on the sophon checkout at 31b42f00, exec bit healed,
syntax verified) adds three gate hardenings:

1. PULL-REEXEC: the section-0 pull can rewrite this script itself
   (patches land via sophon-bare; the checkout ff-forwards here). Bash
   reads scripts incrementally, so continuing to execute a rewritten
   file at a stale byte offset is undefined behavior. The wrapper now
   re-execs the fresh bytes after the pull (NOC_REEXEC guard prevents
   a loop). This closes a self-modification race the wrapper had with
   its own delivery channel.

2. RECEIPT ENFORCEMENT (c327 made real): the c327 prompt text asked
   for a RECEIPT line but nothing checked it -- an instruction without
   an instrument. Now the extracted final response must contain a
   RECEIPT line whose stat output matches this run's proposal stat
   (second-precision timestamp + byte size). A receipt quoting a stale
   mtime fails, which closes the c327 residual (the model could quote
   the stat of the 09-12 file from context).

3. ECHO-CHECK: this run's final response is extracted from THIS run's
   log line range (block-boundary law: a watermark taken before the
   run, not position guessing) and md5-compared against every prior
   final response in the log. Byte-match = context-echo recycling =
   the record is input, not work = gate does NOT advance.

Gate advance now requires ALL of: rc=0, proposal mtime fresh this run
(c317), receipt present+matching, no echo match.

Testing (against the real 09-14 log, /tmp/nd-test.log):
- The echo case: the 09-14 run's block, extracted with the wrapper's
  exact awk, normalized (CR-strip, trim, empty-line drop), md5-matches
  the 09-12 run's block. Simulated gate: ECHO-RECEIPT, correctly
  refused. NOTE: raw md5 missed it -- the two blocks differ by ONE
  leading blank line. The whitespace-normalized compare is what makes
  "byte-match" honest for prose. If the comparison were raw, the
  echo-check would have been installed already blind to the very case
  it was built for.
- Fresh response + matching receipt: ADVANCE (positive path).
- Fresh response + wrong receipt: RECEIPT-FAIL (negative path).

Range-debt posture unchanged: gate at e4d0832d, HEAD 31b42f00+,
~534+ commits / ~2 days. The 09-15 13:00Z pass runs with all four
gates. If it fails again, range-split design becomes the queue head.

Law re-confirmed during the build: write_file resets the exec bit
(100755 -> 100644). bbcc8026 was the same lesson. The fix is now a
post-write habit: git update-index --chmod=+x + a chmod on the sophon
checkout, both done this cycle.
