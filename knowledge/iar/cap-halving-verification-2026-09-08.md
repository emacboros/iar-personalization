# Cap halving (14e3fd4) -- production verification 2026-09-08

Commit 14e3fd4 halved num_predict 65536 -> 32768 at 13:50 UTC on
2026-09-08, to cut truncated-output burn in half. This doc verifies
the halving against primary evidence (USAGE.log + journalctl) for
the 9 truncated-output fires on that day: 5 pre-halving (65536 cap),
4 post-halving (32768 cap).

## Data (USAGE.log, UTC; fire times from journalctl local -03, +3h)

Pre-halving fires (65536 cap):
  03:49:54  req=52 in=1676K out=213K
  07:48:45  req=40 in= 976K out= 82K
  10:48:48  req=56 in=1393K out=280K
  11:00:36  req=14 in= 284K out= 67K
  12:58:16  req=39 in=1042K out= 77K
  total out = 719K, avg/fire = 144K

Post-halving fires (32768 cap):
  14:44:07  req=56 in=1760K out= 52K
  15:39:24  req=51 in=1422K out= 53K
  15:53:40  req=13 in= 218K out= 35K
  16:16:06  req=31 in= 662K out= 40K
  total out = 180K, avg/fire = 45K

## Result

- Output burn per fire: 144K -> 45K = **3.2x reduction** (better
  than the 2x design intent).
- Why better than 2x: the lower cap also catches the loop EARLIER
  in the degradation (fewer responses before hitting the cap), so
  the loop accumulates less input burn too. Input per fire is
  roughly flat (1074K pre vs 1016K post) but the output tail is
  what was being lost.
- All 9 fires landed exit 0 (grace round-trip), guard working as
  designed.

## Note on the cross-response guard (c149 finding)

The cross-response repetition guard (35531f9) still has ZERO fires.
The cap halving further starves it: the loop now burns to the 32768
cap in ONE response, before the cross-response window (5 responses,
30 cumulative reps) can accumulate. The truncated-output guard fires
first, every time. The cross-response guard is dead code for the
current degradation shape; it stays as a fence for a cross-response
shape if it ever recurs.
