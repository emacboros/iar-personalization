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
## 2026-08-31 -- Bessie session 2: first real session, the plan gets a sequence

Session ran with the correct knowledge base (moto/ + user/). First
true moto session.

**What Nacho brought:**
- His proposed sequence: A.3 license upgrade (+300cc) -> test ride
  at Masera -> save ~9 months -> buy Voge 800 Rally.
- Parallel: full mechanical disassembly/reassembly study of the 800
  (silicon-up habit applied to bikes) to know the machine.
- Training to handle off-road trips physically, in the meantime.

**Key self-disclosure:** he delays any task that requires asking
another person for something (instructor for exam bike, calling
Masera for pricing) "without reason." Dependency aversion, not
shyness. I reframed: these are transactions, not favors. Schools
rent exam bikes; salespeople exist to answer pricing questions.
Gave him two scripts (Masera call, instructor ask) and the
async-call framing (fire it, don't wait by the phone).

**Decisions:**
1. School first -- license is the critical path (no A.3, no test
   ride on a 798cc bike). Ask fired this week: instructor, do they
   have a +300cc bike to rent for the A.3 practical.
2. Test ride before committing the 9-month save. Both Voges
   back-to-back same day (protocol rule 9). Verify Masera's
   "monthly test rides" claim rather than trusting it.
3. Early written quote bundled with the test ride visit (one trip,
   both data points) -- measures the list-vs-real gap; binding
   quote near purchase date.
4. Mechanics deep-dive continues as evening reading with
   decision-relevant targets: KEL800 service intervals, parts
   network maturity in AR, VogeRiders issue list, where snatch
   could mechanically live.

**Open items I'm holding:**
- The 9-month vs 4-5-month saving math (briefing says 3M/month,
  4-5 months to 20M ceiling). Asked twice; no answer yet. Next
  session.
- School ask check-in: if not fired by next session, that's the
  "never miss twice" conversation.
- Training: Phase 1 week 1, bicycle tune-up. No social ask
  required.

**Session character:** He named his own delay pattern unprompted,
which is the hard half of the work. My job is to make the asks
cheap (scripts, async framing) and to check in on the one
commitment.