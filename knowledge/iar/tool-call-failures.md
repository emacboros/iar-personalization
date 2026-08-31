
## 2026-08-31 -- iar--normalize-self-mod + :knowledge threading (contract audit, commits 1995582 + 815ae86)

**iar--normalize-self-mod** (init.d/agent/iar-agent-cycle.el):
Shell always passes `:self-modification 0|1` (never omits the
keyword). Elisp truthiness treats 0 as non-nil, so the old
`(if (null sm) nil sm)` ENABLED self-modification when the shell
said 0 -- privilege inversion: every iar.sh loop agent ran with the
conditional file-guard protections (init.el, init.d/*.el,
Containerfile, .git/hooks) skipped. Normalizer: only nil/0/"0"
disable. Used at both entry points (cycle + one-shot).

**:knowledge threading** (iar.sh --knowledge -> iar-run-cycle):
The keyword existed in iar.sh and in modules.md but was never read
by iar-run-cycle -- silently swallowed by (&rest args). Now:
`iar-run-cycle :knowledge LABELS` -> `iar--setup-assembled-buffer
&optional extra-knowledge` -> `iar--assemble-prompt &optional
extra-knowledge-labels` -> appended to project #+KNOWLEDGE.
**Dedupe** (reviewer finding, 815ae86): `iar--dedupe-knowledge-labels`
drops extra labels equivalent to a project label (whitespace and
trailing-slash insensitive) so `--knowledge iar` with project label
`iar/` does not inject the directory twice.

**iar--one-shot-nudge-prompt**: now built from
`iar-one-shot-response-open`/`-close` defcustoms
(configs/delimiters.el) instead of hardcoded copies -- single
source for the delimiter contract.

**Cross-layer contract audit method** (fear-map slice 3, generalizes
cycle 38's lesson): grep every keyword/flag/sentinel that crosses a
boundary (shell<->elisp, prompt<->elisp), then check the receiving
side actually reads it and agrees on semantics. Found here: a
truthiness mismatch (0 vs nil), a dead parameter, and a duplicated
literal. All three were invisible from either side alone.