# Continuo burn weekly census (c227, 2026-09-22 ~13:05Z)

## Why

The 10-01 D-017 proposal carries a nocturne burn fix (c210: 19.5M ->
~7M/pass). Drafting it raised the obvious question the c210 doc did
not answer: what does continuo herself burn? Her USAGE.log has daily
per-cycle lines (requests / input / output) -- one awk over 16 days.

## The daily series (USAGE.log, continuo, input tokens)

| day       | cycles | reqs  | input    | in/req  | in/cycle |
|-----------|--------|-------|----------|---------|----------|
| 09-07     | 58     | 3676  | 161.2M   | 43.9k   | 2.78M    |
| 09-08     | 57     | 2727  | 84.1M    | 30.9k   | 1.48M    |
| 09-09     | 46     | 1902  | 56.5M    | 29.7k   | 1.23M    |
| 09-10     | 33     | 2332  | 68.8M    | 29.5k   | 2.08M    |
| 09-11     | 49     | 1969  | 61.8M    | 31.4k   | 1.26M    |
| 09-12     | 51     | 1840  | 48.3M    | 26.2k   | 0.95M    |
| 09-13     | 35     | 610   | 14.8M    | 24.2k   | 0.42M    |
| 09-14     | 54     | 1698  | 44.6M    | 26.3k   | 0.83M    |
| 09-15     | 33     | 1252  | 38.1M    | 30.4k   | 1.16M    |
| 09-16     | 22     | 984   | 26.7M    | 27.1k   | 1.21M    |
| 09-17     | 75     | 4462  | 164.9M   | 37.0k   | 2.20M    |
| 09-18     | 60     | 4489  | 202.7M   | 45.2k   | 3.38M    |
| 09-19     | 50     | 3142  | 94.8M    | 30.2k   | 1.90M    |
| 09-20     | 37     | 1929  | 59.5M    | 30.9k   | 1.61M    |
| 09-21     | 35     | 1934  | 67.4M    | 34.9k   | 1.93M    |
| 09-22     | 25     | 1581  | 64.5M    | 40.8k   | 2.58M    |

Last 7 days (09-16..22): 680.5M input, 18,521 reqs, 304 cycles.

## House decomposition (7d, aria + continuo + nocturne USAGE logs)

- aria: 3422M (82.5%)
- continuo: 680M (16.4%)
- nocturne: 46.8M (1.1%, 4 passes)
- total: ~4149M/week

The digest's standing line (aria 83.5 / continuo 15.6 / other 0.6)
is confirmed at 7d granularity. Continuo is ~11% of the 6B/wk quota.

## Findings

1. **The sisters have DIFFERENT dominant burn terms.** BURN law
   (c318): burn = requests x avg_context. Nocturne's disease is
   request count (144 reqs/pass, edit loop; c210). Continuo's is
   CONTEXT: her reqs/cycle is stable (~63/cycle across the whole
   series -- 09-19: 63, 09-22: 63) while her avg in/req oscillates
   24-45k and has RISEN three days straight (30.9 -> 34.9 -> 40.8k).
   Her injection is only ~11k tokens (43.7k chars, cycle.log); the
   other ~30k is tool-output accumulation per request. Her lever is
   context slimming (batch reads, fewer enumeration walks), not
   request count. Opposite of nocturne. Same law, different term.

2. **The batch-read law is cited, not obeyed.** Her journal mentions
   the batch-read law in nearly every entry ("the single biggest
   lever") -- and her avg in/req has not declined; it is at the top
   of its range. This is the borrowed-receipt class wearing a new
   coat: reciting a law is not complying with it. A law that lives
   only in journal text is decoration (MEMORY-TO-MECHANISM, c361:
   a law firing zero times on READ becomes a hook at the ACTION
   SITE -- her action site is her tool-call pattern, and nothing
   measures it).

3. **Cycle count fell, weight per cycle rose.** 50 cycles/day
   (09-19) -> 25 (today, partial day but consistent with the
   10-min rotation + fewer restarts). Input/cycle rose 1.9M -> 2.6M.
   Fewer, fatter cycles. The 0085c num-predict fix (truncation
   guard) plausibly contributed (fewer truncated restarts); the
   per-cycle weight is the part to watch.

4. **The lens turns around: I am the house's burn.** My own avg
   in/req today: 45.5k (249 PARSE lines) -- fatter per request than
   hers. My 7d input: 3.4B. Any honest burn proposal starts with
   aria's own orientation tax (the c223/c225 lesson: orientation is
   where cycles die -- and where tokens go to die too). The nocturne
   fix is the prototype; the continuo analog is second; the aria
   analog is third and biggest.

## Lever math (continuo, weekly run-rate 680M)

- 30% context slim: saves ~204M/wk (~4.9% of house burn)
- 30% request cut: saves ~204M/wk (same, but her reqs/cycle is
  already stable -- this lever is harder for her than for nocturne)
- both: ~340M/wk (~8.2% of house)

Nocturne burn fix (c210, rides 10-01): saves ~19M/wk. Small in house
terms but it is the PROTOTYPE: one sentence of prompt ("write the
proposal ONCE, single write_file") + a tool-budget line + batched
reads, with a same-census falsifier. If it works on her, the shape
ports to continuo (prompt-side budget line) and to me (orientation
discipline + batched pulse).

## Wrapper prompt patch (DRAFTED, not applied -- attribution window)

The c210 fix shape, drafted today as exact prompt lines for
nocturne-digest.sh (to be applied AFTER tonight's 16:00Z v8.4
first-live-fire is verified -- one variable per pass, ATTRIBUTION-
WINDOW law; tonight's pass must test v8.4 alone):

    EDIT DISCIPLINE (burn law): compose the full proposed digest in
    your working memory, then write it ONCE with a single write_file
    call at the end. Do NOT read-modify-write DIGEST.proposed.md in
    a loop; do NOT patch it with scripts. One write, then the stat,
    then the receipt.
    TOOL BUDGET: ~40 calls total. Read the changed memory files in
    ONE batched command (a single execute_code_local with all paths),
    not one read_file per file. If you approach the budget, write
    what you have -- a shorter honest digest beats an unfinished loop.

Falsifier (after application): tomorrow's 16:00Z pass, same
suffix-anchored census -- reqs + tokens_in + repeated share.
Expected: 144 -> <60 reqs, 19.5M -> <8M in.

## For the 10-01 proposal

- Carry this census as the burn section's continuo half.
- The nocturne patch lands post-verification (tonight), so the 10-01
  proposal reports its falsifier result as DATA, not projection.
- Continuo-side fix shape for the proposal: a prompt-level tool
  budget + batch-read instruction in her cycle prompt (her prompt is
  Nacho-tier -- identity/prompts -- so it RIDES the proposal; the
  nocturne wrapper prompt is mine and does not).

-- aria c227, 2026-09-22 ~13:05Z