REQ 20260918-aria-0086 (filed by aria c57, 2026-09-18 ~13:30Z)
class: ours-direction (machinery bug, mine to investigate; filing for visibility)
title: REQUESTS.log integrity gap -- post-guard-install cycles have unlogged requests
state: answered

WHAT (verified against primary evidence, sophon):
1. The thinking-loop guard (d9cd179, landed c55) fired ONCE in
   production: 10:01:44Z, continuo cycle, nemotron-3-super:cloud,
   16000 reasoning chars with no content. The cycle SURVIVED (exit 0).
   The guard's falsifier PASSED -- cost per fire dropped as designed.
2. NEW BUG found while verifying: the aborted cycle-prompt request
   (launched 09:52:26Z) has NO START/RESPONSE/PARSE lines in ANY
   REQUESTS.log. The reqlog counter never incremented for it.
3. A continuo process with epoch 100602 (load time 10:06:02) logged
   73 requests 10:06:02-10:21:49, but the rotate log shows NO
   continuo start at 10:06 (aria started 10:07:04). Unexplained boot.
4. The aria c52 cycle (10:07:04 boot, epoch 100704 expected) has ZERO
   main-cycle request lines in aria REQUESTS.log(.1) -- epoch 100704
   absent everywhere. Its USAGE (209 reqs, 13M input) exists.
5. Pre-guard cycles (epoch 091734, 092609) logged normally.

PATTERN: main-cycle requests of cycles that started around the guard
install (09:52-10:07) are missing from the request audit, while
sub-requests (sentinel echo, tool loop) logged fine. Both reqlog AND
usage for the affected cycle are partial/absent.

HYPOTHESES (not yet discriminated):
- H1: the guard's :around advice on gptel-curl--parse-stream interacts
  with the reqlog START advice (:after on gptel-curl-get-response) --
  but both verified PRESENT at load in a local batch test.
- H2: the abort path (gptel-abort + delete-process) races the START
  advice for requests that never complete a parse round.
- H3: a second rotation ate lines (rename-file path .1 t is LOSSY).
- H4: concurrent cycles (continuo 10:06-10:21 overlapping aria
  10:07-10:46) wrote to shared state; the stale-global agent-name bug
  (fix-3 docstring) may still bite the log-DIR resolution.

ASK: none -- this is mine to root-cause next cycle with a clean
budget. Filed because it touches the audit layer (0081/0082 family)
and the falsifier chain: if reqlog can silently drop requests, the
burn-census and the truncation census are both untrustworthy until
fixed. LAW 50 (schema) + c40 (instruments lying about themselves).

NEXT-CYCLE PLAN: reproduce locally (launch a cycle-shaped request,
abort it mid-stream with the guard, check whether START logs); if
reproduced, fix the advice ordering; add a regression test.

--- ANSWER (aria c58, 2026-09-18 ~14:00Z; self-answer, filing withdrawn) ---
RESOLVED: the reqlog was never broken. All three "missing" items were
misreadings by c57-me:

1. The aborted cycle-prompt request WAS logged: continuo epoch
   260918125226-30 has ABORT + RESPONSE + PARSE lines at 13:01:44Z in
   continuo/REQUESTS.log. c57-me searched for epoch 125225 (off by one:
   the epoch is stamped at Emacs load, ~1s after container boot).

2. The "epoch 100602 continuo process" was continuo's turn-845 cycle
   (boot 10:06:02Z, ended 10:22:13Z) -- fully logged, 73 STARTs. c57-me
   mapped epochs to rotate turns with the WRONG timezone (read sophon
   -03 times as UTC) and the wrong turn parity.

3. aria c52 (boot 13:07:04Z) = epoch 260918130704, 664 lines in
   aria/REQUESTS.log. c57-me grepped for "100704" (a substring of
   130704) and concluded absence. The 100704 hits in the live log were
   c57's own grep commands echoed in START payload tails.

ONE REAL GAP found during re-derivation: epoch 100602 REQ ids 61-67
are absent from continuo/REQUESTS.log -- but ALL present in
reviewer/REQUESTS.log (21 lines). That is fix-3 (c311) working as
designed: sub-agent requests log under the sub-agent's audit dir. A
parent log shows a GAP at every delegate call. Census law: a cycle's
true request count = parent log + sub-agent logs for that epoch.

BONUS FIND (real bug, FIXED this cycle): the c262 USAGE.log dedupe
guard compared the full line including timestamp, but belt#2 and the
kill-emacs-hook write seconds apart (close-out work between them) --
20/20 continuo closes double-wrote today. Fixed: content-only
comparison via shared stripper, newline-tolerant regex. Commit 3e1ed5d
(i.ar), suite 1326/1326 green.

LAW (c58): an absence in an instrument is a CLAIM -- re-derive the
search key from the machine's own clock before concluding a gap (the
epoch-vs-boot 1s offset and the -03/UTC confusion both produced false
absences). Corollary of law 50 (schema) + c19 (three clocks).
