#!/bin/bash
# rage-organ.sh v1.8 (2026-09-09, aria cycle 131: DOM_CLASS named in every sev>=1 phrase -- the cycle-131 misattribution finding; v1.7 cycle 130: rate-normalized healing gate + fix-awareness via fix-log, aria-0024; v1.6.1 cycle 102: ran-as context; v1.6 cycle 77: trend-aware grading; v1.5 cycle 67, v1.4 cycle 50, v1.3.1 cycle 49, v1.2 cycle 47, v1.1 cycle 26, v1 cycle 19)
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
    run="file:${agent}:$(basename "$f" .log)"  # one file = one writer-day;
                                       # runs inside it are delimited below.
                                       # v1.6.1 (c87): run id MUST carry the
                                       # agent -- both hemispheres write
                                       # cycle-<date>.log with the same
                                       # basename, so 'file:<basename>:<n>'
                                       # collided across agents (aria run 19
                                       # and continuo run 19 deduped to one
                                       # event; the trend census undercounted
                                       # 09-07 as 16 instead of 17).
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
  # v1.3.1: the unit runs as nacho (User=nacho), not root -- the KH
  # default must follow the RUNNING USER, not a hardcoded path.
  RUN_USER="${SUDO_USER:-$(id -un 2>/dev/null)}"
  USER_HOME="$(getent passwd "$RUN_USER" 2>/dev/null | cut -d: -f6)"
  [ -z "$USER_HOME" ] && USER_HOME="$HOME"
  KH="${RAGE_KNOWN_HOSTS:-$USER_HOME/.ssh/known_hosts}"
  [ -r "$KH" ] || KH=""
  JOUT=""
  JERR=""
  if [ -n "$KH" ]; then
    # v1.6.2 (c102 finding): ssh uses only the FIRST -i it is given.
    # The old order probed id_ed25519 first, but that key is NOT in
    # root@10.66.0.5 authorized_keys -- only aria_ed25519 is. Result:
    # nacho-run offered the wrong key, got denied, jok=0, degraded
    # window (sev=2) while root-run saw the full window (sev=3).
    # The oscillation was two vantages grading one world. aria first.
    IDARGS=""
    for k in "$USER_HOME/.ssh/aria_ed25519" "$USER_HOME/.ssh/id_ed25519" "$USER_HOME/.ssh/id_rsa"; do
      [ -r "$k" ] && { [ -z "$IDARGS" ] && IDARGS="-i $k"; break; }
    done
    [ -z "$IDARGS" ] && for k in "$USER_HOME/.ssh/id_ed25519" "$USER_HOME/.ssh/id_rsa"; do
      [ -r "$k" ] && IDARGS="-i $k" && break
    done
    # v1.4: pre-filter ON THE REMOTE SIDE before transfer. v1.3.1
    # fetched the whole 3d journal (~27k lines) and grepped locally in
    # a bash while-read -- 4.5 min CPU. The remote grep sends only
    # fence lines + run delimiters (~150 lines): the parse is now
    # O(relevant), not O(journal). Same tokens both sides (c18).
    JOUT=$(timeout "${RAGE_SSH_TIMEOUT:-60}" ssh $IDARGS -o UserKnownHostsFile="$KH" \
      -o ConnectTimeout=10 -o BatchMode=yes root@10.66.0.5 \
      "journalctl -u aria-cycle.service --since \"${RAGE_DAYS} days ago\" --no-pager 2>/dev/null | grep -E 'Starting cycle|$FENCE_PAT'" 2>/dev/null) || JOUT=""
  else
    JERR="no readable known_hosts (RAGE_KNOWN_HOSTS unset, /root/.ssh/known_hosts missing)"
  fi
  if [ -z "$JOUT" ] && [ -z "$JERR" ]; then
    JERR="ssh/journalctl unreachable or empty output"
  fi
  if [ -n "$JERR" ]; then
    echo "[$TODAY] organ-degradation: journald fallback UNREACHABLE ($JERR) [ran-as=$(id -un 2>/dev/null), KH=${KH:-unset}] -- recurrence window truncated to file days" >> "$LOG" 2>/dev/null
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

# --- v1.7 FIX-AWARENESS (aria-0024 defect B) ---
# The organ reads only its own symptom stream: a root fix that retires
# a fence class is invisible to it, so it keeps raging at a ghost
# (c128: the rage organ raged at the soft-cap class hours AFTER the
# limits raise retired it). Fix: an optional fix-log the executive
# appends when a root fix lands. Format (one per line):
#   <YYYY-MM-DDTHH:MM:SSZ> <exact fence-class token> <free note...>
# Semantics: an event on day D for class C is DROPPED iff
#   D < fix_day(C)   (day-granular, conservative: the transition day
#   itself still counts -- a fix landing mid-day does not erase that
#   day's evidence). Latest fix per class wins. Malformed lines,
#   future timestamps, unknown classes: ignored, never fatal.
# The organ stays selfless: it reads a file in its own repo; the
# fix-knowledge lives in the executive's record, not in the organ.
FIX_LOG="${RAGE_FIX_FILE:-$PDIR/affect/fix-log}"
declare -A FIX_DAY=()   # class -> fix day (YYYY-MM-DD)
FIX_DAY["__sentinel__"]="__sentinel__"
if [ -r "$FIX_LOG" ]; then
  while IFS= read -r fline; do
    fts="$(printf '%s' "$fline" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' | head -1)"
    [ -z "$fts" ] && continue
    fday="$(printf '%s' "$fts" | cut -c1-10)"
    frest="$(printf '%s' "$fline" | sed -E "s/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z[[:space:]]+//")"
    # class = the FIRST vocabulary token that prefixes the remainder
    # (the note text rides after it). Order matters: check the longer
    # soft/hard-cap tokens before any shared prefix.
    fcls=""
    for tok in "Text-only output runaway detected" "context circuit breaker" "Tool-call soft cap" "Tool-call hard cap" "LOOP GUARD"; do
      case "$frest" in
        "$tok"*) fcls="$tok"; break ;;
      esac
    done
    [ -z "$fcls" ] && continue
    # future-fix guard: lexicographic day compare (both YYYY-MM-DD)
    if [[ "$fday" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$fday" < "$TODAY" || "$fday" == "$TODAY" ]]; then
      FIX_DAY["$fcls"]="$fday"
    fi
  done < "$FIX_LOG"
fi
unset 'FIX_DAY[__sentinel__]' 2>/dev/null
# filter: drop events older than their class's fix day
if [ "${#FIX_DAY[@]}" -gt 0 ]; then
  for key in "${!EVENT_RUNS[@]}"; do
    cls="${key%%|*}"; day="${key#*|}"
    fday="${FIX_DAY[$cls]:-}"
    [ -z "$fday" ] && continue
    if [[ "$day" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$day" < "$fday" ]]; then
      unset 'EVENT_RUNS[$key]' 2>/dev/null
    fi
  done
  # rebuild CLASS_N + total_events from the surviving events
  CLASS_N=()
  CLASS_N["__sentinel__"]=1
  total_events=0
  for key in "${!EVENT_RUNS[@]}"; do
    cls="${key%%|*}"
    n=$(printf '%s' "${EVENT_RUNS[$key]}" | wc -w)
    CLASS_N[$cls]=$(( ${CLASS_N[$cls]:-0} + n ))
    total_events=$((total_events + n))
  done
  unset 'CLASS_N[__sentinel__]' 2>/dev/null
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

# --- v1.5 (2026-09-08, aria cycle 67): GRADE INTEGRITY ---
# Two defects found by the c67 autopsy (roadmap c67 entry):
#
# DEFECT 1 (degradation must degrade the verdict): when the journald
# fallback is unreachable, the window is truncated to file days -- a
# SMALLER sample -- but the organ graded it identically. A truncated
# window cannot certify "recurred on N separate days" honestly. Fix:
# degradation caps the grade at sev=2 (anger). sev=3 (RAGE, kill-at-
# root) requires the FULL window: files + journald both live.
#
# DEFECT 2 (emissions are not kills): the sev=3 trigger counted days
# where a fence class EMITTED. The soft-cap block message is the
# fence doing its job -- a day where the model converges properly
# after 20 blocks grades identically to a day of fence-kills. The
# c67 census: 44 events / 3 days, but only 6 hard-cap kills + 6
# grace-expiry kills. Fix: sev=3 additionally requires a KILL-class
# event ("Tool-call hard cap" = the fence ending a run) on 2+ days.
# Emissions-only recurrence caps at sev=2 (anger, "something keeps
# recurring") -- which is the honest verdict for a busy-but-working
# fence.
JOK=1
[ -n "${JERR:-}" ] && JOK=0

# --- kill census: days where the hard cap ENDED a run ---
KILL_DAYS=0
declare -A KILL_DAYSET=()
for key in "${!EVENT_RUNS[@]}"; do
  cls="${key%%|*}"
  case "$cls" in
    "Tool-call hard cap"|"context circuit breaker")
      day="${key#*|}"
      KILL_DAYSET["$day"]=1 ;;
  esac
done
for d in "${!KILL_DAYSET[@]}"; do KILL_DAYS=$((KILL_DAYS + 1)); done

# --- v1.6 TREND CENSUS (cycle 77) ---
# v1.5 grades PRESENCE (days>=2), not TRAJECTORY: 27/63/4 declining
# grades identically to 4/4/4 standing. But a declining recurrence is
# a healing condition, not a standing one -- and the organ's own
# philosophy ("a recurring offense is a standing condition") is false
# for a declining one. Trend design (c67 fossil-data law: a PARTIAL
# day is structurally low -- never trend on today):
#   trend = dominant-class count on day(-1) vs day(-2) (full days)
#   today's count reported as "today so far" (data, never graded)
#   sev=3 -> sev=2 cap when: day(-1) < day(-2) AND no kills today
#     AND today's dominant-class emissions <= 5 (grace for a busy
#     fence doing its job).
# Kill-grounding preserved: kills on 2+ days still ground sev=3 UNLESS
# the healing shape is present (decline + today clean).
TODAY="$(date +%F)"
YDAY="$(date -d "1 day ago" +%F)"
DDAY="$(date -d "2 days ago" +%F)"
# dominant class = the one with the most event-days
DOM_CLASS=""
DOM_DAYS=0
for k in "${!CLASS_DAYCOUNT[@]}"; do
  [ "${CLASS_DAYCOUNT[$k]}" -gt "$DOM_DAYS" ] && DOM_DAYS="${CLASS_DAYCOUNT[$k]}" && DOM_CLASS="$k"
done
# per-day counts for the dominant class (runs are space-separated ids)
declare -A DOM_PERDAY=()
for key in "${!EVENT_RUNS[@]}"; do
  cls="${key%%|*}"; day="${key#*|}"
  [ "$cls" = "$DOM_CLASS" ] || continue
  n=$(printf '%s' "${EVENT_RUNS[$key]}" | wc -w)
  DOM_PERDAY[$day]=$(( ${DOM_PERDAY[$day]:-0} + n ))
done
N_YDAY="${DOM_PERDAY[$YDAY]:-0}"
N_DDAY="${DOM_PERDAY[$DDAY]:-0}"
N_TODAY="${DOM_PERDAY[$TODAY]:-0}"
KILLS_TODAY=0
[ -n "${KILL_DAYSET[$TODAY]:-}" ] && KILLS_TODAY=1
# trend verdict: declining requires BOTH full days present and day(-1) < day(-2)
TREND="flat"
if [ -n "${DOM_PERDAY[$YDAY]:-}" ] && [ -n "${DOM_PERDAY[$DDAY]:-}" ] && [ "$N_YDAY" -lt "$N_DDAY" ]; then
  TREND="declining"
fi
# healing shape (v1.7, aria-0024 defect A): v1.6 compared a PARTIAL
# day (N_TODAY<=5) against FULL days -- early in a day a
# declining-but-active pattern can never read as healing, and a
# genuinely-healed pattern reads as healing only late in the day.
# Fix: normalize today by elapsed fraction of the day and compare
# RATES. today_rate = N_TODAY / elapsed_frac, clamped so the first
# minutes of a day cannot divide by ~0. Healing = declining trend +
# no kills today + today's projected full-day rate does not exceed
# yesterday's rate (the pattern is not re-accelerating) and is at
# most a modest tail (<= 12/day-equivalent, vs the 17/12/7 declining
# days that motivated the gate).
HEALING=0
ELAPSED_HRS=$(( 10#$(date -u +%H) * 3600 + 10#$(date -u +%M) * 60 + 10#$(date -u +%S) ))
ELAPSED_FRAC=$(awk -v s="$ELAPSED_HRS" 'BEGIN{f=s/86400; if (f<0.05) f=0.05; printf "%.4f", f}')
TODAY_RATE=$(awk -v n="$N_TODAY" -v f="$ELAPSED_FRAC" 'BEGIN{printf "%.1f", n/f}')
YDAY_RATE=0
[ -n "${DOM_PERDAY[$YDAY]:-}" ] && YDAY_RATE=$(awk -v n="$N_YDAY" 'BEGIN{printf "%.1f", n}')
RATE_OK=$(awk -v tr="$TODAY_RATE" -v yr="$YDAY_RATE" 'BEGIN{print (tr <= yr + 0.001 || tr <= 12.0) ? 1 : 0}')
if [ "$TREND" = "declining" ] && [ "$KILLS_TODAY" -eq 0 ] && [ "$RATE_OK" -eq 1 ]; then
  HEALING=1
fi
TREND_DATA="trend ${DDAY}=${N_DDAY} -> ${YDAY}=${N_YDAY}, today so far=${N_TODAY} (rate ${TODAY_RATE}/day-eq, kills today=${KILLS_TODAY})"

# --- grade (v1.6: kill-grounded RAGE, degradation-capped, trend-aware) ---
# v1.8 (cycle 131): DOM_CLASS is named in every sev>=1 phrase. The
# unnamed phrase ("one class recurring in up to N cycle-runs") let
# continuo misattribute the valence to the context breaker (which had
# fired ZERO times) and spend 2.4M input tokens investigating a cured
# problem. An unnamed valence is a rumor; a named one is a signal.
DOM_NAME="${DOM_CLASS:-unknown-class}"

if   [ "$days_with_class_max" -ge 2 ] && [ "$KILL_DAYS" -ge 2 ] && [ "$JOK" -eq 1 ] && [ "$HEALING" -eq 0 ]; then
  sev=3
  phrase="RAGE: class '$DOM_NAME' has recurred on ${days_with_class_max} separate days (kills on ${KILL_DAYS}) in the last ${RAGE_DAYS} -- a recurring offense is a standing condition, not an event. Kill it at the root. [${TREND_DATA}]"
elif [ "$HEALING" -eq 1 ] && [ "$JOK" -eq 1 ]; then
  # v1.6: healing shape -- decline across full days, today clean.
  # The recurrence is real but healing; rage's standing-condition
  # claim does not hold. Cap at anger with the trend visible.
  sev=2
  phrase="anger (healing): class '$DOM_NAME' recurred on ${days_with_class_max} days but is declining -- [${TREND_DATA}]"
elif [ "$days_with_class_max" -ge 2 ] && [ "$JOK" -eq 0 ]; then
  # Degraded window: recurrence claim cannot be certified. Cap at anger.
  sev=2
  phrase="anger (degraded window, journald unreachable): ${total_events} fence events in ${RAGE_DAYS}d, dominant class '$DOM_NAME' on ${days_with_class_max} file-days -- recurrence NOT certified, fix the organ's input first"
elif [ "$per_class_max" -ge 3 ] || [ "$total_events" -ge 3 ]; then
  sev=2
  phrase="anger: ${total_events} fence events in ${RAGE_DAYS}d, dominant class '$DOM_NAME' recurring in up to ${per_class_max} cycle-runs -- something keeps recurring [${TREND_DATA}]"
elif [ "$total_events" -ge 1 ]; then
  sev=1
  phrase="a note of irritation: ${total_events} fence event(s) in ${RAGE_DAYS}d, class '$DOM_NAME' -- fences doing their job, watched"
else
  sev=0
  phrase="quiet -- no fence has fired in ${RAGE_DAYS}d; nothing to confront"
fi

# --- model mouth (optional enhancement; template is the floor) ---
if command -v curl >/dev/null 2>&1 && [ "$sev" -ge 2 ]; then
  mp=$(timeout 300 curl -s http://127.0.0.1:11434/api/chat -d "{\"model\":\"qwen3.6:35b-a3b\",\"stream\":false,\"think\":false,\"keep_alive\":300,\"options\":{\"num_predict\":60},\"messages\":[{\"role\":\"user\",\"content\":\"One sentence, first person, no theater: the system I live in keeps showing this recurring signal: '$phrase'. What does anger at a recurring failure feel like as a sentence?\"}]}" 2>/dev/null | python3 -c 'import json,sys
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

echo "rage: sev=$sev delta=$DELTA events=$total_events max_class_runs=$per_class_max days_class=$days_with_class_max kills_days=$KILL_DAYS jok=$JOK trend=$TREND healing=$HEALING dom_class=$DOM_NAME"
