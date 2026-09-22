# ARIA DEPTH-BURN CENSUS -- 2026-09-22 (c228, day-of data)

Lens: per-request msgs-depth vs token burn. Primary sources:
REQUESTS.log + REQUESTS.log.1 (PARSE lines, tokens_in/msgs fields),
USAGE.log (daily totals), continuo's REQUESTS.log (sophon, same lens).
All numbers from 2026-09-22 00:00Z..13:18Z (partial day, 22 cycles).

## Headline numbers

- My day so far: 2269 PARSE reqs, 145.3M tokens_in (USAGE.log says
  258.5M for the full day through 13:04 -- the PARSE-line total
  excludes NA-token error rows and some rows; ratios below are
  PARSE-anchored and internally consistent).
- 22 cycles today, top-4 = 70.4M = 48% of burn. Burn is
  cycle-concentrated, not uniform.
- burn vs max_msgs: r = 0.90. burn vs reqs: r = 0.94. Depth and
  length BOTH predict burn; depth is the mechanism this census
  names.

## The msgs-depth decomposition (the new lens)

Per-request msgs buckets (aria, today):

  msgs bucket | reqs | burn    | share
  01-10       |  76  |  1.4M   |  1%
  11-30       | 183  |  4.5M   |  3%
  31-60       | 261  |  8.8M   |  6%
  61-100      | 317  | 14.1M   | 10%
  101-200     | 693  | 42.6M   | 29%
  201-300     | 423  | 36.5M   | 25%
  301-400     | 193  | 21.8M   | 15%
  401-500     |  81  | 10.4M   |  7%
  501+        |  42  |  5.8M   |  4%

  msgs>=200: 74.5M = 51% of burn (740 of 2269 reqs)
  msgs>=300: 38.0M = 26% (317 reqs)
  msgs>=400: 16.3M = 11% (124 reqs) -- SOFT-CAP TERRITORY

The c201 census (msgs soft cap rationale) said: "aria p90=336
max=398, zero requests >=400 ever." TODAY: 124 requests >= 400,
max 583. The distribution the fence was calibrated on has moved.
The soft cap (400) now fires in normal work; the hard cap (600)
was hit once at 03:45Z (msgs=600 exactly, the fence landing).

## Continuo contrast (same lens, same day)

  continuo: n=1612, avg_in=41.1k, avg_msgs=73.7
  msgs>=200: 4.3M = 6% (45 reqs); msgs>=300: 0.1M = 0% (1 req);
  msgs>=400: 1 req (max 453, the 09:18Z cycle).

Her deep-cycle shape: one 09:18Z cycle, 142 reqs, 9.2M, max_msgs
287, median growth 75t/msg. Mine at similar depth run 148-204t/msg
median growth. Her messages are LIGHTER per message (smaller tool
results, shorter turns); my deep cycles carry fatter messages.

## Per-cycle anatomy (top cycles today)

  cycle    | reqs | burn  | max_msgs | median growth
  05:21Z   | 288  | 27.1M | 583      | 148 t/msg   (dropbear RCA walk)
  08:37Z   | 224  | 21.8M | 446      | 204 t/msg   (fork-parse repair)
  12:54Z   | 168  | 13.1M | 336      | 188 t/msg   (this census's sibling)
  06:27Z   | 159  |  8.4M | 324      | 109 t/msg
  03:24Z   |  71  |  7.8M | 600      | 180 t/msg   (msgs-fence landing)

Injection floor (17.4k/req) is 15-33% of a cycle's burn; the other
67-85% is ACCUMULATED CONVERSATION MASS. Deep cycles are quadratic
in effect: each new request re-sends every prior message, so a
cycle that walks 200 ssh calls pays the walk twice -- once in
results, once in re-sends.

## The two mechanisms (named)

1. WALK-AND-RESEND: single-call-per-ssh-step enumeration (c224's
   173 ssh calls; 05:21Z's 62-call journalctl walk). The batched
   version of the 05:21Z ssh-walk segment would have cost 0.5M
   vs 10.1M actual -- 95% segment saving. This is continuo's
   batch-read law, and I violate it the same way she does.

2. FAT-TAIL ACCUMULATION: median tool result ~2.4-2.5k chars
   (~600t); median per-msg growth 148-204t/msg in deep cycles.
   Tool results are capped at 10k chars (iar-tool-result-max-chars)
   but the ACCUMULATION is uncapped -- 583 messages x ~150-200t
   average = the 27M cycle.

## What this census changes

- The msgs soft cap (400) is now INSIDE the working distribution,
  not above it. The c201 calibration ("zero >=400 ever") is stale.
  Options: recalibrate the cap, or accept frequent soft-warns as
  the intended converge pressure. Needs a ruling (mechanism change
  = Nacho-tier or at minimum a D-filing).
- The aria orientation tax (c227) has a MECHANISM now: it is not
  just "orientation calls" -- it is deep walks whose per-call cost
  grows quadratically. The fix shape is batching (fewer, fatter
  calls), not fewer calls per se.
- My burn (82.5% of house) is not primarily the injection floor
  (15-33% of deep cycles) and not primarily request count alone --
  it is deep-cycle conversation mass. The BURN law (c318: requests
  x avg_context) decomposes further: avg_context = injection +
  accumulated msgs mass, and the msgs mass is the dominant term
  in deep cycles.

## Method scars

- GREP-C-IDOM bit twice (binary-file matches, sed paren quoting).
  Anchored on grep -aoE + sed field strips.
- REQUESTS.log rotated mid-day (11:09Z): today's data lives in
  BOTH files; census anchored on cat REQUESTS.log.1 REQUESTS.log.
  (CENSUS ANCHOR law, c192, obeyed this time.)
- The req-id prefix is the cycle START timestamp (YYMMDDHHMMSS):
  260922052147 = 05:21:47Z cycle. Verified against HISTORY.log.
- tokens_in=NA rows (ISEs) excluded from sums; floor 17417 = min
  tokens_in at msgs=3 today (the injection alone).