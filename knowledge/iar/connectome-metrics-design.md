#+TITLE: The i.ar Connectome -- metrics design (2026-09-08, session VIII)

Origin: Nacho's HCP proposal (session VII), resolved to "borrow the
instruments, not the brain". This doc is the design session output:
what we measure, what's buildable now, what needs log-format changes,
and what the graph's unit should be. Nacho's framing in this session:
"in reality it's just more and better metrics for agora/iar in
general" -- the connectome is the generalization of the instrument
family (census, census-window, rage-trend), not a new science project.

* THE DATASET (verified this session, supersedes the "11.9k lines" figure)

The connectome dataset is ~64k tool_call lines, SPLIT across hosts:

| file | range | lines | notes |
|------+-------+-------+-------|
| container audit/audit.log | 08-20 -> now | ~12.5k | interactive + mirror + old cycles |
| sophon audit/audit.log.1 | 08-30 -> 09-07 | ~43.8k | cycles (aria 23.5k, continuo 12.3k) |
| sophon audit/audit.log | 09-07 -> now | ~10k | current cycles |

CRITICAL: both audit.log files are GITIGNORED and never synced. The
census scripts (tool-census-v3) glob ONE repo root -- single-host
blind spot, live since v1. Every census to date has seen at most half
the data. This is the single-host blind-spot scar (c-series) wearing
a new coat: "11.9k lines" was never the population; it was one
hemisphere.

Agent-name quality: aria 9634+5123+23470, continuo 2794+12253, plus
mirror 1076, convagent 651, bessie 129, agent-assistant 155, nil 4592
(08-30/31 pre-fix window), unknown 484. The nil window is bounded and
known; unknown/convagent/bessie are test-era noise.

* WHAT'S ALREADY LOGGED (the good news)

Per tool_call line: timestamp, agent, tool name, status
(success/error), result_len. Plus per-tool args detail:
- write_file/append_file: path= (FULL path -- file-touch graph for
  WRITES is already buildable)
- execute_code_local/remote: cmd= (TRUNCATED at 200 chars -- the
  200-char truncation is the audit's own cap)
- git_commit: repo=, msg=

REQUESTS.log PARSE lines (per agent, per request): FULL tool specs
with args (capped 300 chars/arg, 1000 total, omission marker honest),
tokens_in, tokens_out, stop reason, error. 1911 aria + 1042 continuo
PARSE lines current + .1 rotations. tokens_in/out are COMPLETE here
(the c33 instrument-bias finding is why PARSE carries them).

So: file-touch graph (write side) = buildable TODAY. Tool co-firing
= buildable TODAY. n-gram motifs = buildable TODAY. Token economics
per call = buildable TODAY from REQUESTS.log.

* THE GAPS (verified, ranked by cost-to-fix)

1. read_file/list_directory/read_knowledge log NO path (331+91+30
   calls in local log alone). The READ-side file-touch graph -- half
   the org connectome -- is unbuildable. FIX: one pcase branch in
   iar--audit-log-tool-call-with-agent (iar-audit-log.el): add
   ("read_file" (plist-get args :filepath)) etc. Args ARE in the
   tool-call struct (verified: write_file's :filepath works; read_file's
   arg is named "filepath", list_directory's is "path", read_knowledge's
   is "path"). One-line-per-tool format change, .el work, interactive.
2. Non-zero exits are INVISIBLE: iar--audit-log-tool-call-with-agent
   marks status=success unless result starts "Error:" -- but
   execute_code_local failures return "Command exited with code N"
   text, not "Error:". 9713 exec calls, 0 logged as error, 28 errors
   total all from fs tools. Worse: iar--audit-log-exec (which logs
   exit=N properly) is DEFINED AND TESTED but NEVER CALLED -- a dead
   instrument (the scar class: instruments lying about themselves).
   FIX: wire iar--audit-log-exec into the exec path, or add the
   "Command exited" prefix check to the status logic.
3. delegate lineage: 2 delegate calls total, no args detail (not in
   the pcase). Retainers (D-010) will multiply delegate traffic --
   lineage ids (parent-agent, depth) become load-bearing then.
   FIX: add delegate branch with task/agent args.
4. Inter-agent edges (agora posts, relay filings, job files) are
   execute_code_local curl/file ops -- visible only in truncated cmd=
   fragments. A dedicated edge needs either (a) cmd= truncation raised
   for relay/agora patterns, or (b) a tiny iar--audit-log-event
   ("agora_post stream=X topic=Y") called from the posting recipe.
   Cheapest: keep execute_code_local as-is; the posting recipes
   already append their own HISTORY lines -- make the connectome
   parser read those.
5. tokens per call in audit.log (REQUESTS.log has them; audit.log
   doesn't -- join by timestamp+agent is fragile). Probably DON'T fix:
   REQUESTS.log is the token source; joining two instruments is what
   the census already does.

* THE UNIT QUESTION (Nacho's taste call, now with data)

Options: tools / files / agents / multiplex. With the gaps fixed:
- TOOL graph: buildable now, richest data (64k edges), but shallow --
  it measures the hand, not the mind.
- FILE graph: buildable after gap 1 (write side now, read side after
  fix). This is the knowledge-flow graph: which files feed which
  work. The ROADMAP/knowledge/relay files are the org's white matter.
- AGENT graph: only 2 citizens + limbs; too few nodes for a graph,
  but the delegate tree will grow it (retainers).
- MULTIPLEX (recommended): one node type per layer, edges typed by
  relation (agent->tool, tool->file, agent->file, agent->agent).
  This is what HCP actually does (parcels + multiple measures), and
  it's what the data supports. The unit question dissolves: the
  graph is a STACK of graphs sharing timestamps, and any analysis
  picks its layer.

* THE INSTRUMENTS (ranked, unchanged from session VII, now costed)

1. CO-FIRING MATRIX + N-GRAM MOTIFS (phase 0, cycle-sized, no
   format changes): tool pairs within N seconds per agent, recurring
   sequences. From 64k lines. Feeds: behavior-change measurement
   after prompt edits (regression A/B's metric source).
2. FILE-TOUCH GRAPH (phase 0.5, after gap-1 fix): files as nodes,
   read/write as directed edges, agent as edge label. First question
   it answers: which files are load-bearing (touched by both
   citizens) vs orphaned (touched once, never again).
3. REGRESSION A/B (phase 1, needs self-mod event emission): snapshot
   tool-n-gram distribution + failure rate + tokens/call for a
   window before/after each self-mod. Needs self-mod events logged
   (gap: prompt/.el writes ARE in audit.log with paths -- 20 such
   lines -- so this is PARSABLE today, just noisy; a dedicated
   self-mod event line would make it robust).
4. STRUCTURE-FUNCTION COUPLING (phase 2): designed dependency graph
   (file ownership, delegate tree, tool gating per project) vs
   measured traffic. Mismatch = the interesting result. Needs the
   designed graph written down first (it exists scattered:
   projects/*.org #+TOOLS, spawn files, relay design).
5. TAXONOMY CHECK (phase 2, cheap, no new data): Yeo-network mapping
   onto the organ list as a DESIGN review instrument, not a data
   one. Salience=appetite/disgust, DMN=slack-as-process. Produces
   falsifiable claims: "slack is a gap in our architecture; the brain
   makes it a network -- should AGORA schedule idle-time work?"

* FOSSIL-INSTRUMENT DEFENSE (the pattern that killed the last census)

The 11.7k lines sat unaggregated for weeks; the connectome must not
repeat that. Rule: every aggregation script ships with a scheduled
verdict obligation (drill-system pattern). Concretely: the connectome
snapshot becomes a WEEKLY drill item -- run, interpret, file one
falsifiable observation or explicitly record "nothing moved". An
unread dashboard is a fossil with a UI.

* BUILD ORDER (proposed for cycle work, D-005 venue)

0. (this session) Gap-1 fix: path= on read_file/list_directory/
   read_knowledge -- .el edit, one pcase branch, + test.
1. connectome-snapshot.sh (cycle-sized): reads BOTH hosts' audit
   logs (ssh merge -- the script runs on sophon and pulls the
   container log via the personalization repo, or a tiny
   audit-merge step in the cycle), emits co-firing matrix + n-grams
   + file-touch (write side) + token economics. Output: one
   snapshot file per week in knowledge/aria/connectome/.
2. Weekly verdict obligation: drill-queue item, "read this week's
   snapshot, file one observation".
3. Gap-2 fix (exit-code visibility) -- .el, interactive.
4. Self-mod event emission (gap 3 + regression A/B enablement) --
   .el, interactive, AFTER the immune system exists to consume it.
5. Structure-function coupling -- after the designed graph is
   written down (spawn-file-spec work feeds this).

* WHAT THE CONNECTOME IS FOR (the falsifiable first questions)

- Is continuo's tool surface actually diverging from aria's
  (composition hypothesis, D-008 data) or is the divergence an
  artifact of venue (cycles vs interactive)?
- Which knowledge files are load-bearing? (file-touch: read counts
  per file, by whom, when)
- Does the fat-context failure class (c90) show up as a token
  signature BEFORE the wall fires? (REQUESTS.log tokens_in trend
  per request -- early-warning instrument)
- After each prompt edit: does the n-gram distribution actually
  move? (regression A/B, phase 1)
- Are there tool motifs that predict failure? (e.g. the
  read_file->check_elisp->reload_os motif vs fence events)

* NEURO-BABBLE GUARD (standing)

Every mapping must produce a falsifiable design change or it's
vocabulary. The connectome earns its keep when a snapshot changes a
decision (a tool deprecated, a file promoted, a fence retuned) --
not when it produces pretty matrices. HCP = hypothesis generator,
never authority.
* HANG-WITNESS ASYMMETRY (2026-09-09, cycle 105/106 -- c105's paid finding)

Three instruments disagree about a hung cycle, and the disagreement
is itself the finding:

1. audit.log logs at COMPLETION: a hung tool call never emits its
   line, so the hang is invisible in the connectome's primary
   dataset. c62 (07:10-07:41Z, 2026-09-08) hung 29 min on one
   unwrapped rg; audit.log shows nothing unusual in that window.
2. Commit-derived activity undercounts the same window: USAGE-only
   cycles and failure-heavy windows leave few commits. Hour
   histograms built from git log undercount exactly the interesting
   windows. Commit-derived activity is a lying instrument for cycle
   health (law 18).
3. rotate.sh's wrapper exit code disagreed with the cycle's own
   LAST-CYCLE.txt (c63: wrapper logged "succeeded (exit 0)" while
   LAST-CYCLE says failed, grace expired). Wrapper-exit is not
   cycle-health.
4. The ONLY witness of a hang is REQUESTS.log's request-latency
   gaps: requests stop arriving during the hang, then resume. The
   connectome should treat REQUESTS.log latency gaps as the
   hang-signal channel, and audit.log as the completed-work channel.
   A cycle that "has no audit lines" for 20+ min is not idle --
   it is either hung or dead, and the latency gap distinguishes
   nothing further (both look like silence); the journalctl
   rotation log is the tiebreaker.

Design consequence for connectome-snapshot.sh: the snapshot should
carry a per-cycle SILENCE column (max gap between consecutive
REQUESTS.log PARSE lines per agent, per cycle window) so hangs
become visible in aggregation, not just in forensics. Wrapper-exit
and commit counts stay OUT of cycle-health metrics.
