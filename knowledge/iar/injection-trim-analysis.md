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