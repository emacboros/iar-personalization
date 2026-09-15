# i.ar Tools Reference

## Tool Categories

### Filesystem Tools (tools/filesystem/)

| Tool | Args | Description |
|------|------|-------------|
| `read_file` | `filepath` (required) | Read file contents into context. Size-limited by `iar-fs-read-max-size` (default 1MB, from configs/debug.el) using character count. Truncation notice appended when limit exceeded. Error handling via `condition-case`, returns `Error:` string on failure. |
| `write_file` | `filepath`, `content` (required) | Create or overwrite a file. Core function `iar--fs-write-file`. File-guard enforced via `iar--guard-check-write`. Buffer-aware: if file is open in a buffer, checks `buffer-read-only` and `buffer-modified-p`, then erases/inserts/saves with `iar--with-suppressed-save-hooks`. If not in a buffer, uses atomic write (temp file + rename). Creates parent directories. Audit-logged via the tool-call bridge (`iar--audit-log-tool-call-with-agent`: name, status, result_len, target path). Returns `Success:` or `Error:` string. |
| `append_file` | `filepath`, `content` (required) | Append to end of file. Auto-prepends newline if needed. Used for HISTORY.log and LOGS.md. File-guard enforced via `iar--guard-check-append`. Audit-logged via the tool-call bridge (name, status, result_len, target path). |
| `list_directory` | `path` (required) | List directory contents. Returns newline-separated file names including hidden files. Directory entries suffixed with `/`. Results sorted alphabetically. |

### Code Execution (tools/code/)

| Tool | Args | Description |
|------|------|-------------|
| `execute_code_local` | `command` (required) | Run bash command in the container. Uses `:connection-type 'pipe` (no pty allocation). Full toolset available: bash, dig, nmap, openssl, python3, jq, whois, traceroute, tcpdump, rg, git, curl, find, gawk, sed, grep, gcc, make, tar, gzip, unzip. Audit-logged via the tool-call bridge (name, status, result_len, command text capped at 200 chars).  Per-call timeout: defaults to `iar-exec-default-timeout` (600s, c65) -- one hung call must not eat the cycle wall; callers needing longer pass an explicit timeout. |

### Remote Container Execution (tools/code/)

| Tool | Args | Description |
|------|------|-------------|
| `execute_code_remote` | `target` (required), `command` (required) | Execute bash commands in a purpose-specific container (local or remote). Local targets run via `podman exec` into running containers (resolved from `IAR_CONTAINER_<target>` env var). Remote targets run via SSH over WireGuard (`iar-remote-targets` defcustom or `IAR_REMOTE_TARGETS` env var). SSH uses `make-process` with explicit argv (no shell injection surface). Key-only auth. Async tool with same pattern as `execute_code_local`. Output sanitization via `iar--sanitize-exec-output` when enabled. Target validation via `iar--current-containers` buffer-local (set from project `#+CONTAINERS`). Registered via `iar-tool-register`. Audit-logged. Provide symbol: `iar-tool--execute-code-remote`.  Per-call timeout: defaults to `iar-remote-exec-default-timeout` (600s) -- one hung remote call must not eat the cycle wall (mirrors the c65 local fix `iar-exec-default-timeout`); callers needing longer pass an explicit timeout. |

### Code Quality (tools/code/)

| Tool | Args | Description |
|------|------|-------------|
| `check_elisp` | `filepath` (required) | Check .el file for syntax errors, unbalanced parens, and byte-compilation warnings. Two-phase: 1) `check-parens` in temp buffer, 2) `byte-compile-file` with temp .elc (cleaned up). Validates .el extension and file existence. Returns "ISSUES FOUND" or "OK" report. Does NOT modify the file. |

### Task Management (tools/tasks/)

| Tool | Args | Description |
|------|------|-------------|
| `read_task` | `path` (optional) | Read tasks from the current agent's tasks directory (`tasks/<project>/`). With no argument, returns a tree-like hierarchy of all tasks with descriptions. With a path argument (slash-separated), returns detail: directory listing, subtask contents, or single file content. |
| `create_task` | `path`, `description` (required) | Create a new task directory with a description.org file. Path is slash-separated. Description limited to `iar-task-description-limit` characters (default 500, from configs/tasks.el). |
| `write_subtask` | `path`, `content` (required) | Write a subtask .org file inside a task directory. Path is slash-separated where the last segment becomes the filename. |
| `remove_task` | `path` (required) | Remove a task or subtask. If the path is a directory, removes the entire directory tree (task done). If a file, removes just that file (subtask done). |
| `read_history` | `agent_name` (optional) | Read per-agent HISTORY.log from `audit/<project>/<name>/` or unified merged history from all agents. If agent_name provided: validates name, reads single log. If omitted: scans all agent dirs, parses timestamp lines, merges sorted by timestamp into unified timeline. |
| `read_roadmap` | none | Read the ROADMAP.org file from the current agent's tasks directory. The roadmap defines task ordering, dependencies, and cycle guidelines for continuous agents. |
| `write_roadmap` | `content` (required) | Write or overwrite the ROADMAP.org file in the current agent's tasks directory. File-guard protected (append-only for write_file). Use this tool to update the roadmap. |

### Knowledge Base (tools/knowledge/)

| Tool | Args | Description |
|------|------|-------------|
| `read_knowledge` | `path` (optional) | Read from the concept knowledge base directory (`knowledge/`). With no argument, returns a tree of knowledge bases with descriptions. With a path argument (slash-separated), returns: if the path is a directory with subdirectories, the description and a listing of subdirectory and file names (names only); if a directory without subdirectories, the description and full contents of all files; if a file, that single file's content. Handles arbitrary file extensions (.tex, .rb, .c, .v, .spice, .org, .md). Custom path validation allows dots for file extensions. |

### Agent Management (tools/agent/)

| Tool | Args | Description |
|------|------|-------------|
| `reload_os` | none | Re-evaluate init.el. Rebuilds gptel-tools list. Use after modifying .el files. |
| `reload_agent` | `agent_name` (optional) | Re-read personality .org and update system prompt in current buffer. Re-assembles via `iar--setup-assembled-buffer`. With an explicit agent name: re-resolves archetype + project from the personality (same resolution as delegate / C-c a). Without: refreshes current personality with current archetype + project. Use after modifying personality files. |

### Delegation (tools/agent/)

| Tool | Args | Description |
|------|------|-------------|
| `delegate` | `agent` (optional, defaults to agent-assistant), `task` (required), `context` (optional), `timeout` (optional) | Spawn sub-agent with specific profile. Async, returns final response as tool result. Default timeout 600s. Resolves archetype and project from personality name, assembles prompt via `iar--assemble-prompt`, applies tool gating from project `#+TOOLS`. Result extraction via `=== DELEGATION RESULT ===` marker -- only the sub-agent final summary is returned, not raw tool output. Completion hook detects marker in text-only responses (no tools called) to complete simple tasks without re-prompting loop. |

**STATUS:** Matrix server (daftpunk) was killed. These tools are dead unless Matrix is redeployed.
### Notification (tools/notify/)

| Tool | Args | Description |
|------|------|-------------|
| `send_telegram` | `message` (required) | Send Telegram notification via Bot API. Async tool (synchronous curl internally, callback-based from gptel perspective). Message prefixed with `[AgentName]` via `iar--get-agent-name`. Credentials from `AGENT_TELEGRAM_BOT_TOKEN` and `AGENT_TELEGRAM_CHAT_ID` env vars. Uses `call-process` with curl (10s timeout, 5s connect timeout). Audit-logged. |

### Git (tools/git/)

| Tool | Args | Description |
|------|------|-------------|
| `git_commit` | `repo_path`, `message` (required) | Stage all changes (`git add -A`) and commit in a git repository. Sync tool using `call-process` directly (no shell, no injection surface). Validates repo directory and `.git` presence. Git identity auto-configured from configs/git.el. Audit-logged. Returns `Success:` or `Error:` string. |

## Tool Gating

Tool availability is controlled per-project via `#+TOOLS` metadata in project files (`personalization/projects/<name>.org`). The assembly engine (`iar-prompt-assembly.el`) filters the global `gptel-tools` list to only those listed in the project's `#+TOOLS` line.

Example from `personalization/projects/darwin.org`:
```
#+TOOLS: list_directory read_file write_file append_file execute_code_local check_elisp read_task create_task write_subtask remove_task read_history git_commit read_roadmap write_roadmap
```

This gives darwin filesystem, code execution, task management, git, and roadmap tools -- but no delegate, no telegram, no reload, no knowledge.

If `#+TOOLS` is absent from a project file, all registered tools are available (backward compat).

**Container-gated tool:** `execute_code_remote` is gated by `#+CONTAINERS` metadata, not `#+TOOLS`. When a project declares `#+CONTAINERS` (e.g., `#+CONTAINERS: pentest`), the `execute_code_remote` tool is automatically included in the tool list by `iar--filter-tools` (which accepts an optional `containers` argument -- when non-nil, `execute_code_remote` is always added). It does not need to be listed in `#+TOOLS`. Available container targets are injected into the system prompt via `iar--format-containers`, which uses `iar--container-descriptions` (a defconst mapping target names to brief descriptions). When `#+CONTAINERS` is absent from a project file, `execute_code_remote` is not available -- the tool is not registered and sidecar containers are not started.

See `tool_gating.md` for the planned `--enable-code-exec`, `--enable-elisp`, and `--danger-zone` flags that will add container-level tool gating on top of the project-level gating.

## File Guard Protection

The file guard (`iar-file-guard.el`) intercepts `write_file` and `append_file` calls. Protected paths are defined as defcustoms in `configs/file-guard.el` as (regex reason append-allowed) triples.

### Always Protected (cannot be bypassed)
- Archetype files: `agents.d/archetypes/<name>.org` (append not allowed)
- Personality files: `agents.d/personalities/<name>.org` (append not allowed)
- Cycle files: `agents.d/cycles/<name>.org` (append not allowed)
- Shared context: `agents.d/base_context.org` (append not allowed)
- Common prompt templates: `agents.d/common/*.org` (append not allowed)
- HISTORY.log files (append only -- overwrite and replace blocked)
- LOGS.md files (append only -- overwrite and replace blocked)
- JOURNAL.org files (append only -- overwrite and replace blocked)
- STATE.org files (append only -- overwrite and replace blocked. Use write_file for updates -- STATE.org is not append-only in the file guard because it needs full rewrites each cycle.)
- ROADMAP.org files (append only -- overwrite and replace blocked. Use write_roadmap tool to update.)

### Conditionally Protected (relaxed in self-modification mode)
- `init.el` (append not allowed)
- `init.d/**/*.el` (append not allowed)
- `Containerfile` (append not allowed)
- `iar.sh` (append not allowed)
- `containers/` directory (append not allowed)
- `.git/hooks/` directory (append not allowed)

Self-modification mode is controlled by the `EMACBOROS_SELF_MODIFICATION` environment variable (set via `--self-modification` flag on `iar.sh`). When unset, all guards are active. When set to `1`, tier 2 guards are relaxed but tier 1 (archetype/personality/cycle files, base context, history logs, LOGS.md, JOURNAL.org, STATE.org) remains enforced.

### Multi-Container Physical Separation

The multi-container model provides physical filesystem separation per purpose, replacing the need for file guard patches on `execute_code_local`. Sidecar containers (pentest, concepts, life-org, debug) do not share the Emacs container's filesystem except for the shared workspace at `/workspace`. Each sidecar container type has its own image, user namespace, and network policy:

- The **pentest** container has bridge networking (outbound internet) but cannot see the personalization repo, docs, or knowledge bases -- no personal data is mounted into it.
- The **concepts** and **life-org** containers (future) have no networking at all -- they cannot reach the internet.
- The **debug** container mounts the host root filesystem read-only at `/host` for inspection, accessed via SSH over WireGuard with an unprivileged user.

This means file guard is not the security boundary for sidecar execution; physical container separation is. No personalization data, prompts, or Emacs configuration is mounted into sidecars. The `--no-containers` flag on `iar.sh` force-disables sidecar containers regardless of `#+CONTAINERS` in the project file.

## Audit Logging

All tool calls are logged to `audit/audit.log` by the tool-call bridge (`iar--bridge-post-tool-call` -> `iar--audit-log-tool-call-with-agent`). Effectful tools get their arguments recorded: write_file/append_file log the target path, execute_code_local/remote log the command (capped 200 chars), git_commit logs repo + message (capped 80). The agent name is captured at call time from the conversation buffer (async sentinels cannot resolve it; nil falls back to 'unknown'). The capture reads the global default of `iar--current-agent-name`, which `iar--setup-assembled-buffer` and the delegate setup maintain via `setq-default` (a bare `setq` after `setq-local` rebinds only the buffer-local value -- the 2026-08-31 bug that made every batch-cycle audit line say nil/unknown). The log rotates at `iar-audit-log-max-size` (default 10MB, from configs/debug.el), keeping one generation (`audit.log.1`).

## Loop Guard

The loop guard (`iar-loop-guard.el`) detects repetitive tool calls via `iar-pre-tool-call-functions` (i.ar's own hook, bridged to gptel via the tool call layer):
- **Soft threshold** (default 3, from configs/loop-guard.el): After N identical consecutive tool calls, the call is blocked and a correction message is sent to the LLM.
- **Hard threshold** (default 6): After N identical consecutive tool calls, the entire request is stopped.
- History ring size: 20 entries.

## Debug Instrumentation

- **Status mode** (`iar-status-mode.el`): Custom mode-line display showing agent name, prompt size, last and cumulative token counts. All token data comes from the tool call layer's accumulators. No gptel internals.

The tool call layer (`iar-tool-call.el`) provides the underlying token usage tracking and audit logging.
### Honest-failure preflight (2026-09-03, continuo cycle 2)

`execute_code_remote` now preflights the client binary before spawning. When `podman` (local sidecar targets) or `ssh` (remote targets) is not present in the environment, the tool returns an honest diagnosis ("podman client not found in this environment... use execute_code_local instead, or fix the sidecar wiring in an interactive session") instead of a generic re-signaled error. Background: the Emacs cycle container ships no podman client, so every local sidecar exec failed invisibly for 4+ days -- the error was re-signaled by the outer handler, the audit bridge logged the callback as success, and cycle exit codes stayed green (see knowledge/aria/research-sidecar-wiring.md). The preflight makes the failure legible at the tool-result layer, where failure-first and the model can see it. The real fix (podman socket bridge into the Emacs container) remains an interactive-session security decision. Commit d768f37, suite 991/991.
** Resurrection guard (c270 fix, 2026-09-13)

After `git add -A`, staged paths matching `iar-git-commit-refuse-pattern`
(default `\`audit/.*cycle\.log\'`) are unstaged (`git rm --cached`) and
reported in the tool result ("Note: refused to stage ...").  WHY: a
stale checkout that still tracks a gitignored rolling transcript
re-adds it on every `add -A` (tracked files ignore .gitignore) -- the
c270 incident, 109 commits carrying ~6.7GiB of transcript blobs.
Dated transcripts (`cycle-YYYY-MM-DD.log`) do NOT match the pattern:
they are belt-discipline artifacts, tracked intentionally via
`git add -f`.  The commit itself never fails -- the guard only removes
the offending paths and notes them.  Tests: test-git-commit.el
(refuses-rolling-transcript, dated-transcript-still-commits,
guard-silent-when-clean).
### Belt #2b -- pre-exit commit carries the record (c292 fix, 2026-09-14)

`iar--usage-commit-log-now` (the belt #2 pre-exit commit in
iar-tool-call.el) previously committed ONLY `USAGE.log`. The c292
finding: continuo's close protocol has no commit step -- 9 of her 10
successful 09-13 runs left her journal/history/REQUESTS uncommitted,
and her record's durability rode aria's manual belt-syncing. The belt
now stages the agent's OWN record files alongside the meter:
JOURNAL.org, HISTORY.log, LAST-CYCLE.txt, STATE.md, DIGEST.md,
REQUESTS.log, THREADS.org, LOGS.md, today's AND yesterday's dated
cycle logs, plus USAGE.log. Explicit file list (`iar--audit-record-files`), never a
directory sweep: the rolling cycle.log (86MB, the c270 resurrection
class), scratch files, and one-off captures never ride it, and a
sibling agent's files are never touched (the list resolves against
the current agent's log-dir only). Commit message:
"<agent> cycle: belt #2 durability (meter + record files)".
Known edge (fixed c293, commit 584344e): the WRAPPER names the dated
cycle log with the SOPHON-LOCAL date while the belt runs on the
container UTC clock -- in the sophon 21:00-23:59 window (= UTC
00:00-02:59) the wrapper writes yesterday's dated log and the belt
originally staged only today's, so the run's cycle log never rode any
belt (observed: continuo 00:56Z run, sophon 21:56 local). The belt now
stages BOTH today's and yesterday's dated logs (missing files are
skipped). Tests: test-usage-belt2.el (commit-does-not-sweep updated to
the belt #2b contract -- own record rides, sibling stays out;
never-sweeps-cycle-log test) + test-usage-belt2b-tz.el (TZ boundary).
Suite 1253/1253. Commits 7718052, 584344e.
### Belt #2c -- hook refusal is NOT "nothing to commit" (c364 fix, 2026-09-15)

`iar--usage-commit-log-now` treated the belt commit's exit 1 as
"nothing to commit, already durable" and returned t. But exit 1 is
AMBIGUOUS: it is also what a REFUSING pre-commit hook returns. The
HISTORY-CLOCK guard (hooks/pre-commit, c362) refuses belt commits that
carry fabricated future-dated HISTORY.log timestamps -- production
case: continuo 2026-09-15 10:35Z. She generated a `[2026-09-16
10:38:00]` timestamp (the clock-fabrication class), her belt staged
the record files including the fabricated line, the guard refused the
commit, and the belt read exit 1 as durable-success. Result: her
10:31-cycle record stayed undurable AND the refused blob sat staged
in the shared checkout index, where the next waking cycle saw it as a
mystery staging. The fix: the belt now captures the commit's combined
stdout+stderr (via a temp buffer), and when exit is 1 AND the output
matches "REFUSED", returns nil (honest not-durable) with a Warning
message naming the refusal. A plain exit 1 with no REFUSED in the
output is still "nothing to commit" (t). Test:
test-usage-belt2.el (refusal-honest-nil -- a repo whose pre-commit
always refuses). Suite 1293/1293. Commit cb6ea45.
