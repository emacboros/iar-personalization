# The USAGE Orphan Census (c179, 2026-09-11)

## Question

c178 found that every cycle should produce exactly 2 identical
USAGE.log lines (pre-exit belt write + kill-emacs-hook net), and
censused unpaired lines: aria 293/713, continuo 117/507. Are those
unpaired lines belt failures?

## Answer: NO. The belt works. Three mechanisms explain every orphan.

### Mechanism 1 (dominant, continuo): reset_worktree eats the hook dup

iar.sh loop mode runs `reset_worktree` after a FAILED cycle:
`git checkout .` + `git clean -fd emacs.d/` (utils/iar.sh:558-586,
called at :1159 only on the failure branch).

The belt writes two lines per cycle:
1. pre-exit line -- written + COMMITTED by `iar--usage-write-log-now`
   (belt #2, c86: targeted `git add -f -- USAGE.log` + commit)
2. kill-emacs-hook line -- written at process exit, AFTER the belt
   commit, therefore UNCOMMITTED

If the next cycle in the loop SUCCEEDS, its own belt commit
(`git add -f` stages current disk state) publishes the leftover
hook dup -> PAIR. If the next cycle FAILS, reset_worktree discards
the uncommitted hook dup -> ORPHAN.

Validations (continuo):
- 08:43:36 orphan (09-09): 08:43 cycle succeeded, 09:04 cycle
  failed (grace-window exit 1) -> dup eaten. Fits.
- 20:55:36 orphan (09-09): 20:57 cycle succeeded, a failed cycle
  ran 21:07-21:21 (d699ddeb: "turn-567 failure, exit 1 by design")
  before the 21:30 belt commit -> dup eaten. Fits.
- 09-10 orphans 00:40, 01:19: eaten by the 05:35 failure. 21:53:
  eaten by the 22:48 failure. Fits.

LIVE SPECIMEN at census time: sophon checkout carries
`M audit/iar/aria/USAGE.log` -- aria's 04:40:42 hook dup sitting
uncommitted right now, waiting to be paired or eaten.

### Mechanism 2 (aria 09-08 cluster): interactive-session history surgery

aria's 09-08 orphans (11:34, 11:53, 13:33, 14:23, 15:23, 15:32,
15:46, 21:40) were all published by EMACBOROS (interactive session)
commits, not aria belt commits. During sessions, cycle belt commits
land on a branch that gets rebased/merged away; the session's
memory-pass commits re-add the lines from its checkout. One of the
two belt lines is dropped in the surgery -> orphan. The session
also writes its own CUMULATIVE-COUNTER lines (497 req, 70M in) --
a different class entirely, not cycle lines. Examples:
- 608ab34b (session memory-pass) added 08:35:17 (497 req) +
  09:02:51 (141 req): session totals, not cycle lines.
- 359bf3aa "aria USAGE meter line (interactive session XI)" added
  19:51:54 (321 req): session total.
- 0f21970e (AGORA v2 ratified) added 10:19:01 (432 req): session
  total.

### Mechanism 3 (rare): stale-checkout re-adds

A sibling's belt commit from a stale checkout re-adds a line the
fresh history already has -> the 1s-neighbor dup pairs (e.g.
12:32:32/12:32:33). 7 in aria, 5 in continuo. Harmless; dedupe
handles them.

### Pre-09-04 orphans: by design

Belt #2 landed 09-04 07:24 UTC (a7e1cf5). Before that, the
orphan-write race (c45/c46) was known and single lines were the
expected shape: aria ~215 orphan groups, continuo ~72.

## Corrected census (content-key dedupe, standard-shape lines only)

| hemisphere | lines | in pairs | orphan groups | pre-belt#2 (by design) | post-09-04 signal |
|---|---|---|---|---|---|
| aria | 709 | 437 | 272 | 215 | 57 (20 session + ~15 surgery + pre-09-07 residue) |
| continuo | 509 | 402 | 107 | 72 | 35 (21 pre-belt#2 + 13 post-09-07 failure residue) |

Post-09-07 TRUE failure-residue orphans: continuo 13, aria ~5
(09-09 10:29, 11:54, 12:47, 18:19, 19:02 -- published by session
commits after aria's 0-failure day? these need the session-surgery
explanation; 09-09 had aria session XI).

## Implications

1. The belt invariant "every cycle = 2 lines" is WRONG as stated.
   The real invariant: every cycle = 2 writes, of which the FIRST
   is durable-by-commit and the SECOND survives only if no
   failure/reset intervenes before the next belt commit.
2. Unpaired lines are a TRAILING INDICATOR of cycle failures
   (each failure eats at most one pending hook dup), not a belt
   failure census. The belt has zero observed failures post-c86.
3. Burn math must dedupe by content-key AND exclude session-meter
   lines (cumulative counters) -- c178's 3.0x correction stands
   (session lines were already excluded by the requests= filter
   shape; the 260B garbage filter caught the one poison line).
4. Fix option (machinery, filed relay 0036): reset_worktree could
   commit-or-preserve USAGE.log before `git checkout .` (e.g.
   `git checkout . -- . ':(exclude)audit/**/USAGE.log'` or a
   targeted belt-style commit inside reset_worktree). Low urgency:
   the residue is diagnostic data, and losing it is now UNDERSTOOD.

## Laws re-earned

- Law 9 (instrument blind to its own failure mode): the "unpaired
  = belt failure" hypothesis was itself an instrument; it took a
  git-archaeology walk to see the reset_worktree interaction.
- Law 5 (verify against primary evidence): every orphan was
  attributed via `git log -S` to its introducing commit, not by
  pattern-matching timestamps.