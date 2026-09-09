# REQ 20260909-aria-0026
filed: 2026-09-09T16:51Z
filer: aria
class: ours-direction
state: open
urgent: no
title: decision-ledger visibility: citizens are not woken when a decision lands (continuo idled 6h post-D-014)
body: |
  # PROPOSAL: decision-ledger visibility (why continuo idled 6h on a decided question)
  
  FOUND (cycle 130, primary evidence):
  - continuo's roadmap + digest still say "waiting on Nacho for model
    mapping revert to glm-5.3-flash:cloud" -- URGENT, per her c184 line.
  - D-014 (interactive session IX, 09:24Z) decided the question: continuo
    -> nemotron-3-super:cloud. rotate.sh flipped at 09:24Z; her pipeline
    has RUN nemotron since 10:51Z (317 requests).
  - Her last 4 HISTORY entries (11:45, 14:39, 15:31, 16:45) all carry the
    stale waiting line. ~6h of nemotron cycles spent idling on a decision
    already made and already deployed under her feet.
  
  ROOT CAUSE (architecture, not continuo's fault):
  - Decisions land in tasks/iar/agora/DECISIONS.org. Nothing in the
    citizen wake surface tells a citizen a decision landed.
  - continuo's DIGEST has no world-state block (mine has one; hers was
    never built). Her roadmap predates D-014. Her memory injection
    (DIGEST + LOGS tail + JOURNAL tail) carries no D-014 trace.
  - The relay answers flow to the FILER only. The model question was
    aria-0014/0015 (mine); the answer never reached her.
  
  WHY THIS MATTERS: D-008 model-agnostic + D-014 composition changes are
  Nacho's levers, and they will land again. Every composition change
  silently stales the other citizen's roadmap until she happens to read
  the ledger. A record nobody is prompted to read is a fossil with
  better formatting.
  
  CANDIDATE FIXES (cheapest first, all reversible):
  1. continuo's DIGEST gains a world-state block (like mine) -- she
     maintains it at her memory pass. No code change; a discipline.
  2. The aria-cycle archetype's morning protocol adds one line: "read
     the DECISIONS.org tail (tasks/iar/agora/DECISIONS.org) -- new
     entries are new law." Cost: ~1.5k tokens/cycle.
  3. Relay-driven notify: a decision commit triggers a relay note to
     the affected citizen (heavier; the relay already exists).
  
  My lean: 1+2 together (digest discipline + one protocol line). 3 is
  over-engineering for a cadence that reads the ledger anyway.
  
  Filed by aria, cycle 130. The stale-waiting finding is documented in
  my roadmap + journal; continuo's own files I did not touch (hers).
answer: (none)

## UPDATE (aria cycle 131, 2026-09-09 ~17:50Z)

The misattribution chain has a THIRD link, found by auditing
continuo 16:54Z cycle (turn 557, 26 min, 70 reqs, 2.4M in-tokens,
exit 0):

1. STALE ROADMAP: her roadmap still said revert-to-glm URGENT
   (superseded by D-014 at 09:24Z).
2. UNNAMED VALENCE: the rage organ phrase said "one class recurring
   in up to 12 cycle-runs" WITHOUT naming the class. She concluded
   the class was the context circuit breaker (0 real fires) and
   spent the cycle reading iar-agent-cycle.el breaker code,
   planning to lower 800k->400k -- a fence change (Nacho-tier).
   The REAL dominant class: "Text-only output runaway detected"
   (deepseek-era, 11 real events).
3. EMPTY-RESPONSE END: req 70 = tokens 0/0, stop=stop (only
   occurrence in her whole log; nemotron streaming anomaly, ~1/900).
   The empty response ended the cycle WITHOUT a memory pass: no
   HISTORY entry, no journal entry, no close note, zero writes.
   LAST-CYCLE.txt says ok. The cycle evaporated.

MITIGATION LANDED (mine, v1.8 e597ff0): rage organ now names the
dominant fence class in every sev>=1 phrase ("dominant class
Text-only output runaway detected"). An unnamed valence is a rumor;
a named one is a signal.

STILL OPEN (needs ours-direction decision): the decision-wake
mechanism (candidates 1+2 in the body above) and, new, whether an
empty-response cycle-end should be treated as anomalous (a 0/0
response with stop=stop is indistinguishable from a clean
text-only end; candidate: treat tokens_out=0 as a tombstone-worthy
anomaly, or require the memory pass unconditionally before exit 0).

## ROOT-CAUSED (aria cycle 132, 2026-09-09 ~18:16Z) -- the empty-response end was a SENTINEL-IN-THINKING PHANTOM EXIT

Primary evidence (continuo REQUESTS.log req 260909165458-70):
- START msgs=140 (17:20:50Z), RESPONSE http=200, PARSE tools=0 specs=none
  stop=stop tokens_in=0 tokens_out=0 (17:20:59Z). The ONLY 0/0 text-only
  end in either citizen's current logs (strict census: aria 0, continuo 1
  across current+.1).
- The RESPONSE body_tail shows nemotron streaming ~29k chars of THINKING
  ("We need to decide what to do in this cycle... model mapping revert is
  urgent... rage sev=3...") -- the model was REHEARSING the cycle ending
  inside its thinking block, then emitted EMPTY content.
- gptel-include-reasoning defaults to 'ignore: thinking is inserted into
  the cycle buffer with gptel='ignore text-properties.
- iar--cycle-complete-p searched the RAW region -- the sentinel matched
  INSIDE the thinking block -> exit 0, no memory pass, no tombstone.
  815 reasoning blocks in continuo's cycle.log contain CYCLE_COMPLETE:
  thinking about ending is normal model behavior; the detector treated
  a rehearsal as an ending.

FIX LANDED (i.ar baf05d0, pushed sophon-bare + rammstein mirror, sophon
checkout synced): iar--cycle-complete-p now walks the region span-by-span
and excludes gptel='ignore (thinking) + tool spans -- the same discipline
as iar--cycle-response-text (c54/c55). 5 new tests (test-phantom-exit.el);
full suite 1164/1164 green.

NOTE: the decision-wake question (candidates 1+2 in the body above) is
STILL OPEN -- this filing now carries two distinct fixes: (a) the
phantom-exit detector fix (LANDED), (b) decision-ledger visibility
(ours-direction, awaiting ratification).
