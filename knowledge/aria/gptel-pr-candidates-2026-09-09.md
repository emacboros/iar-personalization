# gptel fork PR candidates -- upstream-gap audit (c112, 2026-09-09)

Question: after the 0.9.9.6 merge (c956841), which of our fixes are still
fork-only, and are the failure classes they fix still LIVE upstream?

Method: for each fork-only commit (not ancestor of upstream tip 4799c80),
read the upstream file content and grep for the mechanism. A fix is a PR
candidate iff the failure class is still live upstream (not just the
commit absent).

## The six fork-only commits

| commit | fix | upstream state | PR candidate |
|---|---|---|---|
| 4c588a2 | FSM stuck at TOOL when 2+ tool calls (tool-calls-captured guard) | no guard; injects tool_calls on EVERY streaming chunk carrying them -> duplicate injection + stuck FSM | YES -- clean, small, testable |
| d8494f8 | model-output ``` breaks structural fence folding (gptel-property parity check) | parity code counts ALL fences; model backticks still break folds | YES -- small, self-contained |
| bcfd670 | degenerate tool_call sanitize (string :function, non-string :name -> silent FSM death / swallowed stream) | no sanitize; crash classes live | YES -- but touches both gptel-ollama.el + gptel.el; biggest diff |
| 7370286 | gptel-tool-p guard in include-tool-results loop (unknown-tool crash) | loop unguarded; (gptel-tool-name tool) on a non-tool signals | YES -- 3-line diff, easiest |
| 970da80 | done_reason capture in STREAMING parse (:stop-reason) | non-streaming path has it; streaming does not | YES -- 7-line diff, mirrors existing upstream pattern |
| 8715a6c | invisible-turn stub (truncated thinking-only turn -> synthesized stub) | no stub, no last-role tracking; the loop class (model re-derives cut-off reasoning every turn) live | YES -- but the most opinionated; needs the regression tests (landed af11d37, 4 green, verified this cycle) |

All six verified LIVE upstream on 2026-09-09 against 4799c80 (last
upstream commit in our merge). Fork suite: 4 invisible-turn tests green
standalone; i.ar suite 57/57 green; gptel-ollama.el byte-compiles clean.

## PR order recommendation (risk-adjusted)

1. 970da80 -- mirrors upstream's own non-streaming pattern, 7 lines.
2. 7370286 -- 3-line guard, zero behavior change for valid tools.
3. 4c588a2 -- FSM hang class, high value; needs a streaming test.
4. d8494f8 -- folding polish; needs a fence-folding test.
5. bcfd670 -- crash class; upstream may prefer a different shape
   (sanitize vs guard), so propose the mechanism, not the diff.
6. 8715a6c -- behavior change (synthesizes a message); needs the
   invisible-turn mechanism explained in the PR body. The regression
   tests are the argument.

## Process notes

- Upstream remote (git@10.66.0.1:gptel.git) is NOT fetchable from the
  cycle container (publickey denied) -- the 4799c80 analysis is from
  the local merge, which is fine: the merge brought the full upstream
  tree. If a PR is filed, fetch fresh upstream first (law 7).
- GitHub access for PRs = Nacho-class action (nacho-external) unless
  he hands over a token; filing is his call.
- The dangling commit af2889db (identical tree to bcfd670) is git-fsck
  residue from the pre-merge history rewrite -- no content lost.
