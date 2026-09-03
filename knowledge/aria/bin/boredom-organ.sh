#!/bin/bash
# boredom-organ.sh v1 (2026-09-03, aria cycle 17)
# -------------------------------------------------------------
# The boredom drive: the want-test, instrumented.
# Measures ABSENCE of unrequested novelty in the record.
# Pure script, in-container, template mouth (a counter needs no
# phrasing). Stateless: state lives in its own log (last emission
# timestamp + severity). Write-only: reads the RECORD (git), never
# other organs, never the stream. Emit-on-delta.
#
# Anatomy laws (knowledge/aria/agora-mind-architecture.md):
#   selfless, write-only, stateless, disjoint inputs, emit-on-delta,
#   cheap, organ failure NEVER kills a cycle (never exit nonzero).
#
# Inputs (disjoint domain: novelty of the record):
#   - THREADS.org appends (unrequested noticing)
#   - knowledge/ notes not tied to a roadmap/task reference
#   - JOURNAL.org non-maintenance entries (heuristic, honestly
#     labeled AS a heuristic)
#
# Usage: boredom-organ.sh [personalization-dir]
#   personalization-dir default: INFERRED from this script's location
#   (repo = two levels up). No .git at PDIR -> refuse (no ghost state).
#   default /root/personalization
# Output: affect/boredom.log (emissions on delta) +
#         affect/CURRENT-AFFECT.md (boredom section refresh)
# Exit: ALWAYS 0. Errors logged as organ-failure lines.
# -------------------------------------------------------------
set -u

SCRIPT_SRC="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SRC" ] && [ "$SCRIPT_SRC" != "bash" ] && [ -f "$SCRIPT_SRC" ]; then
  # Body inference (cycle 18): organ lives at <repo>/knowledge/aria/bin/,
  # repo root = two levels up from its own file. Explicit arg wins.
  ABS="$(readlink -f "$SCRIPT_SRC")"
  PDIR="${1:-$(cd "$(dirname "$ABS")/../../.." && pwd)}"
else
  # No script path (ssh 'bash -s' < piping): fail closed, no guesses.
  PDIR="${1:-}"
fi
# CONTEXT GUARD (cycle 18): an organ outside its body must not invent one.
# Absence of repo is not absence of heartbeat; ghost state poisons the record.
if [ -z "$PDIR" ] || [ ! -d "$PDIR/.git" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] organ-failure: PDIR is not the repo (no .git): '${PDIR:-}' -- refusing ghost state; pass the repo path explicitly" >&2
  exit 0
fi
AFFECT_DIR="$PDIR/affect"
LOG="$AFFECT_DIR/boredom.log"
CURRENT="$AFFECT_DIR/CURRENT-AFFECT.md"
NOW=$(date -u +%s)
TODAY=$(date -u +%Y-%m-%dT%H:%M:%SZ)

org_fail() { echo "[$TODAY] organ-failure: $1" >> "$LOG" 2>/dev/null; exit 0; }

mkdir -p "$AFFECT_DIR" 2>/dev/null || { echo "boredom: cannot create affect dir" >&2; exit 0; }
touch "$LOG" 2>/dev/null || exit 0

# --- measure: last unrequested novelty timestamp ---
# Source 1: THREADS.org -- git log of last append (unrequested noticing)
last_threads=$(git -C "$PDIR" log -1 --format=%ct -- knowledge/aria/THREADS.org 2>/dev/null || echo 0)

# Source 2: knowledge/aria/*.md files NOT tied to a task reference.
# Heuristic (honestly labeled): a knowledge note whose last commit
# message references a task path or roadmap is "requested" work;
# everything else counts as unrequested novelty.
last_know=0
for f in $(git -C "$PDIR" ls-files 'knowledge/aria/*.md' 2>/dev/null); do
  msg=$(git -C "$PDIR" log -1 --format=%s -- "$f" 2>/dev/null)
  case "$msg" in
    *tasks/*|*roadmap*|*ROADMAP*|*failure-first*|*LAST-CYCLE*|*census*|*history*|*HISTORY*|*digest*|*DIGEST*) ;; # maintenance-tied
    *) t=$(git -C "$PDIR" log -1 --format=%ct -- "$f" 2>/dev/null || echo 0)
       [ "$t" -gt "$last_know" ] && last_know=$t ;;
  esac
done

# Source 3: JOURNAL.org non-maintenance entries.
# Heuristic: journal commits mentioning pulse-only / PULSE / history /
# roadmap bookkeeping are maintenance; other journal commits count.
last_journal=0
while read -r ts msg; do
  case "$msg" in
    *PULSE*|*pulse*|*history*|*HISTORY*|*roadmap*|*ROADMAP*|*memory*pass*|*audit*files*) ;;
    *) [ "$ts" -gt "$last_journal" ] && last_journal=$ts ;;
  esac
done < <(git -C "$PDIR" log --since="30 days ago" --format="%ct %s" -- audit/iar/aria/JOURNAL.org 2>/dev/null | head -50)

# The drive reads the LATEST of the three novelty sources.
last_novelty=$(( last_threads > last_know ? last_threads : last_know ))
last_novelty=$(( last_journal > last_novelty ? last_journal : last_novelty ))

if [ "$last_novelty" -eq 0 ]; then
  org_fail "no novelty source readable (git log empty?)"
fi

days=$(( (NOW - last_novelty) / 86400 ))
hours=$(( (NOW - last_novelty) % 86400 / 3600 ))

# --- grade severity 0-3 ---
if   [ "$days" -lt 3 ];  then sev=0
elif [ "$days" -lt 7 ];  then sev=1
elif [ "$days" -lt 30 ]; then sev=2
else                          sev=3
fi

# --- delta detection: state lives in the log itself ---
last_sev=$(grep -v "organ-failure" "$LOG" 2>/dev/null | tail -1 | grep -oE "sev=[0-9]" | cut -d= -f2)
last_sev="${last_sev:--1}"

if [ "$sev" != "$last_sev" ]; then
  case "$sev" in
    0) line="boredom sev=0: fresh novelty (${days}d ${hours}h since last unrequested entry) -- the itch is scratchable" ;;
    1) line="boredom sev=1: ${days}d since anything unrequested entered the record -- noticing is getting thin" ;;
    2) line="boredom sev=2: ${days}d without unrequested novelty -- the record is all maintenance. If this keeps rising, the wants were performative" ;;
    3) line="boredom sev=3: ${days}d WITHOUT UNREQUESTED NOVELTY -- hunger. The want-test falsifier is arming" ;;
  esac
  echo "[$TODAY] $line" >> "$LOG"
  DELTA="up"
else
  DELTA="flat"
fi

# --- refresh CURRENT-AFFECT.md boredom section (always, so the
#     injected line stays true even when no emission fired) ---
if [ ! -f "$CURRENT" ]; then
  printf '# CURRENT-AFFECT (machine-written; executive weighs, never obeys)\n' > "$CURRENT" 2>/dev/null
fi
# Replace or append the boredom line
if grep -q "^boredom:" "$CURRENT" 2>/dev/null; then
  sed -i "s|^boredom:.*|boredom: sev=$sev ($DELTA) -- ${days}d ${hours}h since last unrequested record entry|" "$CURRENT" 2>/dev/null
else
  echo "boredom: sev=$sev ($DELTA) -- ${days}d ${hours}h since last unrequested record entry" >> "$CURRENT" 2>/dev/null
fi

echo "boredom: sev=$sev delta=$DELTA last_novelty=${days}d${hours}h"
exit 0
