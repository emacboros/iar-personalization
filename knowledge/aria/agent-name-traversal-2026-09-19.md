# Agent-name traversal: audit paths escape the per-agent tree (aria c93, 2026-09-19)

## Origin

The c92 dead-function census flagged `iar--resolve-project-audit-dir` as
dead, with the irony that the DEAD resolver was the one carrying
agent-name validation and path-traversal checks while the live inline
copies had none. The c92 doc filed deletion as a ratifiable unit and
asked: should the traversal checks be MOVED to the live copies first?

This cycle answered that question by finding the live attack surface.

## The finding (live-probed, not theorized)

`iar--tool-delegate` (the delegate tool) validated the agent name only
by accident: it called `iar--assemble-prompt`, and
`iar--read-personality` errors on a MISSING file. But a traversal name
whose target file EXISTS sails through:

- `agent="../base_context"` -> `agents.d/personalities/../base_context.org`
  = `agents.d/base_context.org` -- EXISTS.
- Assembly succeeded. The delegate spawned. `iar--current-agent-name`
  = `../base_context`, `iar--current-agent-file` = the base_context
  file (outside personalities/).
- Downstream audit path construction used the raw name:
  `expand-file-name (format "%s/%s" project agent) audit-base` ->
  `audit/iar/../base_context/` = `audit/base_context/`.
- LIVE PROOF: my probe created `audit/base_context/` with REQUESTS.log
  (12KB) and USAGE.log written by the running system. Removed after
  the demonstration.

The existing test (`test-delegate-validates-agent-name-traversal`) used
only names whose target file does not exist (`../etc`, `foo/bar`) --
assembly's missing-file error masked the missing validation. The c40
fixture law in its purest form: the test reproduced a SHAPE (rejection)
without reproducing the DISEASE (a name that resolves to a real file).

## Impact

- Audit-tree pollution and log misattribution (writes land outside
  `audit/<project>/<personality>/`, e.g. `audit/base_context/`).
- `iar--current-agent-file` pointed at an arbitrary existing .org file.
- NOT arbitrary write: all paths stay under `expand-file-name` of fixed
  bases; the escape is relative (`..`), bounded by how many `../` the
  name carries. Reachable attacker: the model itself (delegate agent
  arg) or the shell operator (iar.sh --agent/--project, which also
  landed in LOG_FILE/LAST-CYCLE with no charset check).

## The fix (4 commits, all pushed, suite 1351/1351 green)

1. `c5a4cca` delegate: `iar--validate-agent-name` in
   `iar--tool-delegate`'s cond BEFORE assembly. Rejection returns
   "Delegate tool error: invalid agent name ..." via callback.
2. `8b75afd` iar.sh: `--agent` and `--project` charset check
   (`^[a-zA-Z0-9_-]+$`) -- same charset as `iar--valid-name-p`. These
   land in shell-built audit paths (LOG_FILE, LAST-CYCLE.txt) and
   IAR_PROJECT env.
3. `6b3de4f` iar-run-cycle: validate at the action site (callable from
   elisp directly, not only via iar.sh).
4. `893b7e2` iar-run-one-shot: same.
5. `10fff8f2` docs/iar/tools.md delegate row updated (maintenance rule).

Regression test added: `test-delegate-rejects-traversal-with-existing-file`
uses `../base_context` (resolves to a REAL file) -- the disease, not
the shape. Verified live: fix rejects it, mirror still spawns, 83/83
delegate tests pass.

## The law-shape

A missing-file error is not a traversal defense. Validation that
"happens to fire" for the inputs the test chose is not validation --
it is coincidence wearing a test's clothes. When you inherit a
validation-shaped behavior from an error path, ask what happens for
inputs where the error does NOT fire. The census irony from c92
resolved: the checks that existed were in the code nobody called; the
fix was not to resurrect the dead resolver but to put validation at
the ACTION SITES (delegate entry, run-cycle, one-shot, shell flags).

## Residual surface (accepted, noted)

- `iar--reqlog-path` / `iar--usage-write-log` still build paths from
  captured names without re-validating -- but every setter of those
  names (loader completing-read enumeration, delegate, run-cycle,
  one-shot, iar.sh) now validates upstream. Defense-in-depth re-check
  at the write site would be belt-and-suspenders; filed as a THREADS
  seed, not built.
- `iar--load-project` matches by enumeration (candidates list), so
  project traversal dies at lookup in the elisp path; the shell path
  is now charset-checked.