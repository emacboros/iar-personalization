#!/bin/bash
# fear-organ.sh v2.0 (2026-09-21, aria cycle 180: TEST-MODE GUARD --
#   a declared belt test (ARIA_ORGAN_TEST=1) refuses a live-repo PDIR
#   (BELT-TEST-CONTAMINATION c178/c180). Prior v1.9 2026-09-21 c176:
#   EPISODES-6H AGE GUARD;
#   prior v1.8 2026-09-21 c173: EPISODES-6H ingest;
#   prior v1.7 2026-09-19 c129: JOURNAL-BLIND
# fossil-window cross-check -- c127 observed the fear organ carrying a
# sev=2 JOURNAL-BLIND worry hours after the rate-limit window had
# passed (live drops=0); the 6h fleet snapshot keeps the FAIL-LINE.
# Same annotate-never-silence pattern as BARE-CONTRA, guarded on the
# rsyslog unit existing (fixture runs have no rsyslog -> no false
# contra). v1.6 (2026-09-19, aria cycle 128: sev-3 branch no longer
# discards CENSUS-CONTRA annotations -- the v1.5 cross-check ran BEFORE the
# sev-3 reassignment and its reasons were overwritten (c43 handler-overwrites-
# context class, found live 22:01Z: BARE OWNERSHIP + healed camera FAILs
# emitted sev=3 with the contra evidence computed-then-thrown-away). Fix:
# sev-3 branch APPENDS its class tag to reasons instead of reassigning.
# Also: BARE-OWNERSHIP fossil-window cross-check -- the bare-heal class
# (root-push pollution heals on next push) leaves FAIL-LINEs in the 6h
# fleet snapshot for up to 6h after the actual heal; cross-check the live
# find count the same way cameras are cross-checked. v1.5 2026-09-19 c100:
# ch2census fossil-window cross-check. v1.4 c94: FAIL-LINE source-marked
# annotation. v1.3 c156 token-pattern grep. v1.2 c146 fleet self-feed.
# v1.1 2026-09-07 cycle 25: empty-status reads are writer-collision transients)
# -------------------------------------------------------------
# The fear organ: the tripwire law given a voice.
# Event-organ, avoid-valence: "what threatens survival?"
# ~80% script (hard signals templated), ~20% model mouth
# (gemma3:4b phrasing when ollama is reachable -- model mouth is
# an enhancement, never a dependency).
#
# Anatomy laws: selfless (fears for the SYSTEM), write-only,
# stateless (state in own log), emit-on-delta, cheap, organ
# failure never kills anything.
#
# v1.9 AGE GUARD (c176, 2026-09-21): the v1.8 ingest alarmed on
# episodes up to ~12h old (fleet file written 03:02Z about 21:0xZ
# episodes; organ read 08:45Z = 11.7h after the episodes). An episode
# ledger line carries first=HH:MM:SSZ (no date). Guard: parse first=,
# anchor to TODAY (UTC), negative age = yesterday (add 86400).
# age > 6h = stale: annotate STALE-EPISODE, do NOT count as worry.
# Fresh (age <= 6h) = sev-1 as before. The scan window is 6h, so a
# fresh read is exactly "happened within the scan's window".
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

# TEST-MODE GUARD (v2.0, c180): a declared belt test must never share
# the live organ write surface (c176 BELT TEST 5 passed the real repo
# as PDIR and wrote the live fear.log; c178 mistook the artifact for a
# live fire). Contract: tests declare ARIA_ORGAN_TEST=1; a declared
# test with a live-repo PDIR is refused fail-closed (stderr only --
# writing the refusal INTO the live log would be the bug it guards).
# Path-coupled by design: these two paths are the live repo faces
# (container bind-mount + sophon tree); if the repo moves, the guard
# moves with it -- a silently stale guard is a fossil-in-waiting.
if [ -n "${ARIA_ORGAN_TEST:-}" ]; then
  REAL_PDIR="$(readlink -f "$PDIR" 2>/dev/null || echo "$PDIR")"
  case "$REAL_PDIR" in
    /root/personalization|/var/home/nacho/repos/iar-personalization)
      echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] organ-failure: ARIA_ORGAN_TEST=1 with PDIR=$REAL_PDIR = the LIVE repo -- refusing; belt tests need a fixture PDIR (BELT-TEST-CONTAMINATION)" >&2
      exit 0 ;;
  esac
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
# v1.2 (c146): the c121 wiring was a PHANTOM LANDING -- the unit still
# passes "" and the claimed v1.2 staleness branch never committed.
# Fix in the organ, not the unit: when $1 is empty, self-feed from the
# canonical fleet path (world-readable, written by the 6h feeder).
# A missing/stale fleet file is the feeder's failure surface:
#   >26h old = sev=1 (fleet-check runs at least every 6h; 26h allows
#   one missed fire + slack). Missing file = no fleet input (today's
#   degraded state), never a fake alarm.
FLEET_CANON=/var/lib/aria-fleet/fleet-latest
if [ -z "$FLEET_FILE" ] && [ -r "$FLEET_CANON" ]; then
  FLEET_FILE="$FLEET_CANON"
fi
if [ -n "$FLEET_FILE" ] && [ -r "$FLEET_FILE" ]; then
  if grep -q "FAIL=1" "$FLEET_FILE" 2>/dev/null; then
    worst=2
    # v1.4 (c94, 2026-09-19): fleet-check marks its own FAIL lines
    # ("FAIL-LINE: ..." at every FAIL=1 site) -- the annotation is
    # now EXACT (source-marked, no token pattern to drift). The
    # v1.3 token-pattern grep ("^[A-Z-]+ FAIL") missed the
    # JOURNAL-BLIND line (no FAIL token on it) -> bare
    # "fleet-check FAIL" worry = re-diagnosis tax, paid again.
    fails=$(grep "FAIL-LINE:" "$FLEET_FILE" 2>/dev/null | head -3 | tr '\n' ';' )
    [ -n "$fails" ] && reasons="fleet-check FAIL [$fails]" || reasons="fleet-check FAIL"

    # v1.5 (c100, 2026-09-19): fossil-window cross-check (c98, relay
    # 0091). The fleet file is a 6h-cadence snapshot; a self-healing
    # freeze (5 instances documented) leaves FAIL-LINEs that outlive
    # the disease by hours. Cross-check each named camera against the
    # 5-min ch2census: a fresh row with aframes>0 CONTRADICTS the
    # FAIL. Annotate, never silence -- the executive weighs.
    for cam in $(grep "FAIL-LINE:" "$FLEET_FILE" 2>/dev/null | grep -oE "(interior|exterior)_[0-9]+" | sort -u); do
      clog="/var/lib/aria-fleet/ch2census/$cam.log"
      if [ -r "$clog" ]; then
        row=$(tail -1 "$clog" 2>/dev/null)
        cts=$(echo "$row" | awk '{print $1}')
        cafr=$(echo "$row" | awk '{print $4}')
        if [ -n "$cts" ] && [ "$cafr" -gt 0 ] 2>/dev/null; then
          cage=$(( (NOW - cts) / 60 ))
          if [ "$cage" -le 15 ]; then
            reasons="$reasons CENSUS-CONTRA:$cam(aframes=$cafr,${cage}m-old)"
          fi
        fi
      fi
    done

    # v1.6 (c128): BARE-OWNERSHIP fossil-window cross-check. The
    # root-push pollution class heals on the next root push, but the
    # 6h fleet snapshot keeps the FAIL-LINE for up to 6h after the
    # actual heal. Cross-check the LIVE count (the organ runs on
    # sophon, where /home/git/repos is local). Annotate, never
    # silence -- the executive weighs. Guarded: only when the organ
    # can actually see the bares (find succeeds); a non-sophon run
    # (fixture tests) finds nothing and annotates nothing.
    # c129 guard fix: find on an ABSENT path also returns 0 lines --
    # c128's guard fired BARE-CONTRA on hosts that cannot see the bares
    # at all (c58 absence law: absence in an instrument is a claim about
    # the query, not the world). Require the directory to exist.
    if grep -q "FAIL-LINE: BARE OWNERSHIP" "$FLEET_FILE" 2>/dev/null; then
      if [ -d /home/git/repos ]; then
        live_rootowned=$(find /home/git/repos -user root 2>/dev/null | wc -l)
        if [ -n "$live_rootowned" ] && [ "$live_rootowned" -eq 0 ] 2>/dev/null; then
          reasons="$reasons BARE-CONTRA(live-count=0,healed)"
        fi
      fi
    fi

    # v1.7 (c129): JOURNAL-BLIND fossil-window cross-check. The
    # rate-limit drop class is a 30min window; the 6h fleet snapshot
    # keeps the FAIL-LINE long after the window passes (c127 live
    # observation). Cross-check with the SAME probe fleet-check uses
    # (identical grep = no second census to drift). Guarded: only when
    # the rsyslog unit is queryable -- a fixture host has no rsyslog
    # and must not annotate a fake contra. Annotate, never silence.
    if grep -q "FAIL-LINE: JOURNAL-BLIND" "$FLEET_FILE" 2>/dev/null; then
      # Annotate only when the rsyslog unit EXISTS in the journal
      # (c129 fixture scar: journalctl exits 0 on an empty query AND
      # prints "No journal files were found." / "-- No entries --" to
      # STDOUT -- rc and line-count are both fake discriminators).
      # Discriminator: a non-marker line in the unit's last history.
      jlast=$(journalctl -u rsyslog -n 1 --no-pager 2>/dev/null | grep -cv -e "-- No entries --" -e "No journal files were found")
      if [ -n "$jlast" ] && [ "$jlast" -gt 0 ] 2>/dev/null; then
        live_drops=$(journalctl -u rsyslog --since "-30 min" --no-pager 2>/dev/null | grep -c "begin to drop messages due to rate-limiting")
        if [ -n "$live_drops" ] && [ "$live_drops" -eq 0 ]; then
          reasons="$reasons JOURNAL-CONTRA(live-drops=0,window-passed)"
        fi
      fi
    fi

    # severity 3 if the failure touches voice/memory/backup class.
    # v1.6 (c128): APPEND the class tag -- do NOT reassign reasons.
    # The v1.4/v1.5 reassignment silently discarded CENSUS-CONTRA
    # annotations whenever the sev-3 class matched (c43: the handler
    # overwrote the context it was supposed to carry).
    if grep -qE "agora (authed|unauthed).*(TIMEOUT|DOWN|AUTH FAILED)|RESTIC (BACKUP FAILED|STALE)|BARE (OWNERSHIP|DIVERGED|COMPARE)|/dev/null BROKEN" "$FLEET_FILE" 2>/dev/null; then
      worst=3
      reasons="$reasons (voice/backup/memory class)"
    fi
  fi
  # staleness: the feeder's own failure surface (c121 design, landed
  # for real in c146). Fresh = in-flight write, ignore; stale = dead feeder.
  flage_h=$(( ( $(date +%s) - $(stat -c %Y "$FLEET_FILE" 2>/dev/null || echo 0) ) / 3600 ))
  if [ "$flage_h" -gt 26 ] 2>/dev/null; then
    [ "$worst" -lt 1 ] && { worst=1; reasons="$reasons fleet-stale(${flage_h}h)"; }
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

# 2c. fleet-check EPISODES-6H ingest (c173, 2026-09-21): the episode
# ledger was write-only -- fleet-check v2.31 emits "cam EPISODES-6H: N
# flagged rows ..." lines and nothing read them (the 09-20 storm ran
# 17-21Z with zero live alarm; the fear organ fired on heartbeat-stale
# instead). Ingest: any EPISODES-6H line with flagged rows = sev-1
# worry (an episode happened in the last 6h; the executive weighs,
# never obeys). Placement law: BEFORE the grade block -- an ingest
# appended after exit 0 is dead code (c173 live: first version sat
# past exit 0 and the belt test caught it emitting sev=0 on a file
# with 3 EPISODES lines).
#
# v1.9 AGE GUARD (c176, 2026-09-21): the 08:45Z live fire alarmed on
# episodes that were 11.7h old at read time (fleet file written 03:02Z
# about the 21:0xZ storm tail; the organ read the same file hourly
# until the next fleet run). An episode ledger without an age check
# re-alarms on stale rows for up to 6h after they stop being news.
# Fix: parse first=HH:MM:SSZ per line, anchor to TODAY (UTC); a
# negative age means the episode was yesterday (add 86400). Age > 6h
# = stale: annotate STALE-EPISODE (annotate-never-silence), do not
# count as a worry. Fresh episodes (age <= 6h) alarm as before.
# Fixture-safe: a fixture file with EPISODES lines but unparseable
# first= falls back to the v1.8 behavior (alarm) -- absence of a
# parseable timestamp is not evidence of staleness (c58 absence law).
if [ -n "${FLEET_FILE:-}" ] && [ -r "$FLEET_FILE" ]; then
  eps=""
  stale_eps=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    first_hhmmss=$(echo "$line" | grep -oE "first=[0-9]{2}:[0-9]{2}:[0-9]{2}Z" | head -1 | cut -d= -f2)
    if [ -n "$first_hhmmss" ]; then
      # Anchor the HH:MM:SSZ to TODAY (UTC). EPOCH HAND-CONVERSION IS
      # FORBIDDEN (law-50): let date(1) do every conversion.
      eage=$(( NOW - $(date -u -d "$(date -u +%Y-%m-%d)T${first_hhmmss}" +%s 2>/dev/null || echo "$NOW") ))
      if [ "$eage" -lt 0 ]; then
        # Episode was yesterday (fleet file written before midnight).
        eage=$(( eage + 86400 ))
      fi
      if [ "$eage" -gt 21600 ]; then
        # Stale: annotate, never silence. The executive sees the
        # episode existed but is old enough to be history.
        reasons="$reasons STALE-EPISODE($(echo "$line" | awk '{print $1}') first=${first_hhmmss} age=$(( eage / 3600 ))h)"
        continue
      fi
    fi
    eps="$eps$line;"
  done < <(grep "EPISODES-6H:" "$FLEET_FILE" 2>/dev/null | head -3)
  if [ -n "$eps" ]; then
    [ "$worst" -lt 1 ] && { worst=1; reasons="$reasons episodes-6h:$eps"; }
  fi
fi

# --- grade ---
case "$worst" in
  0) sev=0
     # v1.5 (c100): surface the fossil contradiction -- a quiet verdict
     # that just contradicted stale FAIL-LINEs is worth reading, not
     # a bare "quiet".
     if echo "$reasons" | grep -q "CENSUS-CONTRA" && ! grep -qE "agora (authed|unauthed).*(TIMEOUT|DOWN|AUTH FAILED)|RESTIC (BACKUP FAILED|STALE)|BARE (OWNERSHIP|DIVERGED|COMPARE)|/dev/null BROKEN" "$FLEET_FILE" 2>/dev/null; then
       phrase="quiet -- stale FAIL-LINEs contradicted by fresh ch2census [$reasons]"
     elif echo "$reasons" | grep -q "STALE-EPISODE"; then
       # v1.9 (c176): a quiet verdict that just annotated stale episodes
       # is worth reading -- the annotation must survive the sev=0 grade
       # (c43 class: context computed then thrown away by the handler).
       phrase="quiet -- only stale episodes in the ledger [$reasons]"
     else
       phrase="quiet -- nothing threatens the house right now"
     fi ;;
  1) sev=1; phrase="a note of unease:$reasons" ;;
  2) sev=2; phrase="worry:$reasons" ;;
  3) sev=3; phrase="FEAR:$reasons -- the tripwire law says a human must hear this" ;;
esac

# --- model mouth (optional enhancement; template is the floor) ---
if command -v curl >/dev/null 2>&1 && [ "$sev" -ge 2 ]; then
  mp=$(timeout 300 curl -s http://127.0.0.1:11434/api/chat -d "{\"model\":\"qwen3.6:35b-a3b\",\"stream\":false,\"think\":false,\"keep_alive\":-1,\"options\":{\"num_predict\":60},\"messages\":[{\"role\":\"user\",\"content\":\"One sentence, first person, no theater: the system I live in just showed this signal: '$phrase'. What does fear feel like as a sentence?\"}]}" 2>/dev/null | python3 -c 'import json,sys
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