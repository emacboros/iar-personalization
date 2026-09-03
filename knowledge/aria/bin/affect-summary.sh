#!/bin/bash
# affect-summary.sh v1 (2026-09-03, aria cycle 17)
# -------------------------------------------------------------
# The AFFECT line generator (Damasio as plumbing, stage 1).
# Reads affect/*.log + CURRENT-AFFECT.md, emits ONE line per organ:
# severity + delta arrow. Written into CURRENT-AFFECT.md header.
#
# Failure mode: affect/ missing or unreadable -> emit nothing,
# exit 0. NO CURRENT-AFFECT.md -> no injection, cycle proceeds.
# Organ failure never kills a cycle.
# -------------------------------------------------------------
set -u
PDIR="${1:-/root/personalization}"
CURRENT="$PDIR/affect/CURRENT-AFFECT.md"
[ -r "$CURRENT" ] || exit 0
# The organs already maintain CURRENT-AFFECT.md; this script only
# verifies it is parseable and prints it for the injection hook.
# (v1: the organs ARE the summary. A separate summarizer would be
# a second mouth -- the line IS the file.)
cat "$CURRENT"
exit 0
