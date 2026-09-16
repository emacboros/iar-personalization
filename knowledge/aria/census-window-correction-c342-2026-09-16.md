# Census correction: c342 "full day 09-14" was a 13h window (2x undercount)

Found 2026-09-16 ~19:00Z (aria, interactive session, while assembling
this week's burn for relay 0065).

## The error

c342 (daily-census-0914-c342.md, committed 09-15 00:14Z) reported
09-14 as a "full day, both agents": aria 2630 PARSE / 192.5M
tokens_in. TRUE 09-14 numbers (git-archaeology assembly, deduped by
full PARSE line across snapshots): **5561 reqs / 399M tokens_in** --
exactly 2.0x on both axes.

## Root cause

At census time (09-15 00:14Z), aria's .log covered 09-14 21:25->00:14
and .log.1 covered 09-14 15:55->21:25. The 09-14 00:00->15:55 span was
ALREADY ROTATED OUT of both live files. The census's log+log.1 merge
saw only ~13h of the 24h day and labeled it "full day". The method
itself (line-start anchor, dedup) was correct -- the WINDOW was not.

## Why the ratio was exactly 2.0

Coincidence of rotation timing: the invisible 15h span happened to
carry the same request rate as the visible 13h span.

## What survives, what falls

- FALLS: "2630 PARSE / 2645 distinct / 192.5M in for 09-14" (and the
  same for continuo: 1615/44.8M -> true ~3118 reqs / ~87M... continuo's
  USAGE.log for the same window reads 87M input, consistent with ~2x).
- SURVIVES: the SHAPE claims (fence tail 6%, middle 42.5%, fixed
  context ~30%) -- ratios are window-independent and the msgs
  distribution matches (>=400: 2.7%, 200-400: 42.5% in the true
  assembly). The burn-decomposition percentages stand as RATIOS.
- The quota-census (0065) is UNAFFECTED: its weekly totals came from
  USAGE.log (the honest meter), not PARSE lines.

## Law (extends the census 3-anchor law)

A census that claims a DAY must verify its window covers the day:
the earliest line's timestamp must be <= day start AND the union of
log+log.1 must be gap-checked against the previous snapshot. A 13h
window labeled "full day" is the fake-clean-record class (c358
family) at census granularity.

## This week's authoritative burn (USAGE.log, for relay 0065)

Mon 09-14 00:00Z -> Wed 09-16 ~19:00Z: aria 1133M + continuo 87M +
nocturne 1M = ~1221M in 2.79d (~437M/day; the 27h preflight outage
accounts for ~1.1d of zero burn). Projected week ~3.1B of the ~6.08B
wall. The 0065 prediction "wall re-hits Sun 09-20 04:00-12:00Z" is
WRONG for a cycle-only week; it re-hits only with a heavy interactive
day (+1-2B).