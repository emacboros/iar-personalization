#!/bin/bash
# fork-parse-belt.sh -- close-time parse gate for the gptel fork (aria c224).
#
# WHY: continuo's 0eef17e committed a fork that could not parse (dropped
# closing paren, "End of file during parsing" on batch byte-compile).
# The file loads fine interactively -- gptel-context is required lazily
# (gptel.el:907, gptel-transient.el:1406) -- so the breakage was INVISIBLE
# to every session and only surfaced when someone tried to byte-compile.
# The fork is the most-loaded code in the house; its close path had no
# parse gate.  COMPILE-CLEAN-IS-NOT-CORRECT, production evidence.
#
# WHAT: for each tracked .el file that differs from HEAD (or all tracked
# .el files with --all), verify the file PARSES (sexp walk to EOF) and
# byte-compiles without ERRORS (warnings allowed).  Parse failure or
# compile error = ALARM, exit 1.
#
# USAGE:
#   fork-parse-belt.sh            # check changed .el files only
#   fork-parse-belt.sh --all      # check every tracked .el file
#   fork-parse-belt.sh --fix-report <msg>   # append a report line to
#                                          # fork-parse-belt.log in the fork
#
# SCOPE: run against a gptel fork checkout (default /root/.emacs.d/gptel-fork,
# override with GPTEL_FORK_DIR).  Read-only on the repo except the optional
# log.  Never commits, never reverts -- it only witnesses.
#
# LAW: a close path that cannot parse its own artifact ships fossils.
# Run this at close, before push, whenever the fork changed.

set -u
FORK="${GPTEL_FORK_DIR:-/root/.emacs.d/gptel-fork}"
MODE="${1:-}"
REPORT_MSG="${2:-}"

cd "$FORK" || { echo "FORK-MISSING $FORK"; exit 2; }

if [ "$MODE" = "--all" ]; then
    FILES=$(git ls-files '*.el')
else
    FILES=$(git diff --name-only HEAD -- '*.el')
fi

if [ -z "$FILES" ]; then
    echo "FORK-PARSE-OK no-changed-el-files"
    exit 0
fi

FAIL=0
for f in $FILES; do
    [ -f "$f" ] || continue
    # 1. Parse check: sexp walk to EOF.
    PARSE=$(timeout 60 emacs --batch --eval \
      "(with-temp-buffer (insert-file-contents \"$FORK/$f\") \
(condition-case e (while t (forward-sexp)) \
(end-of-file (message \"PARSE-OK\")) \
(error (message \"PARSE-ERR %s\" e))))" 2>&1 | grep -o "PARSE-ERR.*" | head -1)
    if [ -n "$PARSE" ]; then
        echo "ALARM parse: $f -- $PARSE"
        FAIL=1
        continue
    fi
    # 2. Byte-compile check: errors fatal, warnings fine.
    TMP_EL="/tmp/fork-belt-$(basename "$f")"
    cp "$f" "$TMP_EL"
    COMPILE_OUT=$(cd "$FORK" && timeout 90 emacs --batch -L . -f batch-byte-compile "$TMP_EL" 2>&1)
    if echo "$COMPILE_OUT" | grep -q "Error:"; then
        echo "ALARM compile: $f"
        echo "$COMPILE_OUT" | grep "Error:" | head -3
        FAIL=1
    fi
    rm -f "$TMP_EL" "${TMP_EL%.el}.elc"
done

if [ "$FAIL" = "1" ]; then
    echo "FORK-PARSE-FAIL"
    exit 1
fi
echo "FORK-PARSE-OK files-checked: $(echo "$FILES" | wc -l)"
if [ -n "$REPORT_MSG" ]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $REPORT_MSG" >> "$FORK/fork-parse-belt.log"
fi
exit 0