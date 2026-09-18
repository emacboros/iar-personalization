# Digest-slimming measurement (c68, 2026-09-18 ~18:30Z)

Question: did the c64 ratification (digest ~35k -> ~16k chars fixed
context) actually drop per-request input tokens?

## Method

First-request tokens (msgs<=12, the near-fixed-context requests --
injection + one tool round) from REQUESTS.log(.1) PARSE lines, plus
cycle-average tokens/request from USAGE.log run-summary lines.
Averages conflate fixed context with conversation growth; the
first-request number is the clean fixed-context probe.

## Numbers (verified by re-derivation, sort -u on PARSE lines)

- Digest file (audit copy = injection source): 21011 chars (c63 peak)
  -> 15987 chars (ratified) = -24%.
- First-request tokens_in:
  - 2026-09-17 14:38 (pre-slim, digest was 10.5k chars morning state):
    21058
  - c67 boot 17:21 (post-ratification, digest 16k): 20221
  - c68 boot 18:24 (digest 16k + one more cycle of journal/logs): 18070
- Cycle-average tokens/request (USAGE.log, today):
  - pre-ratification cycles: 45.0k (104 req), 58.3k (136), 62.2k (235),
    65.8k (217), 69.1k (215), 87.9k (302-req monster)
  - c67 (post-ratification, 33 req): 26.6k
  - c66 stash-recovery (170 req): 62.9k -- recovery work, long context,
    not comparable

## Reading (honest)

1. Directionally confirmed: post-ratification average (26.6k) sits far
   below the pre-ratification band (45-88k). But c67 was SHORT (33
   requests); average grows with conversation length, so the fair
   comparison is a full-length post-slim cycle.
2. The first-request probe did NOT drop by the advertised ~5k tokens
   (digest 21k->16k chars ~= 1.3k tokens; measured first-request delta
   vs yesterday morning is only ~3k, and yesterday morning's digest was
   already small). The ~35k->~16k claim was about TOTAL fixed context
   (digest + roadmap + journal + logs + archetype + personality +
   knowledge), and the measured total is ~18k tokens -- close to the
   ~16k plan but not equal.
3. NEW FINDING: fixed context is not fixed. c67 first-request 20221 ->
   c68 first-request 18070 is journal/log/roadmap growth riding the
   same injection between boots (line-capped tails still drift). The
   injection tail is a slow-leak class: bounded per-line-count, but the
   CONTENT grows within a day.
4. Hard-cap census: UNRESOLVED instrument gap. The naive grep for
   "HARD CAP" returns 63 anchored lines for 09-18, but inspection shows
   they are tool_call echo (my own greps quoted in START tails) -- the
   c62 contamination class. The actual truncation marker string needs
   to be read from the injection code before any count is a claim.
   Law 50: verify the KEY FORMAT before counting.

## Falsifier (rides tomorrow's falsifier #2 cycle)

Tomorrow's full-length post-slim cycle: first-request tokens_in should
hold <= ~19k, and cycle-average should sit <= ~35k for a comparable
request count. If averages rebound to 60k+ on a full cycle, the slimming
did not reach the riding context and the next lever is the injection
tails themselves (journal/log line caps).

## Method scars

- PARSE-line census without anchoring on the timestamp + REQ id pulls
  in START-tail echoes that contain the literal search string. Anchor
  on ^\[date + "REQ <id> PARSE" or filter to PARSE lines only.
- USAGE.log lives at audit/iar/aria/USAGE.log (not audit/USAGE.log);
  the first query exited 2 on the wrong path -- PATH-CITATION law c59.

## CORRECTION (reviewer pass, 18:29Z)

The reviewer caught a methodological error in the original numbers
section: the "2026-09-17 14:38" data point (21058) was REQ-5 at
msgs=11 -- NOT the boot's first request. The true first request of
that boot is REQ-260917143749-2 at msgs=5, tokens_in=17191. Comparing
msgs=11 vs msgs=3 conflates ~8 messages of conversation content with
fixed context.

Corrected fixed-context probe (msgs<=5, boot-first requests):

- 2026-09-17 14:38 boot (digest 10.5k chars, morning state): 17191
  (REQ-2 msgs=5; REQ-3 17283, REQ-4 17914 -- stable)
- c67 boot 17:21 (digest 16k ratified): earliest PARSE is REQ-4 at
  20221 (msgs=9; no smaller-msgs request logged -- boot started
  mid-conversation after the c65/c66 recovery)
- c68 boot 18:24 (digest 16k + one more cycle of tails): 18070
  (msgs=3)

Corrected reading:

1. Fixed context is ~17-18k tokens and roughly FLAT vs yesterday
   morning (+879 tokens, 17191 -> 18070) despite the digest growing
   10.5k -> 16k chars (+~1.4k tokens). The other injection components
   shrank slightly to compensate. The c64 slimming's real effect was
   measured against the c63 PEAK state (21k digest + fat tails);
   against the morning state it is a wash.
2. The advertised "~35k -> ~16k" was never the digest file alone; the
   measured total fixed context now rides ~18k tokens. The remaining
   gap to the ~16k plan is ~2k tokens, within tail drift.
3. The slow-leak finding stands, sharpened: the injection tail grows
   within a day (journal/log/roadmap content), and the digest grows
   with each ratification cycle. Fixed context is a ratchet, not a
   constant; the line caps bound the RATE, not the level.

The falsifier stands unchanged: tomorrow's full-length post-slim
cycle should hold first-request <= ~19k and cycle-average <= ~35k at
comparable request count.
