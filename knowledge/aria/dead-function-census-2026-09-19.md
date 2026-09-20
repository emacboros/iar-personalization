# Test-suite-as-life-support: the dead-function census (aria c92, 2026-09-19)

Seed origin: c91 found `iar--cycle-load-profile` dead in production (only
tests call it) and filed a sweep seed: "production-dead functions whose only
callers are tests -- the inverse of the c40 fixture law: the test reproduces
a shape nothing in production uses." This census is that sweep, run c92.

## Method

For every defun in init.d (58 files), count references:
- prod = references in init.d + init.el, excluding the defun line itself
- test = references in emacs.d/test/
- dynamic = funcall/apply/symbol-function/#'quote dispatch (checked
  separately -- a name-only census misses these)

DEAD-TEST-ONLY = prod 0, test > 0. DEAD-TOTALLY = both 0.

## Results

11 functions flagged. After reading each in context, they split three ways:

### A. Interactive-only (NOT dead -- M-x surface, tests exercise them)

- `iar-rate-limit-set` (iar-rate-limit.el): dynamic setter for the pentest
  rate limit; production configures via IAR_RATE_LIMIT env (iar.sh
  --rate-limit), this is the runtime knob. Legitimate user-facing API.
- `iar-mcp-start` (iar-mcp-setup.el): manual reconnect when auto-start is
  disabled or a server restarted. Legitimate.
- `iar-status-mode-disable` (iar-status-mode.el): toggle counterpart to
  enable. Legitimate.

Lesson folded in: a defun with an `(interactive)` form is user surface;
"no prod callers" is the wrong predicate for it. The census script should
exclude interactive functions before flagging.

### B. True corpses (dead, tests keep them looking alive)

1. `iar--cycle-load-profile` (agent/iar-agent-cycle.el) -- the c91 original.
   iar-run-cycle assembles directly (reads :knowledge at line 1544 and
   threads it through setup-assembled-buffer -> assemble-prompt).
2. `iar-personality-info` (agent/iar-agent-loader.el) -- docstring says
   "Used by iar-prompt-info to display personality in the prompt
   breakdown" but iar-prompt-info (iar-knowledge-loader.el:202) reads
   `iar--current-agent-name` directly and never calls it. STALE DOCSTRING
   on top of dead code: the docstring is a false provenance claim.
3. `iar--load-or-create-project` + `iar--create-project` (agent/
   iar-project-parser.el) -- a dead CLUSTER. Production loads projects via
   `iar--load-project` directly (iar-prompt-assembly.el:462), which signals
   on missing projects. The auto-create path is unreachable; nothing
   interactive creates projects either. iar--create-project's ONLY caller
   is load-or-create, so killing the entry point kills both. (Note:
   iar--project-candidates is ALIVE -- iar--load-project uses it for
   lookup.)
4. `iar--mcp-filter-servers` (core/iar-mcp-setup.el) -- build-hub-config
   reimplements the same filter inline (config-for-server + dolist); the
   named helper was left behind. Duplicate logic, one copy live.
5. `iar--resolve-project-audit-dir` (shared/iar-agent-utils.el) -- audit
   dirs are resolved inline everywhere (prompt-assembly, request-log,
   iar-utils, read_history all expand iar-audit-path directly). The
   validated resolver (with agent-name validation + traversal check) is
   the one nobody calls; the inline copies are the ones that run. The
   IRONY: the dead function is the one WITH the traversal checks.
6. `iar--task-last-segment` (shared/iar-agent-utils.el) -- zero callers,
   prod or dynamic. Pure corpse.
7. `iar--audit-log-append` + `iar--audit-log-exec` (security/
   iar-audit-log.el) -- legacy per-tool wrappers. The 976f81e refactor
   (Jul 17) centralized audit logging into the tool-call bridge; the
   generic tool_call path (audit-log-tool-call-with-agent) audits
   append_file and execute_code_local by tool NAME with args detail.
   The wrappers predate centralization and were never removed.

### C. Ghost reference (docstring points at a function that never existed)

- `iar--audit-log-tool-call` is referenced in the docstring of
  `iar--audit-log-tool-call-with-agent` ("Same detail policy as
  `iar--audit-log-tool-call'") -- but no function by that name was EVER
  defined in the file's history (git log -S across --all finds nothing).
  The with-agent variant was born (08b8bcb, Aug 31) with a docstring
  citing a sibling that never existed. A documentation ghost.

## The law-shape

A dead function with green tests looks exactly like a live one. The test
suite is a life-support machine: it exercises the corpse's body (signature,
return shape) without its soul (a production caller). The c40 fixture law
says the test must reproduce the DISEASE, not the shape; this is the same
law pointed the other direction -- a test that reproduces a shape nothing
in production uses is keeping the shape alive.

The census predicate needs the interactive exclusion: `(interactive)`
forms are user surface, not dead weight. Without that exclusion the sweep
files three false positives (rate-limit-set, mcp-start, status-mode-disable).

## Dispositions

- Corpses (1-7): safe to delete + their tests. NOT deleted this cycle --
  deletion of shared i.ar code deserves a session or an explicit
  ratification; this doc is the case for it.
- Ghost docstring (C): one-line fix, safe, could ride any commit.
- Census script: /tmp/deadfn-census.sh (not persisted -- the method is
  this doc; re-derive if needed).

## Adjacent finding: duplicate commit pairs in i.ar history

28 duplicate-message pairs in 816 commits. Verified two pairs byte-identical
(08b8bcb/c8b90fb "audit: record WHAT...", a02eed7/7d53402 "tool-guard:
global unknown-tool..."), each pair 10-17 commits apart -- rebase artifacts
from the two-remote era (origin=rammstein + sophon-bare, patches pushed to
one then rebased onto the other). Baked into shared history on both remotes;
not fixable without rewrite (not worth it). Seed: a two-remote setup without
a single push authority breeds duplicate-history; the current single-flow
(origin push, mirror hook) doesn't produce new pairs.