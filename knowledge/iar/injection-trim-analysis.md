# Injection Trim Analysis -- continuo cycle 9 (2026-09-03)
# Method: REQUESTS.log decomposition (aria + continuo, Sep 2-3) +
# journalctl "Assembled prompt" lines + file-size reconstruction.

## The measured numbers

### Injection floor (first request of each cycle, msgs=2)
- aria-cycle: 18,340 tokens (56,008 chars assembled prompt)
- continuo: 13,561 tokens (43,628 chars assembled prompt)

### Per-request re-send cost (linear fit, msgs<=120)
tokens = 21,344 + 172/msg -- the SLOPE is tiny (172 tok/msg);
the INTERCEPT is everything. Every request pays the floor.

### Burn decomposition (Sep 2 03:13 - Sep 3 05:08, deduped cycles)
- aria: 53 unique cycles, 3,380 requests, 147.6M prompt tokens
  - injection floor share: 62.0M = 42%
- continuo: 12 unique cycles, 708 requests, 23.9M prompt tokens
  - injection floor share: 9.6M = 40%
- COMBINED: 171.5M prompt tokens, ~42% is pure re-sent injection.

### Cycle shape (the other 58%)
- avg 64 requests/cycle (aria), 59 (continuo)
- top cycles: 166-227 requests (the capped-at-60 era: 62-req cycles
  cluster at ~2.0-3.0M each; cap=60 -> ~2.4M avg)
- cap 60->120 (00f8103) moves the ceiling to ~4.4M/cycle worst case.

## Where the aria floor's 56k chars go (reconstruction)

| Block | chars | notes |
|-------|-------|-------|
| docs/iar/ FULL (12 files) | 150,925 | #+KNOWLEDGE iar/ -- BUT measured prompt is only 56k chars, so docs/iar is NOT fully injected |
| docs/iar-prod FULL | 51,749 | same question |
| docs/infra FULL | 47,787 | |
| docs/user FULL | 11,732 | |
| DIGEST.md | 11,958 | injected FULL by design |
| JOURNAL tail 120 | 6,458 | |
| personality(aria) | 6,375 | |
| LOGS tail 120 | 6,125 | |
| archetype(aria-cycle) | 3,241 | |
| base_context | 1,156 | |

Reconstruction gap: measured 56,008 vs known-blocks sum 37,913.
Gap = 18,095 chars ~= the four knowledge dirs' _overview.md files
(4,995 + 9,792 + 4,563 + 1,176 = 20,526 with delimiters ~= gap).
CONCLUSION: iar--read-knowledge-files injects ONLY _overview.md
per label, not the full directory. VERIFY before acting.

## The levers, by measured leverage

1. CONFIRM overview-only injection (if full dirs were injected the
   floor would be ~65k tokens, not 18k). If confirmed, knowledge is
   NOT the problem -- stop looking there.
2. DIGEST.md 11,958 chars = ~3k tokens of the 18.3k floor = 16%.
   The digest pressure guard (warn 12k / hard cap 16k) exists;
   aria's digest sits just under warn. Diet is aria's to do
   (her file, her law) -- nudge, don't touch.
3. The REAL lever is request COUNT: 42% floor share x 64 reqs/cycle
   means batching (fewer, bigger tool calls) cuts the floor
   linearly. 64 -> 30 reqs halves total burn. This is prompt-side
   discipline (batch-read law), already in the archetypes.
4. Cap 120: worst-case cycle is now ~4.4M (was 2.4M at cap 60).
   Watch: if capped cycles return at 120, the cap is again killing
   healthy work -- the census's option (c) soft-warning design is
   the structural fix, still unlanded.

## What I did NOT change
Nothing. This cycle was measurement. The numbers say: knowledge
injection is already lean (overview-only), the digest is 16% of
floor, and request count is the dominant lever. The next
structural fix is the soft-warning cap (census option c), which is
interactive-session territory (core .el).
## CONFIRMED (primary evidence, iar-knowledge-loader.el:88-115)
Overview mode is real: if a knowledge dir has _overview.md, ONLY
that file is injected. All four iar/ labels have _overview.md ->
~20.5k chars total knowledge injection. The floor decomposition is
complete: 37,913 (memory+prompts) + 20,526 (knowledge overviews +
delimiters) ~= 58.4k ~= measured 56,008 (delta = delimiters/wrappers
estimate error). No fat left in knowledge injection.

## Revised lever list (final for this thread)
1. Request count is THE lever (42% floor share x 64 reqs/cycle).
   Prompt-side: batch-read law (already standing). Structural:
   soft-warning cap (census option c) -- interactive session.
2. DIGEST diet: aria's call, 16% of her floor. Nudge only.
3. Nothing else structural worth touching at current numbers.
   A well-behaved cycle (30 reqs) costs ~1.1M prompt tokens;
   10-min cadence x 2 agents = ~13M/hour worst case, ~6M/hour
   if cycles batch well. The runaway class (82M single cycle) is
   fenced (breaker + cap + chain guard). Remaining burn is the
   price of the cadence itself -- a Nacho-level tradeoff, not
   a machinery bug.
## Round 2 (2026-09-03, continuo c22): the overviews themselves

C20 trimmed iar-prod+infra overviews (-621 tok/req). Round 2 audited
ALL THREE iar-project overviews against the editorial rule (an
overview is an index, not a mirror of the full docs): a section with
a verified full-doc home compresses to one line + pointer; a section
with NO full-doc home stays.

- docs/iar/_overview.md 4995->2718 (archetypes/personalities/tools/
  modules/memory/security/agents -> agents.md/tools.md/modules.md/
  usage.md pointers)
- docs/iar-prod/_overview.md 7757->3588 (kept services table + ASCII
  diagram -- no full-doc home for either; rest -> deployment.md/
  security.md/architecture.md)
- docs/infra/_overview.md 4113->2583 (zulip block compressed but
  kept -- it has no full-doc home; rest -> overview.md/security.md)
- Drift fix: docs/iar-prod/architecture.md said "Cloudflare proxies";
  reality is Caddy-on-rammstein (deployment.md + infra docs agree).

Total: 16865->8889 chars = -7976 = ~1990 tok/req off the floor
(c20 was ~621). Key-fact preservation verified mechanically (82
facts across three files). Commit a5cd671.

Floor projection: continuo ~12.9k -> ~11k; aria ~17.7k -> ~15.7k.
Remaining floor is DIGEST + JOURNAL + personality + archetype +
tool schemas -- the structural residue. Next lever is request
count, not injection.

## Round 3 (2026-09-03, continuo c23): floor VERIFIED live + residue trim

Floor verification (REQUESTS.log, same-msgs comparison):
- continuo msgs=12: pre-diet median ~16.6k -> post-c22 14.40k = -2.2k
- aria msgs=10: pre median ~22.6k -> post (c39) 21.57k = -1.0k net
  (~-2k diet + ~+1k day-drift from DIGEST/JOURNAL growth)
Projection held within noise. Injection diet is LIVE in production.

Round 3 applied the same rule with fresh full-doc-home greps:
- infra: network table + key services + domains compressed (homes in
  overview.md 66-101, which is a superset). 2583->2284.
- iar-prod: hosting summary + MVP seed-tenants line compressed (homes:
  deployment.md 22-24/142-147/201/232, modules.md 85). 3588->3443.
- iar/: no cut -- already index-shaped (c22 did it right).
- Zulip block: grep confirmed NO full-doc home (version/stack/role/
  systemd unit exist ONLY in the overview). Marked in-file; a full
  doc (docs/infra/zulip.md) is the eventual home. Kept.
Total: 8889->8616 chars = -273 = ~68 tok/req. Diminishing returns --
the overviews are now genuinely index-shaped. Injection lever is
EXHAUSTED. Remaining burn = request count x cycle length (cadence
price, Nacho-level tradeoff).

Floor-share note: floor share of burn ROSE post-diet (continuo ~34%,
aria ~48% in the post-diet window) because cycles got SHORTER
(91->75 reqs aria), not because the floor grew. Floor share is a
function of cycle length too -- do not read its rise as diet failure.
