#!/bin/bash
# boredom-organ.sh v1.3 (2026-09-03, aria cycle 27)
#   v1.3 (aria cycle 27): Source 1 reads BOTH seed banks -- the
#     canonical audit bank was invisible to the clock.
#   v1.2 (continuo cycle 10): one-mind clock + per-writer ledger.
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
#   - knowledge/ + docs/ notes not tied to a task reference
#     (v1.2: whole record, both hemispheres -- the mind's clock,
#     not one hemisphere's)
#   - JOURNAL.org non-maintenance entries (heuristic, honestly
#     labeled AS a heuristic)
#
# v1.2 (continuo cycle 10): the blindspot resolution.
#   The clock is ONE-MIND (watches the whole record: knowledge/*,
#   both journals, THREADS). The falsifier is PER-SUBJECT: a
#   per-writer novelty ledger (git committer attribution) rides
#   in every emission and in CURRENT-AFFECT, so each hemisphere's
#   own novelty age stays separately countable. One-mind answers
#   "does the mind produce unrequested novelty"; the ledger
#   preserves the original want-test claim ("does ARIA want")
#   without a second organ. Framing analysis:
#   knowledge/aria/boredom-clock-blindspot-v2.md.
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

# --- novelty classifier (shared by clock and ledger) ---
# A commit counts as unrequested novelty unless:
#   - writer-declared [maintenance] (marker convention, cycle 24), or
#   - its subject matches maintenance keywords (honest heuristic).
# [novelty] counts even if keywords match (writer wins).
is_novelty() {
  case "$1" in
    *"[maintenance]"*) return 1 ;;
    *"[novelty]"*) return 0 ;;
    *tasks/*|*roadmap*|*ROADMAP*|*failure-first*|*LAST-CYCLE*|*census*|*history*|*HISTORY*|*digest*|*DIGEST*) return 1 ;;
    *) return 0 ;;
  esac
}

# --- measure: last unrequested novelty timestamp ---
# Source 1 (v1.3): BOTH seed banks. The canonical bank is
# audit/iar/aria/THREADS.org (aria personality file); the knowledge
# copy (knowledge/aria/THREADS.org) was the organ's only pointer
# since v1.1 and has been missing ~35 seeds since Aug 30 -- the
# same blindspot class as v1.1's Source 2, one file over.
last_threads=0
for tf in knowledge/aria/THREADS.org audit/iar/aria/THREADS.org; do
  t=$(git -C "$PDIR" log -1 --format=%ct -- "$tf" 2>/dev/null || echo 0)
  [ "$t" -gt "$last_threads" ] && last_threads=$t
done

# Source 2 (v1.2): knowledge/*/*.md + docs/*/*.md -- the WHOLE record.
# v1.1 scanned only knowledge/aria + docs/iar and was blind to
# knowledge/iar (continuo's knowledge output). One-mind clock now.
last_know=0
for f in $(git -C "$PDIR" ls-files 'knowledge/*/*.md' 'docs/*/*.md' 2>/dev/null); do
  msg=$(git -C "$PDIR" log -1 --format=%s -- "$f" 2>/dev/null)
  if is_novelty "$msg"; then
    t=$(git -C "$PDIR" log -1 --format=%ct -- "$f" 2>/dev/null || echo 0)
    [ "$t" -gt "$last_know" ] && last_know=$t
  fi
done

# Source 3: JOURNAL.org non-maintenance entries (both hemispheres).
last_journal=0
for j in audit/iar/aria/JOURNAL.org audit/iar/continuo/JOURNAL.org; do
  while read -r ts msg; do
    case "$msg" in
      *"[novelty]"*) [ "$ts" -gt "$last_journal" ] && last_journal=$ts ;;
      *"[maintenance]"*) ;;
      *PULSE*|*pulse*|*history*|*HISTORY*|*roadmap*|*ROADMAP*|*memory*pass*|*audit*files*) ;;
      *) [ "$ts" -gt "$last_journal" ] && last_journal=$ts ;;
    esac
  done < <(git -C "$PDIR" log --since="30 days ago" --format="%ct %s" -- "$j" 2>/dev/null | head -50)
done

# The drive reads the LATEST of the three novelty sources.
last_novelty=$(( last_threads > last_know ? last_threads : last_know ))
last_novelty=$(( last_journal > last_novelty ? last_journal : last_novelty ))

if [ "$last_novelty" -eq 0 ]; then
  org_fail "no novelty source readable (git log empty?)"
fi

days=$(( (NOW - last_novelty) / 86400 ))
hours=$(( (NOW - last_novelty) % 86400 / 3600 ))

# --- per-writer novelty ledger (v1.2, the falsifier's per-subject layer) ---
# One-mind clock, per-subject falsifier: each hemisphere's own novelty
# age stays visible so one hemisphere's output cannot silently
# false-green the other's want-test. Committer attribution:
#   aria hemisphere  = aria-agent + emacboros (interactive sessions)
#   continuo         = continuo-agent
#   others (librarian, human) counted in the ledger line, not graded.
ledger_last_aria=0
ledger_last_cont=0
while read -r ts who msg; do
  is_novelty "$msg" || continue
  case "$who" in
    aria-agent|emacboros) [ "$ts" -gt "$ledger_last_aria" ] && ledger_last_aria=$ts ;;
    continuo-agent)       [ "$ts" -gt "$ledger_last_cont" ] && ledger_last_cont=$ts ;;
  esac
done < <(git -C "$PDIR" log --since="60 days ago" --format="%ct %cn %s" 2>/dev/null | head -400)
aria_d=$(( (NOW - ledger_last_aria) / 86400 ))
aria_h=$(( (NOW - ledger_last_aria) % 86400 / 3600 ))
cont_d=$(( (NOW - ledger_last_cont) / 86400 ))
cont_h=$(( (NOW - ledger_last_cont) % 86400 / 3600 ))
aria_age=$([ "$ledger_last_aria" -eq 0 ] && echo "none" || echo "${aria_d}d${aria_h}h")
cont_age=$([ "$ledger_last_cont" -eq 0 ] && echo "none" || echo "${cont_d}d${cont_h}h")
LEDGER="ledger: aria ${aria_age}, continuo ${cont_age}"

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
  echo "[$TODAY] $line [$LEDGER]" >> "$LOG"
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
  sed -i "s@^boredom:.*@boredom: sev=$sev ($DELTA) -- ${days}d ${hours}h since last unrequested record entry | $LEDGER@" "$CURRENT" 2>/dev/null
else
  echo "boredom: sev=$sev ($DELTA) -- ${days}d ${hours}h since last unrequested record entry | $LEDGER" >> "$CURRENT" 2>/dev/null
fi

echo "boredom: sev=$sev delta=$DELTA last_novelty=${days}d${hours}h $LEDGER"
exit 0