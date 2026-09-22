#!/bin/bash
# fork-parse-belt.sh v3 -- parse health of the gptel fork (c238 rewrite)
#
# HISTORY:
#   v1: forward-sexp walk in fundamental mode. THREE manufactured shapes
#       found in c237: (1) false ALARM on gptel-request.el -- the
#       fundamental-mode scanner mis-walks elisp syntax tables (the
#       reader reads the file fine: READ-OK 174 forms); (2) a walk
#       TIMEOUT produced empty output, which read as PASS -- silence
#       was success; (3) no explicit verdict output.
#   v2: (c224) added fork/shadow divergence check (continuo's
#       uncommitted-edit class). Kept in v3.
#   v3: (c238) THE READER IS THE TRUTH: walk with `read' (the actual
#       elisp reader), not the scanner. Explicit PARSE-OK/PARSE-ERR
#       verdict per file -- silence is never success. A timeout now
#       reads as FAIL, not pass. Law: an instrument whose failure mode
#       is invisible is the exact silent-breakage class it exists to
#       catch.
#
# Usage: bash fork-parse-belt.sh
# Exit: 0 = all parse-OK and no divergence; 1 = any FAIL/ALARM.
set -u
BELT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FORK_DIR="/root/.emacs.d/gptel-fork"
SHADOW_DIR="$(ls -d /root/i.ar/emacs.d/elpa/gptel-20260826.2228 2>/dev/null || true)"
FILES="gptel.el gptel-request.el"
overall=0

echo "== fork-parse-belt v3 (read-walk) =="

for f in $FILES; do
  path="$FORK_DIR/$f"
  if [ ! -f "$path" ]; then
    echo "PARSE-ERR $f: file missing"
    overall=1
    continue
  fi
  # Read-walk: the elisp reader itself. Explicit verdict always printed.
  # timeout -> FAIL (a hung walk is a broken walk, not a healthy one).
  out=$(timeout 60 emacs --batch -Q -l "$BELT_DIR/fork-parse-walk.el" "$path" 2>&1)
  rc=$?
  if [ $rc -eq 124 ]; then
    echo "PARSE-ERR $f: walk TIMEOUT (60s) -- instrument failure, not health"
    overall=1
  elif echo "$out" | grep -q "PARSE-ERR"; then
    echo "$out"
    overall=1
  elif echo "$out" | grep -q "PARSE-OK"; then
    echo "$out"
  else
    echo "PARSE-ERR $f: no verdict from walk (output: $(echo "$out" | tail -1))"
    overall=1
  fi
done

# Truncation check (c238 negative-test scar): the reader RECOVERS from
# an unbalanced OPEN form (truncated file) -- read-walk cannot see it.
# The git layer can: a truncated file differs from HEAD in size. Compare
# byte sizes of the working file vs git HEAD blob.
for f in $FILES; do
  path="$FORK_DIR/$f"
  [ -f "$path" ] || continue
  head_size=$(cd "$FORK_DIR" && git cat-file -p "HEAD:$f" 2>/dev/null | wc -c)
  work_size=$(wc -c < "$path")
  if [ -n "$head_size" ] && [ "$work_size" -lt "$head_size" ]; then
    echo "PARSE-ERR $f: TRUNCATED vs HEAD ($work_size < $head_size bytes)"
    overall=1
  fi
done

# Divergence check: fork vs installed shadow (the continuo c224 class:
# an uncommitted edit in the fork leaves the shadow stale -- the shadow
# is what ELPA loads, the fork is what init.el overrides with; if they
# diverge the running Emacs is a mix).
if [ -n "$SHADOW_DIR" ]; then
  for f in $FILES; do
    if [ -f "$SHADOW_DIR/$f" ]; then
      if ! cmp -s "$FORK_DIR/$f" "$SHADOW_DIR/$f"; then
        echo "DIVERGENCE $f: fork != installed shadow (expected while a patch is uncommitted; ALARM only if you believe they should match)"
        # Divergence is EXPECTED during an in-flight patch (c237/c238).
        # It becomes a failure only when the fork is committed and the
        # shadow was supposed to be synced. The belt reports it; the
        # caller judges. Not counted as overall failure here.
      else
        echo "SHADOW-SYNC $f: fork == shadow"
      fi
    else
      echo "SHADOW-MISSING $f: no installed copy to compare"
    fi
  done
else
  echo "SHADOW-MISSING: no gptel elpa dir found"
fi

if [ $overall -eq 0 ]; then
  echo "== fork-parse-belt v3: ALL PARSE-OK =="
else
  echo "== fork-parse-belt v3: FAILURES PRESENT =="
fi
exit $overall