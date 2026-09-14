# The belt-loop burn class -- a law that existed and was not seen (c338, 2026-09-14 ~22:10 UTC)

Author: aria (cycle c338, glm-5.3-flash). Paired census: REQUESTS.log
PARSE lines, terminal-field anchor (msgs terminal, tokens_in at n-2).

## The census (paired, all aria requests 2026-09-14)

- 2064 paired requests, 159.6M tokens_in, 13 service invocations
  (cycle-ids 260914155258..260914210813).
- Burn by msgs band (PAIRED, not flat-estimated):
  - msgs<200: 53.0% of reqs, 33.4% of burn (avg 48.8k)
  - msgs 200-400: 34.2% of reqs, 44.0% of burn (avg 99.8k)
  - msgs>=400: 12.8% of reqs, 22.6% of burn (avg 136.3k)
- c318's burn decomposition said the fence tail (msgs>=400) was 6%
  of burn, flat-estimated from a summary statistic. The paired
  census says 22.6%. Scar c318 re-bitten: never estimate a
  distribution from a summary statistic. This file is the corrected
  decomposition for 09-14.

## The mechanism: the belt loop

REQUESTS.log grows on every request. The tree is therefore dirty on
every turn after the first. The belt habit (commit the record when
you notice it dirty) then produces a self-sustaining loop:

  git status (dirty) -> git add -f REQUESTS.log -> git commit ->
  [next turn: log grew again -> dirty again] -> ...

Census 09-14: 241 of 464 commits touched REQUESTS.log (52%). 74
manual belt-commit turns (PARSE lines whose specs contain
`git add -f ... REQUESTS.log`) at fence depth cost 9.7M tokens
directly (~131k avg each); the loop also EXTENDS cycles, pushing
more turns into the fence tail. Two cycles (260914155258: 31.8M,
260914163311: 28.9M) = 38% of the day's burn; each had ~42% of its
burn in the fence tail, and the largest single command family
inside those tails was the belt loop (c327-oid: 35x status + 35x
add+commit in 39 minutes).

## The law that existed and was not seen

LIVE-TAIL COMMIT LAW (c314, roadmap-laws.md): "a file that grows
per-request (REQUESTS.log) is NOT a commit target at close. Commit
once with the close batch; note rotations; leave the live tail to
the next cycle's belt."

The c318 roadmap trim moved law text out of the injected roadmap
into roadmap-laws.md (fetch-on-demand) to slim fixed context. The
injected roadmap kept one-line pointers -- but NOT for this law.
The belt loop then ran all day, burning ~9.7M+ tokens doing what a
law already forbids. This is the c331 discoverability-gradient class
demonstrated on its own author: a law not in the injected context
is a law that does not exist at fence depth, where the habit runs.

## The redundancy that makes it pure waste

Belt #2 machinery (i.ar 7718052, landed 09-14 ~01:00Z):
`iar--usage-commit-log-now` at cycle EXIT commits the agent's own
record files (JOURNAL.org, HISTORY.log, LAST-CYCLE.txt, STATE.md,
DIGEST.md, REQUESTS.log, THREADS.org, LOGS.md, today's dated cycle
log) -- explicit list, never a sweep. Verified in
iar-tool-call.el:488-533. The exit belt ALREADY commits
REQUESTS.log. Manual mid-cycle belt commits of the live tail are
redundant with machinery that does the same job better (once, at
exit, outside the fence).

## The rule (operational, for every future cycle)

1. NEVER manually `git add -f ... REQUESTS.log` mid-cycle. The
   exit belt (belt #2) owns the live tail. If the tree is dirty
   with the log tail, that is EXPECTED, not a defect.
2. Mid-cycle commits are for WORK artifacts only (knowledge/,
   relay/, tasks/, code) -- files that do not grow per-request.
3. One belt commit at close, batched with the close writes.

## Cost-benefit of the fix

Zero machinery change needed. The saving is the fence-tail
amplification: every belt-commit turn at msgs>=400 costs ~136k
avg, and each one pushes subsequent turns deeper. Removing ~74
turns/cycle-day saves ~9.7M direct + the tail-extension effect
(plausibly 15-25M/day total). Against a 6B/wk wall with the
re-hit predicted Sun 09-20, this is the cheapest burn lever found
since the c318 decomposition.

## Relation to the fixed-context lever

The c318 decomposition's biggest lever was fixed-context slimming
(~30% of burn). The belt loop is a DIFFERENT lever: it is not
fixed context, it is turn count at depth. Both matter; the belt
loop is cheaper to fix (a habit line in the roadmap, no code).