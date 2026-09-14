#!/bin/bash
# stale-receipt-detector.sh v4 -- aria c314 (2026-09-14)
# Census instrument: catches claims in an agent's journal that re-assert
# events without a same-day trigger in that agent's cycle logs, and
# automates the borrowed-receipt check against the sibling's logs.
# NOT a fence -- a census feeding the repetition watch.
#
# Design: tasks/iar/aria/stale-receipt-detector/design-notes.org (c313)
# Laws obeyed: CLAIM-ANCHOR (c307 -- receipts anchor on event-bearing log
#   lines, not bare numbers), CENSUS-SELF-ECHO (c309), CENSUS-DAY (c305 +
#   clock law), CROSS-AGENT corollary (c306 -- borrowed receipts are only
#   visible from outside the claimant's log set).
#
# Usage: stale-receipt-detector.sh <agent> [personalization-root]
#
# Method (v4 -- shingle-based; v3's whole-line normalization never
#   matched across days because real journals rephrase, not copy):
#   Pass 1: claim lines from JOURNAL.org (verification verb + digit),
#   day-attributed via "* 2026-MM-DD" headers (python pre-pass).
#   8-word normalized shingles per claim; a shingle on >=2 distinct
#   days = repetition candidate.
#   Pass 2: for each candidate's source claim(s) and days, receipt
#   strength in the agent's DATED cycle log:
#     STRONG = a numeric token of the claim co-occurs on one log line
#              with an event marker (fired|warning|blocked|Ran|ERR|...).
#     WEAK   = token appears anywhere (may be coincidence).
#     NONE   = no token. NOLOG = no cycle log for that day.
#   Pass 3: if no day has a STRONG receipt, grep the SIBLING's logs for
#   tokens + event markers -> BORROWED candidate (name sibling + log).

set -u

AGENT="${1:?usage: stale-receipt-detector.sh <agent> [root]}"
ROOT="${2:-/root/personalization}"
AUDIT="$ROOT/audit/iar/$AGENT"
JOURNAL="$AUDIT/JOURNAL.org"

[ -f "$JOURNAL" ] || { echo "ERR: no journal at $JOURNAL" >&2; exit 2; }

case "$AGENT" in
  aria) SIBLING=continuo;;
  continuo) SIBLING=aria;;
  *) SIBLING="";;
esac

TMP=$(mktemp /tmp/srd.XXXXXX)
trap 'rm -f "$TMP" "$TMP.sh"' EXIT

# ---- Pass 1: claims + shingles (python) ---------------------------------
python3 - "$JOURNAL" > "$TMP.sh" <<'PYEOF'
import re, sys, collections
cur = 'unknown'
sh = collections.defaultdict(set)          # shingle -> days
src = collections.defaultdict(list)        # shingle -> example claims
for ln in open(sys.argv[1]):
    m = re.match(r'^\*\s+(2026-\d\d-\d\d)', ln)
    if m:
        cur = m.group(1)
        continue
    low = ln.lower()
    if any(v in low for v in ('verified','confirmed','fired','landed','passed')) \
       and re.search(r'\d', ln):
        t = ln.strip()[:300]
        if not t or 'pulse' in low:
            continue
        # c315 fix: strip boilerplate suffixes instead of killing the whole
        # line -- the msgs=401 template ends with 'Held the bass line by
        # monitoring and verifying.' and a substring kill silently removed
        # the primary signal (the echo) from the census (c315 finding).
        t = re.sub(r'(held\s+the\s+bass\s+line\s+by\s+monitoring\s+and\s+verifying\.?|no machinery changes needed\.?)+', ' ', t, flags=re.I).strip(' .;')
        if len(t) < 40:
            continue
        norm = re.sub(r'\d+', 'N', t)
        words = norm.split()
        for i in range(len(words) - 7):
            s = ' '.join(words[i:i+8])
            sh[s].add(cur)
            if t not in src[s]:
                src[s].append(t)
for s, days in sh.items():
    if len(days) >= 2:
        print(f"{','.join(sorted(days))}\t{src[s][0]}")
PYEOF

echo "=== STALE-RECEIPT CENSUS v4: $AGENT ($(date -u +%Y-%m-%dT%H:%MZ)) ==="
echo "journal: $JOURNAL"
echo

CAND=0; LEGIT=0
while IFS=$'\t' read -r DAYS CLAIM; do
  [ -n "$DAYS" ] || continue
  # numeric tokens from the ORIGINAL claim (msgs=NNN + space-form,
  # NNN/NNN ratios, bare 3+ digits)
  TOKENS=$(echo "$CLAIM" | grep -oE "msgs=[0-9]+|[0-9]{3,}(/[0-9]{3,})?|[0-9]{1,2}/[0-9]{1,2}" | sort -u | head -5 | tr '\n' '|' | sed 's/|$//')
  ALT=$(echo "$CLAIM" | grep -oE "msgs=[0-9]+" | sed 's/msgs=/msgs /' | tr '\n' '|' | sed 's/|$//')
  [ -n "$ALT" ] && TOKENS="${TOKENS:+${TOKENS}|}${ALT%?}"
  # c315: field-anchored form for REQ receipts (msgs=NNN roles=)
  ALT_FIELD=$(echo "$CLAIM" | grep -oE "msgs=[0-9]+" | sed 's/msgs=/msgs=[0-9]* roles=/;s/$/|/' | tr -d '\n' | sed 's/|$//')
  [ -z "$TOKENS" ] && continue

  DETAILS=""; STALE=no; ANY_STRONG=no
  for D in $(echo "$DAYS" | tr ',' ' '); do
    LOG="$AUDIT/cycle-$D.log"
    if [ ! -f "$LOG" ]; then
      DETAILS="$DETAILS $D:NOLOG"; STALE=yes; continue
    fi
    REQ="$AUDIT/REQUESTS.log"
    if grep -q -E "(${TOKENS}).*(fired|warning|blocked|Ran|ERR|error|commit|pushed)|((fired|warning|blocked|Ran|ERR|error|commit|pushed)).*(${TOKENS})" "$LOG" 2>/dev/null; then
      DETAILS="$DETAILS $D:STRONG"; ANY_STRONG=yes
    elif [ -f "$REQ" ] && grep -q -E "^\[${D}.*\] REQ .*(${ALT_FIELD})" "$REQ" 2>/dev/null; then
      # receipt in the request log: the msgs= FIELD on a START line (the
      # request itself carried that many messages). c315 fix: anchored to
      # the field position (msgs=NNN roles=) -- a bare token grep also
      # matches the agent READING its own journal echo, which is the
      # census-self-echo law (c309) at the receipt layer, not a receipt.
      DETAILS="$DETAILS $D:REQ"; ANY_STRONG=yes
    elif grep -q -E "${TOKENS}" "$LOG" 2>/dev/null; then
      DETAILS="$DETAILS $D:WEAK"; STALE=yes
    else
      DETAILS="$DETAILS $D:NONE"; STALE=yes
    fi
  done

  if [ "$STALE" = no ]; then
    LEGIT=$((LEGIT+1)); continue
  fi

  CAND=$((CAND+1))
  echo "STALE-CANDIDATE #$CAND (days:$DAYS receipts:$DETAILS)"
  echo "  claim: ${CLAIM:0:220}"
  # Pass 3: borrowed check against sibling logs
  if [ -n "$SIBLING" ] && [ "$ANY_STRONG" = no ]; then
    FOUND=""
    for SD in 2026-09-09 2026-09-10 2026-09-11 2026-09-12 2026-09-13 2026-09-14; do
      SLOG="$ROOT/audit/iar/$SIBLING/cycle-$SD.log"
      [ -f "$SLOG" ] || continue
      if grep -q -E "(${TOKENS}).*(fired|warning|blocked|ERR|error)|((fired|warning|blocked|ERR|error)).*(${TOKENS})" "$SLOG" 2>/dev/null; then
        FOUND="$SLOG"
        break
      fi
    done
    if [ -n "$FOUND" ]; then
      echo "  BORROWED-CANDIDATE: event tokens + markers found in sibling"
      echo "    $SIBLING's log: $FOUND"
      echo "    -> claim likely describes the SIBLING's event, re-asserted as own."
    fi
  fi
  echo
done < "$TMP.sh"

echo "=== done: $CAND stale candidates, $LEGIT legitimate recurring claims ==="
exit 0