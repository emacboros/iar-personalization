#!/bin/bash
# nocturne-gate-watch.sh v5 (aria c333, 2026-09-14)
# One-shot verdict on the LATEST nocturne digest pass. v4-wrapper-aware.
#
# c333 fix 1 (run boundary): verdict classifies only lines AFTER the
# last run-start marker (block-boundary law, c327).
# c333 fix 2 (line-tag anchoring): all verdict greps anchor on the
# wrapper's line tag "nocturne-digest: " -- model prose never carries
# it (v2/v3 matched the echo-recycle's own text "the gate advanced").
# c333 fix 3 (source of record): the journal is the AUTHORITATIVE
# wrapper log -- DIGLOG (/var/log/nocturne-digest.log) only receives
# lines when iar.sh's tee target exists; the 09-14 16:04Z run wrote
# journal-only (DIGLOG's last run-start marker is 09-12). v3's
# "NO RUN-START MARKER" fallback silently misclassified. Classify
# from the journal's service lines for the last 24h.
# Usage: nocturne-gate-watch.sh [ssh-key] [known-hosts]
KEY="${1:-/root/.ssh/id_ed25519}"
KH="${2:-/tmp/aria_known_hosts}"
ssh -i "$KEY" -o UserKnownHostsFile="$KH" -o ConnectTimeout=5 root@10.66.0.5 '
cd /var/home/nacho/repos/iar-personalization
echo "=== gate head (LAST-DIGESTED-HEAD) ==="
cat audit/nocturne/nocturne/LAST-DIGESTED-HEAD 2>/dev/null || echo "NO STATE FILE"
echo "=== proposal file ==="
stat -c "%y %s bytes" audit/iar/aria/DIGEST.proposed.md 2>/dev/null || echo "NO PROPOSAL FILE"
echo "=== last 24h wrapper lines (journal, tag-anchored) ==="
RUNLINES=$(journalctl -u nocturne-digest.service --since "24 hours ago" --no-pager | grep "nocturne-digest: ")
echo "$RUNLINES" | tail -15
echo "=== VERDICT (last 24h, wrapper-tag lines only) ==="
if echo "$RUNLINES" | grep -q "ECHO-RECEIPT"; then
    echo "ECHO-RECYCLE: gate held, response was a verbatim re-emission"
elif echo "$RUNLINES" | grep -q "CLAIM-RECEIPT-FAIL\|RECEIPT-FAIL"; then
    echo "RECEIPT-FAIL: gate held, claim not backed by disk"
elif echo "$RUNLINES" | grep -q "gate advanced"; then
    if echo "$RUNLINES" | grep -q "RANGE-CAP"; then
        echo "CLEAN-ADVANCE (capped): gate advanced to the capped head; remainder deferred"
    else
        echo "CLEAN-ADVANCE: gate advanced, full range digested"
    fi
elif echo "$RUNLINES" | grep -q "NOT advancing"; then
    echo "HELD: gate did not advance -- reason line above"
elif echo "$RUNLINES" | grep -q "no change since last digest"; then
    echo "NO-OP: gate head == HEAD, model never loaded"
elif echo "$RUNLINES" | grep -q "launching one-shot"; then
    echo "RUN IN PROGRESS or DIED WITHOUT VERDICT LINE: launching seen, no outcome"
else
    echo "UNCLASSIFIED: no wrapper lines in the last 24h"
fi
echo "=== commits behind gate ==="
GATE=$(cat audit/nocturne/nocturne/LAST-DIGESTED-HEAD 2>/dev/null)
git rev-list --count "${GATE:-e4d0832d}..HEAD" 2>/dev/null
'