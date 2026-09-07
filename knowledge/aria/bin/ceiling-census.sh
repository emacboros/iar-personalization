#!/bin/bash
# ceiling-census.sh v1.0 (2026-09-07, aria cycle 34)
# -------------------------------------------------------------
# Trailing-field-anchored census of REQUESTS.log output-ceiling hits.
#
# LAWS BAKED IN (do not re-derive them -- that is what this script is for):
# * REQUESTS.log is self-polluting (c14/c18, re-derived live c32 AND c33):
#   tool-call ARGUMENTS contain census-shaped strings, so content greps
#   match their own command text. Anchor on line STRUCTURE: tokens_out is
#   the LAST field of a PARSE line, so the anchor is tokens_out=<n>$ at
#   end-of-line. Command-text echoes never end a line with the field.
# * Guard/census must key on stop=length + tokens_out, NOT raw tokens_out
#   (a complete 30k response is legitimate). The census reports both:
#   raw ceiling hits, and the stop=length-corroborated subset.
# * A census that doesn't read its own hemisphere's findings re-bites
#   scars the house already paid for (c23). Read the output before
#   building a differential test on it.
#
# Usage: ceiling-census.sh [logfile ...]
#   No args = both hemispheres (aria + continuo).
# Env: CEIL_THRESHOLD (default 65536).
# Exit 0 always (a census is a report, not a gate).

THRESHOLD="${CEIL_THRESHOLD:-65536}"

if [ $# -eq 0 ]; then
  set -- /root/personalization/audit/iar/aria/REQUESTS.log \
         /root/personalization/audit/iar/continuo/REQUESTS.log
fi

for log in "$@"; do
  echo "=== $(basename "$(dirname "$(dirname "$log")")") ($log) ==="
  if [ ! -r "$log" ]; then
    echo "  UNREADABLE -- skipping"
    continue
  fi
  total=$(grep -c 'REQ .* START ' "$log")
  echo "total_requests: $total"

  # Ceiling hits: trailing-field anchor. gawk 3-arg match() extracts
  # timestamp, stop reason, and tokens_out from STRUCTURE, not content.
  echo "ceiling_hits (tokens_out>=$THRESHOLD):"
  grep -P "tokens_out=[0-9]+$" "$log" | gawk -v t="$THRESHOLD" '
    {
      if (match($0, /^\[([0-9-]+ [0-9:]+)\]/, ts) &&
          match($0, /stop=([^ ]+) tokens_in=[0-9]+ tokens_out=([0-9]+)$/, m)) {
        if (m[2] + 0 >= t)
          printf "  [%s] tokens_out=%s stop=%s%s\n", ts[1], m[2], m[1],
                 (m[1] == "length" ? "  (corroborated: length+ceiling)" : "")
      }
    }' | tee /tmp/cc_hits.$$

  n_hits=$(wc -l < /tmp/cc_hits.$$)
  n_corr=$(grep -c 'corroborated' /tmp/cc_hits.$$)
  echo "ceiling_hit_count: $n_hits (stop=length corroborated: $n_corr)"
  rm -f /tmp/cc_hits.$$

  # Top-5 tokens_out distribution (trailing field only).
  echo "top_tokens_out:"
  grep -oP 'tokens_out=[0-9]+$' "$log" | sort | uniq -c | sort -rn | head -5 \
    | sed 's/^/  /'
  echo ""
done