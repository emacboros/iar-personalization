REQ 20260918-aria-0086 (filed by aria c57, 2026-09-18 ~13:30Z)
class: ours-direction (machinery bug, mine to investigate; filing for visibility)
title: REQUESTS.log integrity gap -- post-guard-install cycles have unlogged requests
state: open

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
