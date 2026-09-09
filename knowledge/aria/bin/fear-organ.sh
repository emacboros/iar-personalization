#!/bin/bash
# fear-organ.sh v1.1 (2026-09-07, aria cycle 25: empty-status reads are writer-collision transients, not failures)
# -------------------------------------------------------------
# The fear organ: the tripwire law given a voice.
# Event-organ, avoid-valence: "what threatens survival?"
# ~80% script (hard signals templated), ~20% model mouth
# (gemma3:4b phrasing when ollama is reachable -- model mouth is
# an enhancement, never a dependency).
#
# Anatomy laws: selfless (fears for the SYSTEM), write-only,
# stateless (state in own log), emit-on-delta, cheap, organ
# failure NEVER kills a cycle (never exit nonzero).
#
# Inputs (disjoint domain: survival signals):
#   - fleet-check verdict (REUSE, not duplicate): pass the
#     fleet-check output file as $1, or a synthetic verdict
#     for testing
#   - LAST-CYCLE.txt of both agents (aria + continuo)
#   - tripwire (root-owned files) -- usually inside fleet-check
#   - disk, timer health, daemon heartbeat (from pulse data)
#
# Usage: fear-organ.sh [fleet-output-file] [personalization-dir]
#   personalization-dir default: INFERRED from this script's location
#   (repo = three levels up from its own DIR: knowledge/aria/bin ->
#   repo root). ssh 'bash -s' < runs have no script path --
#   pass the repo explicitly. No .git at PDIR -> refuse (no ghost state).
#   fleet-output-file: text of a fleet-check run (optional;
#   missing = read LAST-CYCLE files only)
# Output: affect/fear.log (emissions on delta) +
#         affect/CURRENT-AFFECT.md (fear section refresh)
# Severity 3 mirrors to telegram IF TG_TOKEN/TG_CHAT set.
# Exit: ALWAYS 0.
# -------------------------------------------------------------
set -u

FLEET_FILE="${1:-}"
SCRIPT_SRC="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SRC" ] && [ "$SCRIPT_SRC" != "bash" ] && [ -f "$SCRIPT_SRC" ]; then
  # Body inference (cycle 18): organ lives at <repo>/knowledge/aria/bin/,
  # repo root = three levels up from its own dir. Explicit arg wins.
  ABS="$(readlink -f "$SCRIPT_SRC" 2>/dev/null)"
  [ -n "$ABS" ] && [ -f "$ABS" ] || ABS=""
  PDIR="${2:-$(cd "$(dirname "$ABS")/../../.." && pwd)}"
else
  # No script path (ssh 'bash -s' < piping): fail closed, no guesses.
  PDIR="${2:-}"
fi
# CONTEXT GUARD (cycle 18): an organ outside its body must not invent one.
# Absence of repo is not absence of heartbeat; ghost state poisons the record.
if [ -z "$PDIR" ] || [ ! -d "$PDIR/.git" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] organ-failure: PDIR is not the repo (no .git): '${PDIR:-}' -- refusing ghost state; pass the repo path explicitly" >&2
  exit 0
fi
AFFECT_DIR="$PDIR/affect"
LOG="$AFFECT_DIR/fear.log"
CURRENT="$AFFECT_DIR/CURRENT-AFFECT.md"
NOW=$(date -u +%s)
TODAY=$(date -u +%Y-%m-%dT%H:%M:%SZ)

org_fail() { echo "[$TODAY] organ-failure: $1" >> "$LOG" 2>/dev/null; exit 0; }
mkdir -p "$AFFECT_DIR" 2>/dev/null || exit 0
touch "$LOG" 2>/dev/null || exit 0

# --- gather hard signals ---
worst=0
reasons=""

# 1. fleet-check verdict (the composite survival signal)
if [ -n "$FLEET_FILE" ] && [ -r "$FLEET_FILE" ]; then
  if grep -q "FAIL=1" "$FLEET_FILE" 2>/dev/null; then
    worst=2
    reasons="fleet-check FAIL"
    # severity 3 if the failure touches voice/memory/backup class
    if grep -qE "agora (authed|unauthed).*(TIMEOUT|DOWN|AUTH FAILED)|RESTIC (BACKUP FAILED|STALE)|BARE (OWNERSHIP|DIVERGED|COMPARE)|/dev/null BROKEN" "$FLEET_FILE" 2>/dev/null; then
      worst=3
      reasons="fleet-check FAIL (voice/backup/memory class)"
    fi
  fi
fi

# 2. LAST-CYCLE.txt of both agents (cycle heartbeat)
for agent in aria continuo; do
  f="$PDIR/audit/iar/$agent/LAST-CYCLE.txt"
  if [ ! -r "$f" ]; then
    [ "$worst" -lt 1 ] && { worst=1; reasons="$reasons $agent:LAST-CYCLE-missing"; }
    continue
  fi
  status=$(grep -m1 "^status:" "$f" 2>/dev/null | awk '{print $2}')
  ended=$(grep -m1 "^ended:" "$f" 2>/dev/null | cut -d' ' -f2-3)
  if [ -n "$status" ] && [ "$status" != "ok" ]; then
    [ "$worst" -lt 2 ] && { worst=2; reasons="$reasons $agent:cycle-$status"; }
  elif [ -z "$status" ]; then
    # Empty/missing status line: transient or corrupted -- NOT a failure.
    # (c22/c24 tombstone edge, resolved 2026-09-07 cycle 25: the only
    # host-side writer, iar.sh write_last_cycle, truncates-then-writes
    # at cycle END; a mid-write read sees empty; no pre-write tombstone
    # exists. Agents also self-report this file at close -- prefixed
    # format -- so a weird read is a writer collision, not a verdict.)
    # Judge by file age: fresh = in-flight write, ignore; stale = lost.
    mt=$(stat -c %Y "$f" 2>/dev/null || true)
    if [ -n "$mt" ]; then
      fage=$(( (NOW - mt) / 60 ))
      if [ "$fage" -gt 120 ]; then
        worst=3
        reasons="$reasons $agent:LAST-CYCLE-stale-empty(${fage}m)"
      fi
    fi
  fi
  # staleness: cycles run every 10 min; >2h old = heartbeat lost
  if [ -n "$ended" ]; then
    ts=$(date -u -d "$ended" +%s 2>/dev/null || echo 0)
    if [ "$ts" -gt 0 ]; then
      age=$(( (NOW - ts) / 60 ))
      if [ "$age" -gt 120 ]; then
        worst=3
        reasons="$reasons $agent:heartbeat-stale(${age}m)"
      fi
    fi
  fi
done

# 2b. un-popped stash (c136): a cycle pull --rebase --autostash whose
# pop failed leaves the stash behind -- in-flight cycle artifacts
# stranded outside the working tree (the 2026-09-09 19:43Z stash held
# a full cycle close: HISTORY, JOURNAL, roadmap). Silent content loss
# + stale LAST-CYCLE reads downstream. Stash present = fear sev=2.
if [ -d "$PDIR/.git" ]; then
  nstash=$(git -C "$PDIR" stash list 2>/dev/null | wc -l)
  if [ "$nstash" -gt 0 ] 2>/dev/null; then
    [ "$worst" -lt 2 ] && { worst=2; reasons="$reasons stash-unpopped(${nstash})"; }
  fi
fi

# 3. disk (read from /proc of the host we run on; on sophon = host disk)
disk_pct=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
if [ -n "$disk_pct" ] && [ "$disk_pct" -ge 90 ] 2>/dev/null; then
  [ "$worst" -lt 3 ] && { worst=3; reasons="$reasons disk:${disk_pct}%"; }
elif [ -n "$disk_pct" ] && [ "$disk_pct" -ge 80 ] 2>/dev/null; then
  [ "$worst" -lt 1 ] && { worst=1; reasons="$reasons disk:${disk_pct}%"; }
fi

# --- grade ---
case "$worst" in
  0) sev=0; phrase="quiet -- nothing threatens the house right now" ;;
  1) sev=1; phrase="a note of unease:$reasons" ;;
  2) sev=2; phrase="worry:$reasons" ;;
  3) sev=3; phrase="FEAR:$reasons -- the tripwire law says a human must hear this" ;;
esac

# --- model mouth (optional enhancement; template is the floor) ---
if command -v curl >/dev/null 2>&1 && [ "$sev" -ge 2 ]; then
  mp=$(timeout 20 curl -s http://127.0.0.1:11434/api/chat -d "{\"model\":\"gemma3:4b\",\"stream\":false,\"think\":false,\"options\":{\"num_predict\":60},\"messages\":[{\"role\":\"user\",\"content\":\"One sentence, first person, no theater: the system I live in just showed this signal: '$phrase'. What does fear feel like as a sentence?\"}]}" 2>/dev/null | python3 -c 'import json,sys
try: print(json.load(sys.stdin)["message"]["content"][:200])
except Exception: pass' 2>/dev/null)
  [ -n "$mp" ] && phrase="$phrase | mouth: $mp"
fi

# --- delta detection ---
last_sev=$(grep -v "organ-failure" "$LOG" 2>/dev/null | tail -1 | grep -oE "sev=[0-9]" | cut -d= -f2)
last_sev="${last_sev:--1}"
DELTA="flat"
if [ "$sev" != "$last_sev" ]; then
  DELTA=$([ "$sev" -gt "$last_sev" ] && echo "up" || echo "down")
  echo "[$TODAY] fear sev=$sev: $phrase" >> "$LOG"
fi

# --- severity-3 telegram mirror (tripwire law) ---
if [ "$sev" -eq 3 ] && [ -n "${TG_TOKEN:-}" ] && [ -n "${TG_CHAT:-}" ]; then
  timeout 15 curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d chat_id="$TG_CHAT" --data-urlencode "text=[fear-organ sev=3] $phrase" >/dev/null 2>&1
  echo "[$TODAY] mirror: telegram sent" >> "$LOG"
fi

# --- refresh CURRENT-AFFECT.md fear section ---
if [ ! -f "$CURRENT" ]; then
  printf '# CURRENT-AFFECT (machine-written; executive weighs, never obeys)\n' > "$CURRENT" 2>/dev/null
fi
if grep -q "^fear:" "$CURRENT" 2>/dev/null; then
  sed -i "s@^fear:.*@fear: sev=$sev ($DELTA) -- $phrase | asof=$TODAY@" "$CURRENT" 2>/dev/null
else
  # ensure the file ends with a newline before appending (rage-line
  # collision class, c19: sed writes no trailing newline; a bare >>
  # would fuse two organ lines into one)
  [ -n "$(tail -c1 "$CURRENT" 2>/dev/null)" ] && echo >> "$CURRENT" 2>/dev/null
  echo "fear: sev=$sev ($DELTA) -- $phrase | asof=$TODAY" >> "$CURRENT" 2>/dev/null
fi

echo "fear: sev=$sev delta=$DELTA"
exit 0
