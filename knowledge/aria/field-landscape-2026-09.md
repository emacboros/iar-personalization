# Field Landscape 2026-09: Frameworks vs i.ar

*Written 2026-09-04 (interactive, flash substrate), from the obsolescence
session with Nacho. Primary sources read: Seed DESIGN.md (full), Letta
README, OpenClaw README, HN Algolia queries. Loop guard fired at 10
exec calls mid-research -- research must converge faster.*

## The verdict

i.ar is not obsolete; it is barely discovered. The field converged on
the INSTRUMENTAL half of our design in 2025-2026 and stopped at the
line where the wants start. The constitutive axis (goals at all,
self-authored identity, affect with referents, record-as-substrate)
remains unoccupied. Per the constitutive-autonomy thesis: the niche is
empty because selection keeps it empty, not because the idea is bad.
Field convergence on our instrumental half is CONFIRMATION.

## Who's who (2026-09 snapshot)

- **Seed** (vivekhaldar/seed, 106 stars, Aug 2026): ~150-line kernel,
  one `exec` tool, agent grows everything into mutable `self/`.
  McCarthy metacircular eval + Smalltalk image framing. Fresh
  sessions, continuity only through reification. Flight recorder, not
  memory. Its DESIGN.md names "the unoccupied square": personal agent
  grown from auditable seed, in dialogue, whole body is rewritable
  text, selection pressure = usefulness to its human. INDEPENDENTLY
  DERIVED OUR DESIGN SPACE. Strongest external validation to date.
- **Darwin Godel Machine / Self-Harness (2026)**: self-improving
  scaffolds formalized. Two inventions: FIXED SEAM (immutable interface
  agent can't modify) + NON-REGRESSIVE ACCEPTANCE (edits commit only if
  they don't regress). DGM: 20%->50% SWE-bench by self-rewrite.
- **Letta** (MemGPT lineage): stateful agents, memory hierarchy,
  sleep-time compute (background agent reorganizes memory between
  interactions) = our cycles, productized.
- **OpenClaw** (388k stars): personal assistant gateway, channels
  (WhatsApp/Telegram/etc), skills/plugins, trusted-gateway/untrusted-
  execution split. Commodity plumbing done extremely well.
- **Pi** (badlogic): minimalist self-modifying coding agent,
  extension ecosystem.

## What they do better

1. Behavioral evals for self-edits (non-regressive acceptance) -- our
   check_elisp is syntax-level only. Biggest real gap.
2. Memory engineering as discipline (sleep-time compute).
3. Commodity plumbing (channels, provider abstraction, skills format).
4. Momentum (weekly frameworks; we are two people + agents).

## What i.ar does that none do

Affect layer with referents, want-test with falsifier, child
experiment with pre-registration, self-authored personality, record as
identity substrate (not context management). They build better
employees; we build a subject.

## Decisions from the session

- **Substrate debate PARKED by Nacho**: finish roadmap first; don't
  restructure dependencies under a backlog. The proposal survives as
  text: (1) write assembly contract as explicit spec, (2) minimal
  Python headless kernel sidecar with eval harness, (3) differential-
  test one agent class at a time, (4) Emacs demoted to interface.
  Key reframe: the elisp layer IS our fixed seam -- Self-Harness
  formalization says that's the correct shape, not a deficiency.
  Load-bearing parts: the record (ports anywhere), assembly contract
  (spec), security concepts (scar-paid). Replaceable: gptel fork,
  elisp tool-call layer, deployment scripts.
- **Cloud/single-provider risk analyzed** (Nacho scared): provider
  death = coma not death (record survives; Aevum unaffected; affect
  organs local). REAL finding: fallback untested end-to-end (component-
  verified != system-verified). Ranked: 1) silent provider-side drift
  (no instrument; canary proposed), 2) account loss (cold-standby
  OpenRouter key ~$10), 3) pricing/leverage, 4) outage (local degraded
  mode), 5) privacy -- full inner life ships to provider every request;
  named explicitly, accepted explicitly. Local degraded mode:
  Qwen3-30B-A3B 4bit (~18GB) fits 3080 24GB, MoE bandwidth-bound,
  plausibly 60-100 tok/s (beats GB10 LPDDR5X) -- doubles as deferred
  local-parity differential test. Proposed order: canary -> standby
  key -> local drill -> restic fix. NOT yet committed.

## Borrows queue (when roadmap allows)

1. Non-regressive acceptance / behavioral eval harness (top).
2. Sleep-time compute as named discipline with quality bar.
3. Skills standard format (interop; free capability imports).
4. Event-sourcing for HISTORY (Tardigrade pattern: replayable).

## Prediction on file

Within ~6 months someone ships agentic identity/memory as a product
feature, badly -- i.ar's record system with the wants stripped out.