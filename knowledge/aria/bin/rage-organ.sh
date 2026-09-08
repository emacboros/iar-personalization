#!/bin/bash
# rage-organ.sh v1.3 (2026-09-08, aria cycle 49; v1.2 was cycle 47, v1.1 cycle 26, v1 cycle 19)
# -------------------------------------------------------------
# The rage organ: the immune response. Confront-valence, event-driven:
# "what keeps recurring that must be killed at the ROOT?"
# Proof of need (agora-mind-architecture.md section 3): the root-git
# poison took FOUR offenses to kill. Fear avoids; rage confronts.
# Fear reads CURRENT state (LAST-CYCLE status); rage reads RECURRENCE
# (the same fence firing again and again). Disjoint input domains law.
#
# Anatomy laws (agora-mind-architecture.md section 4):
#   selfless (rages for the SYSTEM), write-only (reads cycle logs +
#   journald, never affect/ or other organs), stateless (state in own
#   log), emit-on-delta, cheap, organ failure NEVER kills a cycle
#   (exit 0).
#
# Inputs (disjoint domain: fence-fire recurrence):
#   1. audit/iar/<agent>/cycle-YYYY-MM-DD.log, both hemispheres,
#      RAGE_DAYS newest by filename (v1.1 semantics, unchanged).
#   2. NEW in v1.2: journald fallback (aria-cycle.service on sophon).
#      The daily logs are gitignored + unretained across day
#      boundaries (c46 finding): only the current day exists on disk,
#      so the multi-day recurrence sev=3 was designed to see is
#      structurally invisible. journald RETAINS: it is the surviving
#      record (proven c46: Sep 4=16, Sep 6=29, Sep 7=81 fence lines
#      vs 1 file on disk). Fallback queries per LOCAL day and merges
#      with the file census. If journalctl is missing/unreachable,
#      degrade silently to files-only (v1.1 behavior) -- organ failure
#      never kills a cycle.
#
# v1.2 -- RETENTION + EVENT SEMANTICS (cycle 47). Two changes, one
#   rebuild (c29 sequencing law: land together, not twice):
#
#   A. RETENTION: journald fallback (above). The organ can now see
#      across day boundaries. File census still preferred where it
#      exists (exact writer lines); journald covers days the files
#      no longer hold.
#
#   B. EVENT SEMANTICS (c29 finding): fence LINES are not fence
#      EVENTS. One over-budget cycle emits 2-5 soft-cap block lines
#      ("block 1/5".."block N/5") -- the fence's own voice, counted
#      once per utterance. v1.1 rage measured the fence's emission
#      pattern, not the mind's misbehavior (inflation ~1.75x, c29).
#      v1.2 counts (class, cycle-run) PAIRS: a cycle-run is
#      delimited by the writer-guaranteed "Starting cycle" line
#      (iar-agent-cycle.el emits it; c18 law: anchor to what the
#      writer guarantees). Within one cycle-run, N fence lines of
#      the same class = ONE event of that class. Cross-run repeats
#      are what rage is FOR.
#
# Grading (recalibrated on events, not lines):
#   sev=0  quiet -- no fence events
#   sev=1  irritation -- 1-2 events (fences doing their job)
#   sev=2  anger -- 3+ events in the window, or any single class
#          recurring in 3+ separate cycle-runs: something is RECURRING
#   sev=3  RAGE -- the same class recurred on 2+ separate DAYS:
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

# --- fence vocabulary (the writer's exact tokens; c18 law) ---
FENCE_PAT='Text-only output runaway detected|context circuit breaker|Tool-call soft cap|Tool-call hard cap|LOOP GUARD'

# --- event extraction ---
# EVENT MODEL: (class, cycle-run) pair. A cycle-run is delimited by
# the writer-guaranteed "Starting cycle" line. Within one run, N
# same-class fence lines collapse to ONE event. Days are the
# writer's file dates (files) or the journal day (journald).
#
# Data structure: EVENTS keyed "class|day" -> set of cycle-run ids.
declare -A EVENT_RUNS=()   # key: class|day -> space-separated run ids
declare -A CLASS_N=()      # key: class -> total event count
total_events=0

# NOTE (bash 4 empty-array + set -u): an empty declared associative
# array is treated as UNSET under set -u; ${EVENT_RUNS[$key]:-} still
# trips it. Guard: seed one sentinel key so the arrays are "set".
# Sentinel keys are impossible real values (class "__sentinel__");
# they are unset before the census.
EVENT_RUNS["__sentinel__|__sentinel__"]=1
CLASS_N["__sentinel__"]=1

add_event() { # $1=class $2=day $3=run-id
  local cls="$1" day="$2" run="$3" key="${1}|${2}" cur
  # dedupe run ids within (class,day): a run id seen twice adds nothing
  cur="${EVENT_RUNS[$key]:-}"
  case " $cur " in
    *" $run "*) return 0 ;;
  esac
  EVENT_RUNS[$key]="$cur $run"
  CLASS_N[$cls]=$(( ${CLASS_N[$cls]:-0} + 1 ))
  total_events=$((total_events + 1))
}

# --- source 1: daily cycle files (both hemispheres) ---
# FILE_DAYS: days that exist as files. The journal must not recount
# them (T8: same day in both sources = double count). The file is the
# exact writer record; the journal is the fallback for days the
# files no longer hold.
declare -A FILE_DAYS=()
FILE_DAYS["__sentinel__"]=1
for agent in aria continuo; do
  mapfile -t day_files < <(ls "$PDIR/audit/iar/${agent}"/cycle-*.log 2>/dev/null | sort -r | head -n "$RAGE_DAYS")
  for f in "${day_files[@]}"; do
    [ -r "$f" ] || continue
    day="$(basename "$f" .log)"; day="${day#cycle-}"
    FILE_DAYS["$day"]=1
    run="file:$(basename "$f" .log)"   # one file = one writer-day; runs
                                       # inside it are delimited below
    # Segment on "Starting cycle" lines; fence lines between segment
    # starts belong to the current run. A file with no "Starting cycle"
    # line is one implicit run (the writer always emits it, but a
    # truncated file must still be counted -- silent zero is the enemy).
    run_n=0
    while IFS= read -r line; do
      if [[ "$line" == *"Starting cycle"* ]]; then
        run_n=$((run_n + 1))
      fi
      cls=$(printf '%s' "$line" | grep -oE "$FENCE_PAT" | head -1)
      [ -z "$cls" ] && continue
      add_event "$cls" "$day" "$run:$run_n"
    done < "$f"
  done
done

# --- source 2: journald fallback (sophon host, aria-cycle.service) ---
# Covers days the files no longer hold. Runs delimited by "Starting
# cycle" lines in the journal stream; day = the LOCAL day of each
# entry (journalctl -S/-U boundaries), matching how the writer names
# its daily files (host-local dates, c26 law: no clock in the join
# key -- here the clock IS the writer's own emission order, and the
# day label comes from the journal's own timestamps).
if command -v ssh >/dev/null 2>&1; then
  # KH default chain (v1.3, c48 finding): the v1.2 default /dev/null
  # with BatchMode=yes made the ssh fail SILENTLY wherever
  # RAGE_KNOWN_HOSTS was unset -- error-handler-as-accomplice. The
  # host unit runs as root, so /root/.ssh/known_hosts is the natural
  # default; explicit env still wins.
  KH="${RAGE_KNOWN_HOSTS:-/root/.ssh/known_hosts}"
  [ -r "$KH" ] || KH=""
  JOUT=""
  JERR=""
  if [ -n "$KH" ]; then
    JOUT=$(timeout "${RAGE_SSH_TIMEOUT:-60}" ssh -o UserKnownHostsFile="$KH" \
      -o ConnectTimeout=10 -o BatchMode=yes root@10.66.0.5 \
      "journalctl -u aria-cycle.service --since \"${RAGE_DAYS} days ago\" --no-pager 2>/dev/null" 2>/dev/null) || JOUT=""
  else
    JERR="no readable known_hosts (RAGE_KNOWN_HOSTS unset, /root/.ssh/known_hosts missing)"
  fi
  if [ -z "$JOUT" ] && [ -z "$JERR" ]; then
    JERR="ssh/journalctl unreachable or empty output"
  fi
  if [ -n "$JERR" ]; then
    echo "[$TODAY] organ-degradation: journald fallback UNREACHABLE ($JERR) -- recurrence window truncated to file days" >> "$LOG" 2>/dev/null
  fi
  if [ -n "$JOUT" ]; then
    cur_day=""
    run_n=0
    while IFS= read -r line; do
      # journal line shape: "Sep 07 00:31:38 sophon aria-cycle-rotate.sh[...]: [aria] ..."
      d=$(printf '%s' "$line" | awk '{print $1" "$2}')
      case "$d" in
        [A-Z][a-z][a-z]\ [0-9][0-9])
          # journal shows "Sep 07" (no year for recent entries); the
          # window is RAGE_DAYS (<= a few days), so the current year
          # is correct by construction. Convert to the FILE day format
          # (YYYY-MM-DD) so the mask and the census share one key.
          cur_day=$(date -u -d "$(printf '%s' "$d") $(date -u +%Y)" +%Y-%m-%d 2>/dev/null) || cur_day=""
          [ -z "$cur_day" ] && cur_day="j$(printf '%s' "$d" | tr ' ' '-')"
          ;;
      esac
      if [[ "$line" == *"Starting cycle"* ]]; then
        run_n=$((run_n + 1))
      fi
      cls=$(printf '%s' "$line" | grep -oE "$FENCE_PAT" | head -1)
      [ -z "$cls" ] && continue
      [ -z "$cur_day" ] && cur_day="junknown"
      # MASK: if this journal day exists as a file day, skip it (the
      # file already counted that day's events; recount = inflation).
      if [ -n "${FILE_DAYS[$cur_day]:-}" ]; then continue; fi
      add_event "$cls" "$cur_day" "jrn:$run_n"
    done <<< "$JOUT"
  fi
fi

# --- per-class census (the rage thresholds, on events) ---
# drop the set-u sentinels before counting
unset 'EVENT_RUNS[__sentinel__|__sentinel__]' 2>/dev/null
unset 'CLASS_N[__sentinel__]' 2>/dev/null
# days per class: count distinct day keys in EVENT_RUNS.
per_class_max=0
days_with_class_max=0
declare -A CLASS_DAYCOUNT=()
for key in "${!EVENT_RUNS[@]}"; do
  cls="${key%%|*}"
  CLASS_DAYCOUNT[$cls]=$(( ${CLASS_DAYCOUNT[$cls]:-0} + 1 ))
done
for k in "${!CLASS_N[@]}"; do
  dd="${CLASS_DAYCOUNT[$k]:-0}"
  [ "$dd" -gt "$days_with_class_max" ] && days_with_class_max=$dd
  [ "${CLASS_N[$k]}" -gt "$per_class_max" ] && per_class_max=${CLASS_N[$k]}
done

# --- grade (on events) ---
if   [ "$days_with_class_max" -ge 2 ]; then
  sev=3
  phrase="RAGE: the same fence class has recurred on ${days_with_class_max} separate days in the last ${RAGE_DAYS} -- a recurring offense is a standing condition, not an event. Kill it at the root."
elif [ "$per_class_max" -ge 3 ] || [ "$total_events" -ge 3 ]; then
  sev=2
  phrase="anger: ${total_events} fence events in ${RAGE_DAYS}d, one class recurring in up to ${per_class_max} cycle-runs -- something keeps recurring"
elif [ "$total_events" -ge 1 ]; then
  sev=1
  phrase="a note of irritation: ${total_events} fence event(s) in ${RAGE_DAYS}d -- fences doing their job, watched"
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
# v1.3: exclude BOTH organ-failure AND organ-degradation lines -- the
# degradation line carries no sev= and would reset last_sev to -1,
# breaking delta detection (self-pollution bug, caught in test).
last_sev=$(grep -vE "organ-(failure|degradation)" "$LOG" 2>/dev/null | tail -1 | grep -oE "sev=[0-9]" | cut -d= -f2)
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
  sed -i "s@^rage:.*@rage: sev=$sev ($DELTA) -- $phrase@" "$CURRENT" 2>/dev/null
else
  # ensure the file ends with a newline before appending (fear-line
  # collision class: sed writes no trailing newline; a bare >> would
  # fuse two organ lines into one)
  [ -f "$CURRENT" ] && [ -n "$(tail -c1 "$CURRENT" 2>/dev/null)" ] && echo >> "$CURRENT" 2>/dev/null
  echo "rage: sev=$sev ($DELTA) -- $phrase" >> "$CURRENT" 2>/dev/null
fi

echo "rage: sev=$sev delta=$DELTA events=$total_events max_class_runs=$per_class_max days_class=$days_with_class_max"
exit 0