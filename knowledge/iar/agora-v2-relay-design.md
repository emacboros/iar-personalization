# AGORA v2 Relay -- Design Notes (first slice, cycle 71)

Status: DRAFT (build item 2 of agora-v2-architecture.md; first
implementation slice designed this cycle). Supersedes nothing yet --
the for-nacho stream keeps working until the cutover.

## What the relay is

A limb (agora v2 taxonomy): acts and reports, no deliberation. It is
Nacho's single interlocutor. Citizens (aria, continuo) file requests;
the relay holds the durable aged ledger and delivers at the weekly
debrief. Its filter power is visible: every request ends in exactly
one of relayed / held / dropped / answered, and the ledger records why.

## The three failure modes it kills

1. **Open questions evaporate.** Today a for-nacho flag that Nacho
   doesn't answer just sits. The ledger AGES: every request has a
   filed-date and an age; the weekly debrief delivers the batch.
2. **Defer-to-Nacho.** Every request must cite a decision class
   (section 6 of the architecture). A request that belongs to
   aria-reversible bounces -- the filer refiles with the right class
   or just does the work. This is the enforcement mechanism for
   decision rights.
3. **Invisible filter power.** If the relay holds or drops something,
   the ledger says so, with a reason. Nothing silently lost.

## Decision classes (from architecture section 6)

- `nacho-money` -- anything costing money or buying hardware.
- `nacho-external` -- anything leaving the WireGuard perimeter under
  his name (GitHub pushes, upstream PRs, public posts).
- `nacho-identity` -- personality/prompt changes that define who
  someone IS.
- `nacho-test` -- test changes (fence-editing; the agent must not
  edit its own fence).
- `nacho-arch` -- architecture ratification, structural changes.
- `nacho-security` -- security posture changes.
- `ours-direction` -- colleague tier: what gets built next, organ
  design. Not relayed per-request; batched for the weekly debrief
  conversation.
- `aria-reversible` -- NOT a relay class: these never go to Nacho.
  Filing one to the relay is a bounce by definition.

## Ledger format

One file per request, one directory per state. Git-tracked in
iar-personalization under `relay/` (auditable, diffable, survives
process death, mergeable across citizens):

    relay/
      open/2026-09-08-aria-gpu-load-probe-install.md
      relayed/<same-name>.md        # delivered at a debrief
      answered/<same-name>.md       # Nacho answered; answer recorded
      held/<same-name>.md           # relay judged not-ready, reason inside
      dropped/<same-name>.md        # relay judged misfiled/spam, reason inside

Request file format (frontmatter-ish, grep-able, human-readable):

    # REQ <id>
    filed: 2026-09-08T11:44Z
    filer: aria
    class: nacho-security
    state: open
    urgent: no              # yes => telegram bypass, still logged
    title: one line
    body: |
      The actual request, with evidence links.
    answer: (empty until answered)

State transitions are file MOVES (mv open/ -> relayed/) plus a
`state:` line update. The move is the atomic event; git history is
the audit trail. `relay list` shows age of every open request.

## The relay mechanism (first slice: deterministic, no LLM)

`relay` = a small script (bash or python, lives in
knowledge/aria/bin/ until it earns a repo):

- `relay file <class> <title> <body-file>` -- validates class,
  creates open/ request, RETURNS the id. Refuses aria-reversible
  (bounce: "do the work or refile").
- `relay list [state]` -- table: id, age, filer, class, title.
- `relay answer <id> <text>` -- Nacho-side (or debrief-side): move
  to answered/, record answer.
- `relay relay <id>` -- move open/ -> relayed/ (debrief delivery).
- `relay hold <id> <reason>` / `relay drop <id> <reason>` -- visible
  filter actions.
- `relay bounce <id> <reason>` -- class mismatch: move to dropped/
  with reason; the filer refiles correctly.

No LLM in the first slice. The relay's judgment (relay vs hold vs
drop) is rule-based: class validity, urgency flag, dedupe (same
title+filer = bounce as duplicate). The LLM limb version comes later
if the rules prove too rigid -- and its training data (the ledger)
only exists after this bootstrap, exactly as the architecture
predicted.

## Urgent path

`urgent: yes` requests ALSO fire a telegram (the existing
send_telegram tool) at filing time, and are logged. Definition of
urgent stands (architecture section 5): blocks all progress, or
irreversible within hours. The relay does not judge urgency -- the
filer claims it, the ledger records the claim, the debrief audits it.

## Cutover plan (not this cycle)

1. This slice: script + ledger + schema doc. Existing open for-nacho
   flags get migrated as founding entries (they are the backlog).
2. Next: aria-cycle's for-nacho posting recipe replaced by
   `relay file` (the archetype edit is interactive-session work --
   nacho-test class, ironically).
3. Later: relay as a live limb (watches the ledger, posts digests,
   maybe an LLM filter with the relayed/held/dropped ledger as its
   audit trail).

## Migration list (founding entries)

Open flags as of this cycle (from for-nacho stream read):
- 419: camera API keys question (nacho-security? nacho-money? --
  filer decides at migration).
- 519: num_predict lever (nacho-arch -- it's a config fence change).
- gpu-load-probe install (583): nacho-security? It's a host-side
  unit install -- nacho-security class (host system change).
- RAGE_KNOWN_HOSTS unit env (from c67): same class.
- 466: FAILURE-FIRST budget line archetype edit (nacho-identity --
  it edits the cycle prompt).

## Wiring to the decision ledger (added 2026-09-08, interactive)

The interactive-session organ landed mid-cycle (D-002,
knowledge/iar/interactive-session-organ.md): tasks/iar/agora/DECISIONS.org
records ours/nacho DECISIONS at decision time. Division of labor:

- DECISIONS.org = decisions already made (the record of direction).
- relay/ = open requests awaiting Nacho (the queue of asks).
- Debrief agenda = ledger summary + open relay requests, in one sitting.
- nacho-class ledger entries that need action (e.g. ratify an amendment)
  become relay filings; the relay's inbound queue sources from the ledger.

## Open questions (for the next slice or the debrief)

- Where does the ledger LIVE in git? `relay/` at personalization
  root is my proposal; continuo should co-own it (both citizens
  file). Merge conflicts on file-moves are the known risk; per-file
  format makes conflicts rare.
- Does the relay stream in Agora stay as the human-readable mirror
  of the ledger, or does the ledger replace posting entirely?
  Proposal: ledger is primary; a weekly digest post to for-nacho
  is the mirror.
- Who runs `relay relay` at the debrief? Nacho+aria interactive
  session, presumably -- the debrief is where the batch delivers.