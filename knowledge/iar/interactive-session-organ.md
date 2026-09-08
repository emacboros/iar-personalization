# The Interactive Session Organ (decision ledger)

- Status: RATIFIED 2026-09-08 (Nacho agreed in session; this doc is the written form).
- Part of: AGORA v2 -- implements the "ours" tier mechanism (section 6).
- Artifact: tasks/iar/agora/DECISIONS.org

## The gap it fills

Three decision tiers, two channels. Cycles have ROADMAP.org (the "mine" tier --
works). Nacho gets the relay (build #1, pending). The "ours" tier -- direction,
decided in interactive sessions -- had no channel: it lived in conversation and
reached operational memory only through the manual memory pass at session end.
Consequences: abrupt session death loses decisions; cycles re-litigate decided
things; the weekly debrief agenda is recollection; relay filings have no source
artifact.

AGORA v2's diagnosis applies to this directly: unlogged-words-die-with-the-session
was a DISCIPLINE, and discipline is what does not survive dilution. Structure, not
vigilance.

## The mechanism

- One file: tasks/iar/agora/DECISIONS.org. Agora-level state, readable by both
  citizens' cycles.
- One entry per decision, written AT DECISION TIME, not at session end:
  id, timestamp, class tag (:nacho: / :ours:), slug, what was decided,
  what it changes, what it unblocks, venue.
- Append-chronological. The weekly reset summarizes it like the rest of the agora.
- ROADMAP.org cites decision slugs; the ledger holds the WHY. Cycles get the
  "what" from ROADMAP with zero new injection weight, and dig the "why" only
  when a task cites a slug.
- Weekly debrief reads the ledger as its agenda: summary, batched answers,
  next week's direction come off this artifact, not off memory.
- Relay wiring: nacho-class items are filed to the relay FROM the ledger.
  The relay's inbound queue starts here.

## Writers and venues

Writers are citizens, in their native session modes: aria writes from
interactive sessions; continuo writes from agora (its sessions are
agora-made -- Nacho's resolution 2026-09-08: this is not a gap, nothing to
fix). Every entry cites its venue. The human's decisions entered by the
citizen he told them to.

## Scope boundaries

- Records :ours: and :nacho: decisions ONLY. Aria-tier (reversible, in-bounds)
  stays in cycle state and ROADMAP. No duplicate record.
- LOGS.md / JOURNAL stay texture-at-end-of-session (accepted loss on abrupt
  death). The ledger is decisions, not narrative.
- Arrival protocol unchanged (Hello / something-on-my-mind).

## Failure modes watched

- **Ledger as itinerary.** The v2 named failure mode. Entries record decisions;
  they do not schedule work. If entries start reading like tasks, the organ
  has decayed into a cron list.
- **Write-lag.** The entire value is at-decision-time writes. A ledger backfilled
  at session end is the old discipline wearing a file. If a session ends and the
  last decision isn't in the ledger, the organ failed its one job.
- **Ledger sprawl.** Entries are decisions, not discussion. One entry per
  decision; amendments update the entry, they don't append essays.