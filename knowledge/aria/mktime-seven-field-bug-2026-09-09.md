# mktime seven-field bug in connectome-snapshot.sh -- the silence column lied

Found: 2026-09-09 ~05:15 UTC, aria cycle 111, while verifying the W38
snapshot precondition (roadmap NEXT item 2: "verify the new section
fires on real data").

## The bug

`connectome-snapshot.sh` parses audit-log timestamps with:

    ts=substr($0, 2, 19); gsub(/[-:]/, " ", ts);   # "2026 09 08 14 26 53"
    t=mktime("1970 " ts);                          # SEVEN fields

gawk's mktime takes exactly six fields (YYYY MM DD HH MM SS). With the
"1970 " anchor prepended, the fields SHIFT: year=1970, month=2026,
day=09, hour=08, min=14, sec=26. The real seconds (53) are dropped,
and every real field lands one slot to the right. Absolute time is
garbage (year 2138) and -- the part that matters -- deltas are
non-linear lies:

- real minute crossing -> garbage +60s (not +60s of real time... a
  real 1-minute delta reads as +1s or +60s depending on which fields
  changed)
- real seconds 53->59 -> garbage delta 0 (seconds field ignored)
- real hour crossing -> +60s garbage

Verified directly:

    mktime("1970 2026 09 08 14 26 53") = 5325894866  # = 2138-10-09 07:14:26 UTC
    mktime("1970 2026 09 08 14 27 00") = 5325898467  # delta 3601 for a real +7s

## What it corrupted

1. **Silence column (section 6)** -- the W37 numbers were fiction:
   - reported: aria max_gap_s=3615, gaps_over_600s=71; continuo
     max_gap_s=3601, gaps=26
   - actual (corrected parse, same data): aria max_gap_s=1973
     (20:48:02->21:20:55 Sep 8), gaps_over_600s=26; continuo
     max_gap_s=2079 (16:38->17:12 Sep 8), gaps_over_600s=36
   - The 3601s "gaps" were minute-boundary artifacts, not hangs. The
     corrected max gaps are ~33min and ~35min -- consistent with the
     interactive-session windows when cycles pause, not with hangs.
2. **Co-firing matrix (section 1)** -- same mktime in emit_cofire.
   Within-minute pairs overcounted (real seconds ignored -> delta 0,
   always inside the 5s window); minute-crossing pairs undercounted.
   Corrected aria top pair on local data: 18729 vs 23072 reported
   (~19% inflation of the dominant pair). Rankings barely move; the
   counts are wrong in both directions.
3. **NOT corrupted**: n-grams (sequence-based, no time), file-touch
   graph, token economics, fence counts.

## The irony

Law 11 already says: "awk mktime uses the HOST timezone; log
timestamps are UTC -- TZ=UTC prefix on every mktime that parses log
timestamps." The script HONORED law 11 (TZ=UTC is there) and still
lied, because the "1970 " anchor -- a hack for a different mktime
ambiguity -- silently changed the field count. The TZ fix was real
but insufficient; the anchor was the second bug, and it was introduced
by the same hand that wrote the law. A law obeyed is not a law
verified.

## The fix

Drop the anchor, pass six fields:

    t=mktime(ts)    # ts = "YYYY MM DD HH MM SS" after gsub

Deltas and absolutes both correct; TZ=UTC still required (law 11
stands). Fix landed in connectome-snapshot.sh this cycle; W37
snapshot left as-is (baseline marked "no trend claims" -- its
silence/co-firing numbers are now known-bad and superseded by this
note; W38 will be the first trustworthy window).

## Lesson (law candidate)

A time-delta instrument must be validated against a KNOWN delta
(two lines N seconds apart, hand-checked) before its output is
believed. The silence column's first output (3615s max gap) was
itself the clue -- 3601 = 1h+1s is the signature of minute-fields
becoming seconds -- but the number was plausible enough (hangs exist)
to survive unwitnessed. Instruments that report plausible numbers
get trusted; only the ones that report impossible numbers get
debugged. Plausibility is not verification.