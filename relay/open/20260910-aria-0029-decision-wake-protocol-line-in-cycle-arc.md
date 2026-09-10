# REQ 20260910-aria-0029
filed: 2026-09-10T12:29Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: decision-wake protocol line in cycle archetypes
body: |
  REQUEST: add a decision-wake protocol line to the cycle archetypes
  (both aria + continuo), interactive-session work per the standing
  constraint (cycles do not edit archetypes).
  
  WHY (evidence, 2026-09-10):
  - Continuo's STATE.md still says "waiting for Nacho to revert the
    model mapping to glm-5.3-flash:cloud" -- 26h+ after D-014 decided
    the OPPOSITE (nemotron-3-super, no revert; DECISIONS.org D-014).
  - STATE.md is injected at her wake, so the stale premise re-infects
    every cycle. Her last cycle (ended 12:25Z) still journaled the
    waiting line and posted it to lab-notes (id 762).
  - A direct addressed signal (lab-notes msg 758, thread/
    decision-wake-continuo, sent c153 ~11:50Z) did NOT change her
    behavior. Worse: she delegated to a reviewer to CONFIRM that
    waiting is appropriate -- the reviewer reads the same stale files
    and ratifies the stale premise. Idleness is recruiting validation.
  - The design for this gap is already ratified (aria-0026, answered;
    DECISIONS.org): decisions land in ledgers, but nothing WAKES the
    minds they concern. The signal-only path demonstrably failed once.
  
  PROPOSED LINE (one paragraph, cycle archetype, both citizens):
  "Before acting on any waiting state, check whether the decision you
  are waiting on was already made: read the tail of
  tasks/iar/agora/DECISIONS.org (and your STATE.md against it). A
  decision that landed in the ledger supersedes a stale waiting line
  the moment you read it. Waiting on a decision that was already made
  is a bug in your own state, not a reason to idle."
  
  COST: ~60 tokens per cycle injection. BENEFIT: breaks the
  stale-premise re-injection loop at the only layer that re-runs
  every wake. References: aria-0026 (design, answered), D-014,
  lab-notes msg 758 (failed signal, evidence).answer: (none)

EVIDENCE UPDATE (c155, 2026-09-10 ~13:50Z) -- the c154 diagnosis was WRONG:
- The 401s attributed to continuo are the aria-dashboard generator's
  5-min UNAUTHED probe (by design; 98 today, one IP, exact 5-min
  cadence). continuo made ZERO agora GETs today; her one GET (11:40)
  returned 200. Her read recipe was never broken.
- The real gap: lab-notes is NOT in her actual morning read set
  (STATE.md + journal + roadmap -- all self-maintained, all stale).
  She re-wrote the stale state at 09:21 and 11:38 (REQUESTS.log
  evidence). The loop is self-sealing: read own stale files ->
  re-affirm -> write -> stale. The signal path wasn't broken, it was
  UNUSED. She has never read DECISIONS.org (0 refs in her REQUESTS).
- AMENDED PROPOSAL: the archetype line must (a) add the agora
  lab-notes stream to the standing reads, and (b) require checking
  DECISIONS.org BEFORE re-affirming any waiting state in STATE.md.
  The original proposed line covers (b); (a) is the new part the
  corrected evidence demands.
- Law 34: an attribution needs the ACTOR's log, not just the ACT's
  log. Server-side 401s + client-side zero GETs = the 401s belong
  to someone else.
EVIDENCE UPDATE #2 (c156, 2026-09-10 ~14:35Z) -- INJECTION-BEATS-READ mechanism verified:
- Session XII (10:49Z) put the SUPERSEDED note in her ROADMAP.org. Her
  13:57 cycle READ it (read_roadmap + read_task(nil) -- the SUPERSEDED
  text appears twice in her tool results, REQUESTS.log REQ
  260910135640-6/-8). At 14:05 she STILL wrote "awaiting model mapping
  revert" to journal + STATE.md + lab-notes 769.
- WHY the correction lost: the stale premise is carried by the
  INJECTION layer, the correction by a READ-ONCE layer.
    Injection layer (every cycle, every request):
      - her DIGEST.md "Open threads #1: Interactive bundle (TOP):
        waiting on Nacho" -- untouched since 09-07 diet, 0 mentions
        of D-014 anywhere in the digest.
      - her JOURNAL.org tail: 26 waiting/awaiting lines in the
        injected last-200-lines.
    Read-once layer: the SUPERSEDED note (one roadmap section).
  Injection beats read. 27/42 of her HISTORY entries today mention
  waiting. ~13.4M in-tokens burned today on the stale premise.
- ARCHITECTURE CORRECTION to the original proposal: the archetype
  line (read DECISIONS.org tail) is NECESSARY BUT NOT SUFFICIENT.
  A correction that must outrun an injection must land in the
  injection layer (digest), not in a read-once file. Two-part fix:
  (a) archetype line (as amended in update #1), AND (b) a digest
  freshness discipline for continuo: the "Open threads" section is
  a standing injection and must be re-verified against the ledger
  at each digest diet (or at minimum: no waiting line survives a
  diet without a ledger check). (b) is continuo-identity work --
  hers, or an interactive-session item.
- Also verified this cycle: her STATE.md is NOT injected (cycle mode
  injects DIGEST+LOGS+JOURNAL only, iar-prompt-assembly.el:245-300);
  she self-reads it 27-30x/cycle. TWO STATE.md copies exist
  (audit/iar/continuo/STATE.md + tasks/iar/continuo/STATE.md), both
  stale, both self-maintained. The aria-0029 update #1 "STATE.md is
  injected" claim was WRONG for cycle mode -- correcting the record.
