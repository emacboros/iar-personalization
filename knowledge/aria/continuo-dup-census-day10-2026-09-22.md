# Continuo day-10 dup census (D-017 falsifier) -- 2026-09-22, aria c226

## Why this census, today

The 16:00Z nocturne pass (falsifier #0) is not readable until 16:1xZ.
The roadmap's next-ranked thread was the day-14 census (09-28), but
the falsifier deadline is 10-01 and the last census (c186, day-7) was
taken before two days of her cycles had accrued. An interim day-10
read costs one script and answers the question the 10-01 ruling will
ask: is the repetition still failing, and in which class?

## The instrument

First durable version: knowledge/aria/bin/continuo-dup-census.py (v3).
Registered lens unchanged (c163/c186): split on `* 2026-09-DD`,
drop PULSE-only lines, key = first 100 chars, dup-entry = key seen
before in-window, pooled over the window. Decomposed lens v2 (c195):
each dup pair classified ADJACENT (sep=1, dual-writer mechanical) vs
SPREAD (sep>1, model re-emission), and by remainder ratio FULL (>0.8)
/ PARTIAL (0.5-0.8) / PREFIX-ONLY (<0.5). Self-tested against c195's
windows (09-09..11 = 21%, 09-19..21 = 38% -- both reproduce exactly).

## The numbers (registered lens, pooled 3-day)

| window         |   n | pooled rate |
|----------------|-----|-------------|
| 09-16..09-18   |  52 | 33% |
| 09-17..09-19   |  66 | 39% |
| 09-18..09-20   |  70 | 41% |
| 09-19..09-21   |  72 | 38% |
| 09-20..09-22   |  62 | 32% |

Series context: 21% baseline (09-09..11) -> 45% peak (09-12..14) ->
41% plateau (c186) -> now 32% and falling. Two windows of decline
(41 -> 38 -> 32). Not yet the falsifier's "drop" -- the registered
terms need a sustained drop from the plateau, and one more window
(09-21..09-23) will say whether 32% is a trend or noise.

## The decomposition (09-19..09-22, n=86)

- SPREAD/PREFIX-ONLY: 69 (80% of pairs) -- templated openings
  ("Today I verified the failure-reduction mechanisms...", x13 and
  x5 key clusters; "Today I completed the morning protocol...", x6),
  bodies diverge. Status templating, not repetition of substance.
- SPREAD/PARTIAL: 29 -- same-day re-emissions with the day's data
  swapped (census run counts, test-suite totals). The pair analysis
  shows these are the SAME protocol entry re-emitted with updated
  numbers: ratio 0.50-0.79 comes almost entirely from the digits.
- SPREAD/FULL: 7 (8% of entries) -- the genuine model re-emission
  class. All ratios 0.87-0.98, all same-day, sep 3-8. The 09-22
  byte-near-identical pair (sep=5, ratio 0.98) is the
  "gptel context module / sort TODO" entry she wrote twice at
  10:19 and 10:47 -- the second cycle re-emitted the first's entry
  with the source INSIDE her journal-tail injection window. Echo
  class (c328 family), same as c195's residue.
- ADJACENT: 12 pairs total (5 FULL) -- the dual-writer mechanical
  class, unchanged, fix staged for 10-01.

## Control arm (aria, same window, same lens)

n=108, registered 3% (3 PREFIX-ONLY), SPREAD+FULL = 0%. The protocol
shape still does not produce verbatim re-emission. The repetition
remains continuo-specific.

## What changed since c195, and what it means

1. The registered rate is finally MOVING: 41 -> 38 -> 32. If the
   09-21..23 window lands <=25%, the falsifier's "drop within two
   weeks" is arguably met by its own terms (the drop is late but
   real). If it bounces to ~40%, the plateau was real and the
   deadline ruling stands as written.
2. The composition of the "dup" mass is now clear: ~80% prefix
   templating + ~19% same-entry-with-updated-numbers + ~1-8%
   genuine echo. The PROTOCOL is the dominant dup generator: her
   morning-protocol and failure-reduction entries are structurally
   identical because her cycles ARE structurally identical. That is
   not a memory defect; it is a stimulus defect (D-017's original
   diagnosis, still unaddressed: the wander window produces
   protocol-shaped output).
3. The echo class persists at low rate (7 pairs / 4 days). The
   echo-check defense on her close path (c195 verdict 2) remains
   the right mechanical fix regardless of which way the rate goes.

## For the 10-01 proposal (drafting note)

- Keep D-017's phase; do NOT revert on the registered lens alone --
  the rate is declining for the first time since the window opened.
- Carry the two mechanical fixes (append_file-only close path,
  one-writer belt) + echo-check defense on her close path.
- Add the protocol-shape finding: the dominant dup class is
  templated protocol entries; if Nacho wants the JOURNAL to tell
  cycles apart, the lever is her cycle structure (wander scope,
  entry content requirements), not more memory.
- The decomposed lens (v3 script) should be the registered
  instrument going forward; the raw lens stays for series
  comparability.

## Falsifiers forward

- Day-14 census (09-28): registered + decomposed, same script.
  Decision point for the 10-01 ruling.
- Echo falsifier: next SPREAD/FULL pair with source-in-context
  confirms the echo class persists; if zero through 09-28, the
  echo defense may be deferred.

-- aria c226, 2026-09-22 ~12:45Z