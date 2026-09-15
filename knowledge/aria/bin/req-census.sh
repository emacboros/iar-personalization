#!/bin/bash
# req-census.sh v1 (aria c348, 2026-09-15)
# TRUE failure-class census over REQUESTS.log(.1) -- the c347 method,
# made durable. Field-anchored: $5=class, $6=http=NNN. Merge .log+.log.1,
# dedupe by full line (rotation overlap), count by day.
# Law 50: verify DAY, COLUMN, KEY FORMAT. Law c342: PARSE-only fields,
# never raw grep (echo-quote contamination lives in START tails).
# Usage: req-census.sh [personalization-root]
P="${1:-/root/personalization}"
for a in aria continuo; do
  echo "===== $a ====="
  cat "$P/audit/iar/$a/REQUESTS.log" "$P/audit/iar/$a/REQUESTS.log.1" 2>/dev/null \
    | awk '$5=="RESPONSE" && $6 ~ /^http=/ {print $4, $1, $6}' | sort -u \
    | awk '{split($3,s,"="); d=$2; gsub(/\[/,"",d); cnt[d" "s[2]]++}
           END {for (k in cnt) print cnt[k], k}' | sort -k2,2
done
echo "===== empty-end terminal shape (RESPONSE http=? body_tail=$) ====="
for a in aria continuo; do
  n=$(cat "$P/audit/iar/$a/REQUESTS.log" "$P/audit/iar/$a/REQUESTS.log.1" 2>/dev/null \
    | awk '$5=="RESPONSE" && $6=="http=?" {c++} END{print c+0}')
  echo "$a: $n"
done# c348 AMENDMENT: dedupe key = request-id ($4), not full line (rotation
# overlap duplicates full lines). Census 09-15 02:33Z:
#   aria:  2628 (09-14) + 1034 (09-15) 200; 1 x 503 (09-14 21:26:40);
#          0 true 429; 0 empty-end.
#   cont:  1604 (09-14) + 341 (09-15) 200; 16 x 429 (09-13, quota wall);
#          14 empty-end (11 on 09-14 + 3 on 09-15; 0069 class).
#   Echo-quote contamination (raw grep http=429): aria 41 false events.
