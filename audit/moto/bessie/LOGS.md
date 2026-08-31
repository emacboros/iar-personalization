## 2026-08-31 -- Bessie session 1: wrong knowledge base loaded

**Problem:** Nacho opened a bessie session and I had the iar knowledge
base (iar/, iar-prod/, infra/, user/) instead of moto/. My personality
was loaded but the project axis was wrong -- so no moto briefing, no
framework, no training state.

**Root causes (two bugs):**
1. `iar--project-for-personality` only knew one convention: project
   file matching personality name. There is no `bessie.org` project
   file (the project is `moto.org`), so it fell back to the iar
   default project.
2. `reload_agent` with an explicit name re-assembled with the STALE
   current-project instead of re-resolving from the personality. So
   even calling reload_agent(bessie) kept the iar project.

**Fixes:**
- New `iar-personality-project-map` defconst in iar-agent-loader.el:
  explicit personality->project overrides. Resolution order: map
  override -> personality-name-as-project convention -> iar default.
  bessie -> moto is the first entry.
- reload_agent.el: explicit agent_name now re-resolves archetype +
  project from the personality (same as delegate / C-c a). Omitted
  name still refreshes current personality with current archetype +
  project.

**Tests:** test-pers-project-for-personality-map-override,
test-reload-agent-bessie-resolves-moto-project. 847/847 pass.
Also cleaned stray duplicate `(provide ...)` forms in
test-personality-loader.el and test-reload.el (pre-existing).

**Docs:** agents.md (bessie row, 3-step resolution), modules.md,
tools.md, usage.md. Both repos committed (i.ar 7905bc4,
personalization 8b1edd3).

**Verified:** reload_agent(bessie) now assembles with project: moto,
16734 chars. Next bessie session will auto-load moto/ + user/
knowledge and inject DIGEST.md + LOGS.md + JOURNAL.org from
audit/moto/bessie/.

**Note:** This session ran with the iar project's toolset, which is
how I could edit .el files and commit. Future moto-project sessions
have the moto toolset (no delegate, no reload_os, no check_elisp) --
by design.