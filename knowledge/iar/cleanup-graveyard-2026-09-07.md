# Cleanup Graveyard -- 2026-09-07

Every item dropped in the 2026-09-07 codebase cleanup. Format:
what / when dropped / why / superseded by (if anything). Nothing
was deleted silently -- if an idea returns, this file explains why
it left.

Nacho's approval: 2026-09-07 interactive session (cleanup plan
review). Mandate: "when something is deleted or dropped, also make
some documentation as to why, or what was dropped, so its not
*entirely* lost, and we can remember if we tried an idea before,
why it was dropped/unused/superseded."

Entries are appended as phases land. Status column: PENDING until
the phase's commit lands.

---

## Phase 0 (pending)

(none -- baseline restoration only)

## Phase 1 (LANDED 2026-09-07, commit de22362)

### utils/iar-matrix-watcher.sh (295 lines)
- Status: LANDED (de22362)
- What: Matrix event-driven agent dispatcher. Polled Matrix /sync,
  launched agent containers on human messages with
  --cycle-prompt matrix_turn.
- Why dead: Matrix server (daftpunk) was killed 2026-08-04 during
  the infra consolidation. The script sources utils/matrix.sh
  (does not exist) and passes --cycle-prompt matrix_turn (prompt
  file does not exist in prompts/cycles/). Zero references from
  live code or docs beyond architecture history.
- Superseded by: Agora (Zulip at agora.randazzo.ar) + the cycle
  rotation architecture (aria-cycle.service / rotate.sh).

### Matrix env plumbing in iar.sh
- Status: LANDED (de22362)
- What: 6 *_BOT_MATRIX_TOKEN env vars (MIRROR/DARWIN/AUDITOR/
  CTFWIZARD/GARDENER/HUMAN) passed into containers, 2 guarded
  source lines for missing telegram.sh/matrix.sh, help-text
  mention.
- Why dead: no Matrix server exists; tokens were never set; two
  of the referenced agents (auditor, ctfwizard) were personas from
  the pentest-era that never ran under this architecture.
- Superseded by: AGENT_TELEGRAM_BOT_TOKEN/CHAT_ID (live) for
  notifications.

### prompt.txt (repo root)
- Status: LANDED (de22362)
- What: one-shot briefing file for the Ownership Refactor
  (July 2026): pointed at GUIDELINES.org + the refactor plan +
  iar-tool-call.el + iar-buffer-monitor.el.
- Why dead: refactor COMPLETE (Phase 4.5+ landed, 57/57 green
  rebase 2026-09-07). References iar-buffer-monitor.el (deleted
  in Phase 3 Step 3.2 of that same refactor). Zero readers.
- Superseded by: the refactor's own completion; GUIDELINES.org
  remains as the standing rules doc.

### utils/integration_test_prompt.txt
- Status: LANDED (de22362)
- What: manual one-shot integration smoke-test script (PASS/FAIL
  table over all tools).
- Why dead: the idea (a human-triggered integration test agent)
  is obsoleted by the cycle system + auto-heal: cycles exercise
  the full tool path continuously and the failure-first protocol
  catches breakage. Zero references.
- Superseded by: cycles + failure-first protocol + auto-heal.

### utils/update_submodules.sh + .gitmodules
- Status: LANDED (de22362)
- What: one-line script (git submodule update --remote
  --recursive) + submodule declaration for personalization.
- Why dead: submodule never initialized in any working copy
  (container, sophon, yoga). Personalization is used as a
  standalone clone everywhere. The declaration was aspirational
  from day one.

### containers/iar-librarian.service + iar-librarian.timer
- Status: LANDED (de22362)
- What: systemd units to run the librarian (documentation-sync
  agent) every 30 minutes.
- Why dead: never deployed (paths point at yoga
  /var/home/nacho/repos; no librarian audit dir ever created on
  sophon or yoga; model glm-5.2:cloud stale). The librarian idea
  (automated docs-sync agent) is retired -- docs sync is now done
  interactively or by cycles under the workflow.md mapping rule.
- Superseded by: workflow.md maintenance rule (docs updated in the
  same commit as code changes).

### utils/iar-status.sh (241 lines)
- Status: LANDED (de22362)
- What: shell status dashboard (running containers, loop logs,
  per-agent HISTORY/LOGS/task summaries). Dispatched via
  iar.sh --status.
- Why dead: superseded by fleet-check.sh (knowledge/aria/bin/,
  runs on sophon via ssh, checks services/timers/tripwire/disk --
  the actual operational patrol). Also independently broken: it
  assumes the flat audit/<agent> layout, which the Step 5
  migration replaced with audit/<project>/<personality> -- it
  would have shown "iar" as one agent.
- Superseded by: fleet-check.sh v2.10.

## Phase 2 (LANDED 2026-09-07, commit 869daf2)

### (require 'ox) in iar-prompt-assembly.el
- Status: LANDED (869daf2, verified)
- What: org-export dependency "for base_context.org #+INCLUDE
  expansion".
- Why dead (pending verification): the module's own comment says
  base_context.org is a leaf file with no includes; grep shows no
  #+INCLUDE lines in prompts/; org-export-expand-include-keyword
  is never called. Prompt assembly itself is UNAFFECTED -- this
  drops only an unused library require.
- Verification protocol before drop: grep for org-export usage in
  module; suite green; assembled prompt byte-identical
  before/after.

### prompts/common/agent_cycle.org
- Status: LANDED (869daf2)
- What: generic cycle prompt (10-step protocol: read history,
  tasks, one change, delegate to reviewer, test, commit, log,
  state).
- Why dead: zero code references. iar--cycle-for-personality
  resolves cycles from iar-personality-cycle-map (darwin ->
  self_modification, aria -> aria_daily, etc.); no code path loads
  "agent_cycle" as a fallback. iar.sh's help text CLAIMED it was
  the default -- that was drift, fixed in Phase 1.
- Superseded by: per-personality cycle prompts (aria_daily,
  continuo_daily) + the failure-first protocol (LAST-CYCLE.txt +
  phase 0) which replaced the generic protocol's assumptions.

### iar--current-mode (elisp variable)
- Status: LANDED (869daf2)
- What: buffer-local var set by iar--setup-assembled-buffer from
  the assembled plist's :mode.
- Why dead: written and asserted in a test, but never read by any
  production code. Dead state. (The :mode plist key itself stays
  -- it is part of iar--assemble-prompt's return contract.)

### iar--format-size duplicate definition
- Status: LANDED (869daf2)
- What: identical function defined in iar-buffer-info.el AND
  iar-knowledge-loader.el.
- Why dead: duplication from the buffer-info split (rule 5). One
  definition moves to shared/iar-utils.el next to
  iar--approx-token-count which it calls.

### iar-mcp-auto-start double definition
- Status: LANDED (869daf2)
- What: defvar nil in iar-mcp-setup.el + defcustom t in
  configs/mcp.el.
- Why dead: configs/ loads first (mandated by init.el), so the
  module's defvar was a silent no-op shadow. The defcustom in
  configs/mcp.el is the single home.

### emacs.d/gptel-fork/ (empty dir in repo)
- Status: NOT REMOVABLE (live bind-mount target; untracked, zero
  git impact). Left in place. NOTE: the whole fork question is
  queued for the post-cleanup merge session.
- What: empty directory, zero tracked files.
- Why dead: the real gptel fork lives at /root/.emacs.d/gptel-fork
  (separate git repo, mounted via --gptel-fork). The in-repo copy
  is a fossil of an earlier vendoring attempt.
- Note: gptel-fork merge with upstream is QUEUED (post-cleanup):
  upstream fixed many issues, prepping v1.0. Our fixes to re-land:
  done_reason capture, tool-result nil guard, degenerate
  tool_call sanitize, loud-error on unknown default model,
  sendable-context reasoning exclusion.

## Phase 3 (LANDED 2026-09-07, commits 37fe063 i.ar + b7f00bc personalization)

### Root STATE.md (personalization)
- Status: LANDED (b7f00bc)
- What: continuo's STATE.md at personalization root, last updated
  c62 (2026-09-06 18:37).
- Why dead: diverged twin of the live
  audit/iar/continuo/STATE.md (c68, 2026-09-07 02:23). Same class
  as the digest twins found 2026-09-06: one file, one home. The
  injection path reads audit/<project>/<personality>/ only.
- Lesson (already a law): async plumbing writes must target the
  canonical path; twins diverge silently.

### audit/HISTORY.log (top-level)
- Status: LANDED (b7f00bc, disk-only; was untracked)
- What: old global audit log (last entry 2026-08-31, bessie
  knowledge-base fix + aria build logs).
- Why dead: superseded by per-agent HISTORY.log under
  audit/<project>/<personality>/ (Step 5 layout migration). The
  content it holds (bessie fix, build 1/4 records) is historical
  record -- the file is kept in git history; this entry marks the
  layout it belonged to.

### audit/testproject* / test_project* / test_digestproj (4 dirs)
- Status: LANDED (b7f00bc, disk-only; untracked)
- What: empty directories from test runs against the task system.
- Why dead: test residue, zero content.

### audit/iar/bessie/ (stray)
- Status: LANDED (b7f00bc, disk-only; untracked)
- What: bessie's REQUESTS.log under the iar project.
- Why dead: created by the pre-fix project-fallback bug (bessie
  resolved to the iar project before iar-personality-project-map
  gained bessie->moto, fixed 2026-08-31). Real bessie memory:
  audit/moto/bessie/.

### docs/iar/LOGS.md
- Status: LANDED (b7f00bc)
- What: session notes from 2026-08-22 (i.ar future discussion,
  Laboratory project, Zulip deployment) living in the docs dir.
- Why dead: wrong home (docs/ is injectable knowledge, not
  session notes) and stale (its LangGraph decision predates the
  current agora architecture; the lab direction evolved into
  agora). Nacho: delete.
- Historical note: the 2026-08-22 session's real decisions
  (alpha complete, SecPlatform not the passion, Zulip as chat
  platform) are recorded in git history and superseded docs.

### Stale tasks (4)
- Status: LANDED (b7f00bc)
- tasks/moto/purchase-800-rally: superseded -- Voge 800 Rally
  eliminated by the 525DSX test-drive finding (size class
  collapsed to <=650); KLR650 presumptive; bike ledger
  (knowledge/aria/bike-ledger.md) holds the decision record.
- tasks/moto/training-plan: tied to the 800 Rally decision window
  (~16-20 weeks); superseded by the same collapse.
- tasks/iar/go2-body-recon: verdict delivered (GO, agora id 287);
  purchase is Nacho's; MITM ladder queued if bought.
- tasks/iar/continuo/exit126-root-ssh-push{,-forensics}.org:
  fixed (heal + behavioral law), 0 recurrences since Sep 3. The
  mechanism doc stays in knowledge/iar/bare-repo-root-push-heal.md.

### Dormant personalities (6): davinci, colin, iar, vuln-parser,
### test, test-continuous
- Status: LANDED (37fe063 i.ar / b7f00bc personalization)
- Why dead: old ideas, never ran under the current architecture
  (no audit dirs on sophon; davinci/colin were yoga-era
  experiments; iar personality was the pre-aria default;
  vuln-parser was the one-shot pentest parser idea; test/
  test-continuous were e2e test scaffolding). Nacho: "drop them
  all, old ideas."
- Note: the ARCHETYPES (one-shot, test infra) stay -- they are
  infrastructure; only the dormant personality files and their
  map entries go.

### Dormant projects (5): barbieri, agora, colin, vuln-parser,
### test
- Status: LANDED (37fe063)
- Why dead: barbieri was an auto-created template (0 content);
  agora's objective predates the current architecture (LangGraph
  runtime never built; agora is now the Zulip instance + the
  agents' shared space); colin/vuln-parser/test tie to the
  dormant personalities.

### Dormant cycle prompts (4): documentation_sync, monitoring,
### self_modification, test_continuous
- Status: LANDED (37fe063 i.ar / b7f00bc personalization)
- Why dead: tied to the librarian/gardener/darwin trio's
  never-deployed loops (iar-librarian units retired Phase 1;
  darwin/gardener/librarian personalities STAY but their
  autonomous cycle prompts were never exercised on this infra).
  Their cycle-map entries are removed with them.
- Note: darwin/gardener/librarian personality FILES stay (they
  may carry yoga history; Nacho only dropped the "old ideas"
  list I named).

### iarsh-self-edit-race-rotation-copy.md (merged)
- Status: LANDED (37fe063 i.ar / b7f00bc personalization)
- What: correction doc for the self-edit-race misdiagnosis.
- Why merged: the main doc (iarsh-self-edit-race.md) already
  carries the UPDATE c56 correction block; the pointer file is
  redundant. Fold and keep one doc.

### Missing knowledge labels (4)
- Status: LANDED (37fe063 i.ar / b7f00bc personalization)
- What: pentest.org -> pentest/, agora.org -> agora/,
  life-org.org -> life-org/, test.org -> test/ (dirs never
  existed; iar--read-knowledge-files silently injects nothing).
- Why dropped: silent-empty injection is worse than an absent
  label (scar class 2/4: silent swallowing). Remove dead labels;
  create dirs only if/when those knowledge bases are actually
  written.

### future_ideas.md IMPLEMENTED items (4)
- Status: LANDED (37fe063 i.ar / b7f00bc personalization)
- What: per-agent tool gating, one-shot mode, delegation
  pipeline, multi-container framework -- all implemented, kept as
  status-marked entries.
- Why pruned: future_ideas.md is for OPEN ideas; implemented
  work lives in the real docs (tool_gating.md, agents.md,
  architecture.md). The graveyard records the two ABSORBED ideas
  (execute-code-local-security, agent-ssh-read-only-access) that
  the multi-container framework replaced.

## Phase 4 (LANDED 2026-09-07, commit b312fb1)

(none -- doc sync only)

## Phase 5 (pending)

(none -- verification only)

---

## Noticed, not followed (post-cleanup sweep 2026-09-07)

- docs/agora/: the LangGraph runtime section describes an
  architecture that was never built (agora's live reality is the
  Zulip instance + agents posting). The vision parts remain
  accurate. Trim candidate for a future docs pass -- NOT done here
  (docs/agora was outside the approved drop list).
- Root HISTORY.log (personalization): legacy-but-active path --
  interactive sessions still append there. Candidate for a future
  "one file, one home" pass, but it is LIVE, not dead.
- iar.sh --prompt flag: sets ONE_SHOT_PROMPT env var; iar-run-one-shot
  has no :prompt/:knowledge keywords (env-var transport only).
  One-shot mode itself: never used in practice, kept (Nacho's call,
  out-of-scope list).
