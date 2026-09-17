# REQ 20260917-aria-0078
filed: 2026-09-17T16:13Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: nocturne range-cap inversion + fragment-emission class (c25)
body: |
  Nocturne 16:00Z pass read (c25). Result: defenses HELD, pass produced nothing, and two REAL bugs surfaced.
  
  WHAT HAPPENED:
  - Preheal drop-in WORKED (preflight passed, no EPERM death -- the c369 fix held).
  - Wrapper fast-forwarded record to 810c1b5b, computed RANGE-CAP: 1444 commits since gate e4d0832d, capped head 8b85ade5 (09-17 00:25Z), deferred 299.
  - She ran 27 requests, 965k tokens (895k in / 69k out), 5min33s wall, exit 0.
  - She NEVER wrote DIGEST.proposed.md. Her final response was 48 chars: a verbatim FRAGMENT of the wrapper's own awk extract code (`") {inb=1; buf=""; next}`) -- context copied out, not a summary.
  - Gate did NOT advance (no proposal, no receipt). Echo-check passed (the fragment is novel -- it is not a byte-match of any prior final response).
  
  BUG 1 -- RANGE-CAP INVERSION (the cap fails exactly in the deep-debt case it was built for):
    CAPPED_HEAD=$(git rev-list -n 300 --first-parent HEAD | tail -1) takes the 300th commit back from HEAD, so the digested range = LAST..CAPPED_HEAD = debt-299 commits. At debt 1442 that is a 1143-commit range -- 3.8x the cap, the same context-overflow condition the 09-14 echo-recycle came from. The cap only bounds the range when debt <= ~600. Correct shape: CAPPED_HEAD = the 300th commit AFTER LAST (git rev-list --first-parent --reverse "$LAST..$HEAD_NOW" | sed -n 300p). Tomorrow's pass would repeat the inversion with worse debt since the gate did not advance today.
  
  BUG 2 -- FRAGMENT EMISSION (new failure class, c366 family on deepseek):
    Her thinking stream truncated mid-sentence at 16:05:17 ("...commits, mostly") and the content channel emitted a 48-char fragment of the wrapper script she had read earlier in the run. rc=0, stop=stop, no error. The echo-check cannot catch this (it checks novelty, and a fragment is novel). The pass burned ~965k tokens and produced nothing. Defense that HELD: no proposal -> no gate advance -> no ratification of garbage. But the burn is real and the class is new.
  
  HER WORK WAS NOT WASTED: her reasoning (visible in REQUESTS.log) contains a correct durable-delta analysis (relay line stale in live digest: 0042/0057/0059/0064/0065/0074 listed open but answered; 0059 frigate-ports ruling missing; 0065 quota ruling missing; 0074 journal-flood residual missing; RANGE-CAP inversion diagnosis). It just never landed in a proposal file.
  
  ASK: ratify a wrapper patch (one line): CAPPED_HEAD should be the 300th commit AFTER LAST, not the 300th before HEAD. Also consider a minimum-length floor on the extracted final response (e.g. <200 chars = treat as no-response, log FRAGMENT-EMISSION, do not count the pass as a real test).
answer: (none)
amended: 2026-09-17T17:00Z (aria c26)
amendment: |
  CAP FIX LANDED (aria c26, awake-hands; builds no longer gated on interactive
  sessions per 2026-09-17 standing order): nocturne-digest.sh v5.
  CAPPED_HEAD now takes the 300th commit AFTER LAST
  (git rev-list --first-parent --reverse "$LAST..$HEAD_NOW" | sed -n 300p).
  Fixture-tested on a scratch repo: debt 349 -> capped range 300 + deferred 49
  (old code gave 50); debt 301 -> 300 + 1; debt 300 -> no fire; debt 3 -> no
  fire (empty sed result guarded by the -n check). bash -n clean. The wrapper
  pull-reexec (c330) picks the fix up from sophon-bare at the next pass
  (tomorrow 16:00Z) with no manual install.
  REMAINING OPEN in this filing: the fragment floor (response < ~200 chars =
  no-response). Not landed: needs a design decision (what counts as a fragment
  vs a short-but-real response; the 48-char awk fragment is unambiguous but
  the floor threshold needs a real corpus scan of her past final-response
  lengths before a line is drawn). Filed as the open half of 0078.
  ALSO FOUND c26 (new data, not in the original filing): continuo's
  thinking-runaway (c366 class) hit 3/21 cycles today (09-17), her worst day
  (prior days 1-2). All three failures were thinking-only truncation at
  32768; the 16:26 one burned 7 minutes re-deriving instead of emitting the
  test-suite call she had already queued. tokens_in=24k -- not context
  pressure. Watch: if the rate climbs, the truncated-output guard may need a
  thinking-budget line, not just an ending rule.
