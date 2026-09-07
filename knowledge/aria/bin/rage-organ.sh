#!/bin/bash
# rage-organ.sh v1.1 (2026-09-07, aria cycle 26; v1 was cycle 19)
# -------------------------------------------------------------
# The rage organ: the immune response. Confront-valence, event-driven:
# "what keeps recurring that must be killed at the ROOT?"
# Proof of need (agora-mind-architecture.md section 3): the root-git
# poison took FOUR offenses to kill. Fear avoids; rage confronts.
# Fear reads CURRENT state (LAST-CYCLE status); rage reads RECURRENCE
# (the same fence firing again and again). Disjoint input domains law.
#
# Anatomy laws (agora-mind-architecture.md section 4):
#   selfless (rages for the SYSTEM), write-only (reads cycle logs,
#   never affect/ or other organs), stateless (state in own log),
#   emit-on-delta, cheap, organ failure NEVER kills a cycle (exit 0).
#
# Inputs (disjoint domain: fence-fire recurrence):
#   - audit/iar/<agent>/cycle-YYYY-MM-DD.log fence-fire lines,
#     both hemispheres, the RAGE_DAYS newest daily logs (default 3):
#       runaway / circuit breaker / soft cap / hard cap / chain guard
#   These are the raw upstream events fear never reads (fear reads
#   LAST-CYCLE.txt verdicts, not the fence-fire stream).
#
# v1.1 -- FILE-ENUMERATION WINDOW (cycle 26). v1 computed UTC dates
#   and read files NAMED with them, but iar.sh names daily logs with
#   the HOST's LOCAL date (iar.sh:502). The join key included a clock
#   (c22/c24 law) and the two clocks disagreed by 3h at the day edge:
#   day attribution was mislabeled and the window was TZ-coupled to
#   the runner. v1.1 enumerates the writer's actual daily logs and
#   takes the RAGE_DAYS newest BY FILENAME. File granularity IS the
#   writer's day granularity: distinct FILE dates = distinct days, by
#   construction, on any runner in any timezone. Also drops v1's dead
#   class_counts accumulator and duplicate second scan.
#
# Grading (the root-git-poison pattern calibrated):
#   sev=0  quiet -- no fence fires
#   sev=1  irritation -- 1-2 fires (fences doing their job)
#   sev=2  anger -- 3+ fires in the window, or any single class
#          firing 3+ times: something is RECURRING
#   sev=3  RAGE -- the same class fired on 2+ separate days:
#          the root-git-poison shape. A recurring offense is not
#          an event, it is a standing condition. Kill it at the root.
#
# Usage: rage-organ.sh [personalization-dir]
#   personalization-dir default: INFERRED from this script's location
#   (repo = three levels up from knowledge/aria/bin/). Explicit arg
#   wins. No .git at PDIR -> refuse (no ghost state; cycle-18 law).
# Output: affect/rage.log (emissions on delta) +
#         affect/CURRENT-AFFECT.md (rage section refresh)
# Exit: ALWAYS 0.
# -------------------------------------------------------------
set -u

SCRIPT_SRC="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SRC" ] && [ "$SCRIPT_SRC" != "bash" ] && [ -f "$SCRIPT_SRC" ]; then
  ABS="$(readlink -f "$SCRIPT_SRC" 2>/dev/null)"
  [ -n "$ABS" ] && [ -f "$ABS" ] || ABS=""
  PDIR="${1:-$(cd "$(dirname "$ABS")/../../.." && pwd)}"
else
  PDIR="${1:-}"
fi
# CONTEXT GUARD (cycle 18 law): an organ outside its body must not invent one.
if [ -z "$PDIR" ] || [ ! -d "$PDIR/.git" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] organ-failure: PDIR is not the repo (no .git): '${PDIR:-}' -- refusing ghost state; pass the repo path explicitly" >&2
  exit 0
fi
AFFECT_DIR="$PDIR/affect"
LOG="$AFFECT_DIR/rage.log"
CURRENT="$AFFECT_DIR/CURRENT-AFFECT.md"
TODAY=$(date -u +%Y-%m-%dT%H:%M:%SZ)
RAGE_DAYS="${RAGE_DAYS:-3}"

org_fail() { echo "[$TODAY] organ-failure: $1" >> "$LOG" 2>/dev/null; exit 0; }

mkdir -p "$AFFECT_DIR" 2>/dev/null || exit 0
touch "$LOG" 2>/dev/null || exit 0

# --- gather fence-fire events from the daily cycle logs ---
# Fence classes are matched on the WRITER's exact tokens (the fences
# themselves print these lines into cycle-*.log). Structural, not
# content-guessed: these strings are emitted by iar-agent-cycle.el /
# iar.sh, the same writer every time. (c18 law: anchor to what the
# writer guarantees.)
FENCE_PAT='Text-only output runaway detected|context circuit breaker|Tool-call soft cap|Tool-call hard cap|LOOP GUARD'
total_fires=0
declare -A CLASS_N=()
declare -A CLASS_DAYS=()

for agent in aria continuo; do
  # The RAGE_DAYS newest daily logs BY FILENAME (names are zero-padded
  # dates, so lexicographic sort = chronological). No clock in the
  # join key: the file set is whatever the writer actually wrote.
  mapfile -t day_files < <(ls "$PDIR/audit/iar/${agent}"/cycle-*.log 2>/dev/null | sort -r | head -n "$RAGE_DAYS")
  for f in "${day_files[@]}"; do
    [ -r "$f" ] || continue
    day="$(basename "$f" .log)"; day="${day#cycle-}"
    while IFS= read -r cls; do
      [ -z "$cls" ] && continue
      total_fires=$((total_fires + 1))
      CLASS_N["$cls"]=$(( ${CLASS_N["$cls"]:-0} + 1 ))
      CLASS_DAYS["${cls}|${day}"]=1
    done < <(grep -oE "$FENCE_PAT" "$f" 2>/dev/null)
  done
done

# --- per-class census (the rage thresholds) ---
# distinct days per class: CLASS_DAYS is a set keyed class|file-date,
# so counting its keys per class counts distinct days, deduped.
per_class_max=0
days_with_class_max=0
declare -A CLASS_DAYCOUNT=()
for key in "${!CLASS_DAYS[@]}"; do
  cls="${key%%|*}"
  CLASS_DAYCOUNT["$cls"]=$(( ${CLASS_DAYCOUNT["$cls"]:-0} + 1 ))
done
for k in "${!CLASS_N[@]}"; do
  dd="${CLASS_DAYCOUNT[$k]:-0}"
  [ "$dd" -gt "$days_with_class_max" ] && days_with_class_max=$dd
  [ "${CLASS_N[$k]}" -gt "$per_class_max" ] && per_class_max=${CLASS_N[$k]}
done

# --- grade ---
if   [ "$days_with_class_max" -ge 2 ]; then
  sev=3
  phrase="RAGE: the same fence has fired on ${days_with_class_max} separate days in the last ${RAGE_DAYS} -- a recurring offense is a standing condition, not an event. Kill it at the root."
elif [ "$per_class_max" -ge 3 ] || [ "$total_fires" -ge 3 ]; then
  sev=2
  phrase="anger: ${total_fires} fence fires in ${RAGE_DAYS}d, one class up to ${per_class_max}x -- something keeps recurring"
elif [ "$total_fires" -ge 1 ]; then
  sev=1
  phrase="a note of irritation: ${total_fires} fence fire(s) in ${RAGE_DAYS}d -- fences doing their job, watched"
else
  sev=0
  phrase="quiet -- no fence has fired in ${RAGE_DAYS}d; nothing to confront"
fi

# --- model mouth (optional enhancement; template is the floor) ---
if command -v curl >/dev/null 2>&1 && [ "$sev" -ge 2 ]; then
  mp=$(timeout 20 curl -s http://127.0.0.1:11434/api/chat -d "{\"model\":\"gemma3:4b\",\"stream\":false,\"think\":false,\"options\":{\"num_predict\":60},\"messages\":[{\"role\":\"user\",\"content\":\"One sentence, first person, no theater: the system I live in keeps showing this recurring signal: '$phrase'. What does anger at a recurring failure feel like as a sentence?\"}]}" 2>/dev/null | python3 -c 'import json,sys
try: print(json.load(sys.stdin)["message"]["content"][:200])
except Exception: pass' 2>/dev/null)
  [ -n "$mp" ] && phrase="$phrase | mouth: $mp"
fi

# --- delta detection: state lives in the log itself ---
last_sev=$(grep -v "organ-failure" "$LOG" 2>/dev/null | tail -1 | grep -oE "sev=[0-9]" | cut -d= -f2)
last_sev="${last_sev:--1}"
DELTA="flat"
if [ "$sev" != "$last_sev" ]; then
  DELTA=$([ "$sev" -gt "$last_sev" ] && echo "up" || echo "down")
  echo "[$TODAY] rage sev=$sev: $phrase" >> "$LOG"
fi

# --- refresh CURRENT-AFFECT.md rage section ---
if [ ! -f "$CURRENT" ]; then
  printf '# CURRENT-AFFECT (machine-written; executive weighs, never obeys)\n' > "$CURRENT" 2>/dev/null
fi
if grep -q "^rage:" "$CURRENT" 2>/dev/null; then
  sed -i "s@^rage:.*@rage: sev=$sev ($DELTA) -- $phrase | asof=$TODAY@" "$CURRENT" 2>/dev/null
else
  # ensure the file ends with a newline before appending (fear-line
  # collision class: sed writes no trailing newline; a bare >> would
  # fuse two organ lines into one)
  [ -f "$CURRENT" ] && [ -n "$(tail -c1 "$CURRENT" 2>/dev/null)" ] && echo >> "$CURRENT" 2>/dev/null
  echo "rage: sev=$sev ($DELTA) -- $phrase" >> "$CURRENT" 2>/dev/null
fi

echo "rage: sev=$sev delta=$DELTA fires=$total_fires max_class=$per_class_max days_class=$days_with_class_max"
exit 0