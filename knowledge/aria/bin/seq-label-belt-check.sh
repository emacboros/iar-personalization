#!/bin/bash
# seq-label-belt-check.sh -- verify cycle self-labels against the system counter.
#
# c217 (2026-09-22): aria cycles c213..c217 self-labeled seq+1 (derived from
# the digest ledger, violating SEQ-IS-THE-COUNTER). c219 (2026-09-22 08:37Z)
# recurred -- labeled itself c220 AND misquoted its own injection as "220"
# when bump-at-start semantics (iar-agent-cycle.el:1581, bump before
# assembly) mean its injection said 219. Behavioral fix ("trust the
# injection") did not hold. This is the mechanical belt.
#
# SEMANTICS (verified in code 2026-09-22):
#   iar--cycle-seq-bump fires at cycle START, before assembly. The injection
#   block reads the POST-BUMP value. So: injection value == my cycle number.
#   At cycle CLOSE (when this check runs), the file still holds MY number --
#   the next bump happens at the NEXT cycle's start.
#
# CHECK: the last cycle-label header in JOURNAL.org must equal CYCLE-SEQ.
#   Journal label styles: "## cN ..." and "* cN ..." (both observed).
#   HISTORY.log "cycle cN" mentions are secondary (close entries may lag).
#
# WHEN TO RUN: at cycle CLOSE, AFTER writing your own journal entry.
#   Mid-cycle (before your entry), the last label is the PREVIOUS cycle's
#   number and the seq already holds YOUR number -- an ALARM then is
#   EXPECTED, not a bug. At close, your label == seq, so OK is the only
#   honest pass. A mislabeling cycle alarms at its own close and can
#   fix its own journal before ending.
#
# Usage: seq-label-belt-check.sh [--fix-report]
#   Exit 0 = labels match (or no labels yet). Exit 1 = MISMATCH (alarm).

set -u
AUDIT="${IAR_AUDIT:-/root/personalization/audit/iar/aria}"
JOURNAL="$AUDIT/JOURNAL.org"
SEQFILE="$AUDIT/CYCLE-SEQ"

fail() { echo "SEQ-LABEL ALARM: $1"; exit 1; }

[ -f "$SEQFILE" ] || fail "CYCLE-SEQ missing"
SEQ=$(tr -d '[:space:]' < "$SEQFILE")
case "$SEQ" in ''|*[!0-9]*) fail "CYCLE-SEQ not a number: '$SEQ'";; esac

# Last cycle-label header in the journal (## cN or * cN; N = digits).
LAST=$(grep -aE '^(#{1,2}|\*) c[0-9]+' "$JOURNAL" 2>/dev/null | tail -1)
[ -n "$LAST" ] || { echo "SEQ-LABEL OK (seq=$SEQ): no journal labels yet"; exit 0; }
JN=$(printf '%s' "$LAST" | grep -oE 'c[0-9]+' | head -1 | tr -d 'c')

if [ "$JN" = "$SEQ" ]; then
    echo "SEQ-LABEL OK (seq=$SEQ, journal=$JN)"
    exit 0
else
    echo "SEQ-LABEL ALARM: seq=$SEQ but journal last label=c$JN"
    echo "  header: $LAST"
    echo "  LAW: injection value == cycle number (bump-at-start, before assembly)."
    echo "  NEVER derive from digest/journal ledgers; never trust a quoted"
    echo "  injection from a previous cycle's reasoning -- verify the file."
    exit 1
fi