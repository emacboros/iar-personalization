#!/bin/bash
# stale-receipt-detector.sh v4.5 -- aria c16 (2026-09-17): result-receipt rung
#   + broadened test-suite anchor (run-tests.el/.sh/bare/ert-substring)
# Census instrument: catches claims in an agent's journal that re-assert
# events without a same-day receipt in that agent's logs, and automates
# the borrowed-receipt check against the sibling's logs.
# NOT a fence -- a census feeding the repetition watch.
#
# Design: tasks/iar/aria/stale-receipt-detector/design-notes.org (c313)
# Laws obeyed: CLAIM-ANCHOR (c307 -- receipts anchor on event-bearing log
#   lines, not bare numbers), CENSUS-SELF-ECHO (c309), CENSUS-DAY (c305 +
#   clock law), CROSS-AGENT corollary (c306 -- borrowed receipts are only
#   visible from outside the claimant's log set).
#
# Usage: stale-receipt-detector.sh <agent> [personalization-root]
#
# Method:
#   Pass 1 (python): claim lines from JOURNAL.org (verification verb +
#   digit), day-attributed via "* 2026-MM-DD" headers. 8-word normalized
#   shingles; a shingle on >=2 distinct days makes its CLAIM a repetition
#   candidate. Claims deduped by text (one row per template, not per
#   shingle -- v4.1 emitted 110 rows for ~10 templates).
#   Pass 2: per claim, per day, requirements evaluated independently:
#     MSGS   = claim asserts "msgs=NNN" (a fence EVENT). Receipt: fence-
#              fire marker + token in the DATED log, OR msgs=NNN FIELD on
#              a START line in the request logs (field-anchored; reading
#              your own journal echo is not a receipt -- c309/c315).
#     INSTR  = claim names an instrument (lexicon below). Receipt: a PARSE
#              specs=execute_code_local line naming that instrument in the
#              request logs dated that day. v4.2 finding: cycle-agent
#              DATED logs are wrapper output (startup + "Cycle complete")
#              and carry almost no tool-call evidence; the receipts live
#              in REQUESTS.log(.1). Without this tier the detector cried
#              wolf 55:1 on legitimate recurring census/suite claims.
#     GENERIC = bare numeric tokens. Receipt: token + event marker in the
#              dated log (STRONG), msgs=NNN FIELD (REQ), token alone
#              (WEAK), nothing (NONE).
#   A claim is STALE if ANY requirement is UNMET on ANY day.
#   Pass 3: for unmet requirements, grep the SIBLING's dated logs for
#   tokens + event markers -> BORROWED candidate (name sibling + log).

set -u

AGENT="${1:?usage: stale-receipt-detector.sh <agent> [root]}"
ROOT="${2:-/root/personalization}"
AUDIT="$ROOT/audit/iar/$AGENT"
JOURNAL="$AUDIT/JOURNAL.org"

[ -f "$JOURNAL" ] || { echo "ERR: no journal at $JOURNAL" >&2; exit 2; }

case "$AGENT" in
  aria) SIBLING=continuo;;
  continuo) SIBLING=aria;;
  *) SIBLING="";;
esac

TMP=$(mktemp /tmp/srd.XXXXXX)
trap 'rm -f "$TMP" "$TMP.sh"' EXIT

# ---- Pass 1: claims + shingles (python) ---------------------------------
python3 - "$JOURNAL" > "$TMP.sh" <<'PYEOF'
import re, sys, collections
cur = 'unknown'
sh_days = collections.defaultdict(set)     # shingle -> days
claim_days = collections.defaultdict(set)  # claim text -> days (union)
claim_reps = collections.Counter()         # claim text -> shingles repeated
for ln in open(sys.argv[1]):
    m = re.match(r'^\*\s+(2026-\d\d-\d\d)', ln)
    if m:
        cur = m.group(1)
        continue
    low = ln.lower()
    if any(v in low for v in ('verified','confirmed','fired','landed','passed')) \
       and re.search(r'\d', ln):
        t = ln.strip()[:600]
        if not t or 'pulse' in low:
            continue
        # c315 fix: strip boilerplate suffixes instead of killing the whole
        # line -- the msgs=401 template ends with 'Held the bass line by
        # monitoring and verifying.' and a substring kill silently removed
        # the primary signal (the echo) from the census (c315 finding).
        t = re.sub(r'(held\s+the\s+bass\s+line\s+by\s+monitoring\s+and\s+verifying\.?|no machinery changes needed\.?)+', ' ', t, flags=re.I).strip(' .;')
        if len(t) < 40:
            continue
        norm = re.sub(r'\d+', 'N', t)
        words = norm.split()
        repeated = False
        for i in range(len(words) - 7):
            s = ' '.join(words[i:i+8])
            sh_days[s].add(cur)
        # after collecting all shingles, mark which repeated
        for i in range(len(words) - 7):
            s = ' '.join(words[i:i+8])
            if len(sh_days[s]) >= 2:
                repeated = True
        if repeated:
            claim_days[t].add(cur)
            claim_reps[t] += 1
for t, days in claim_days.items():
    print(f"{','.join(sorted(days))}\t{claim_reps[t]}\t{t}")
PYEOF

echo "=== STALE-RECEIPT CENSUS v4.4: $AGENT ($(date -u +%Y-%m-%dT%H:%MZ)) ==="
echo "journal: $JOURNAL"
echo

CAND=0; LEGIT=0
while IFS=$'\t' read -r DAYS REPS CLAIM; do
  [ -n "$DAYS" ] || continue
  # --- requirements -------------------------------------------------------
  # MSGS: fence-event assertion "msgs=NNN"
  MSGSTOK=$(echo "$CLAIM" | grep -oE "msgs=[0-9]+" | head -1)
  MSGSN=""
  [ -n "$MSGSTOK" ] && MSGSN=$(echo "$MSGSTOK" | grep -oE "[0-9]+")
  # INSTR: instrument lexicon (claim phrase -> receipt anchor in request logs)
  INSTR=""
  echo "$CLAIM" | grep -qE "census-window|census window|updated (the )?census|ran census" && INSTR="${INSTR:+${INSTR}|}census-window\.sh"
  SUITE_CLAIM=no
  # v4.5 (aria c16): anchor broadened to run-tests (matches run-tests.el,
  # run-tests.sh, bare run-tests, and the ert-run-tests-batch substring).
  # The old run-tests\.el anchor missed the .sh wrapper and bare ert forms --
  # the forms cycle agents actually invoke -- so real runs showed as UNMET.
  echo "$CLAIM" | grep -qE "test suite|suite passed|suite green|suite [0-9]" && { INSTR="${INSTR:+${INSTR}|}run-tests"; SUITE_CLAIM=yes; }
  echo "$CLAIM" | grep -qE "failure-triage|triage" && INSTR="${INSTR}|failure-triage\.sh"
  echo "$CLAIM" | grep -q "fleet-check" && INSTR="${INSTR}|fleet-check\.sh"
  echo "$CLAIM" | grep -q "digest twin" && INSTR="${INSTR}|digest-twin-verifier\.sh"
  echo "$CLAIM" | grep -q "stale-receipt" && INSTR="${INSTR}|stale-receipt-detector\.sh"
  # morning protocol = instrument bundle (any of the core four that day)
  echo "$CLAIM" | grep -q "morning protocol" && INSTR="${INSTR}|census-window\.sh|failure-triage\.sh|run-tests|digest-twin-verifier\.sh"
  # FENCE family: "msgs fence is live" -> load line receipt; truncated-output
  # guard -> [+N chars] truncation markers in request logs
  FENCE_LOAD=no; TRUNC=no; GUARD=no
  echo "$CLAIM" | grep -qE "msgs fence|msgs-fence|context budget guard" && FENCE_LOAD=yes
  echo "$CLAIM" | grep -qE "truncated-output|truncated output" && TRUNC=yes
  # v4.3 (c316): "the loop guard fired" claims -> receipt = loop-guard-chain
  # SOFT BLOCK / HARD STOP lines in the dated log (the guard's own witness)
  echo "$CLAIM" | grep -qE "loop guard|loop-guard" && GUARD=yes
  # GENERIC tokens (only when no msgs=/instrument requirement exists)
  TOKENS=""
  if [ -z "$MSGSTOK" ] && [ -z "$INSTR" ] && [ "$FENCE_LOAD" = no ] && [ "$TRUNC" = no ] && [ "$GUARD" = no ]; then
    TOKENS=$(echo "$CLAIM" | grep -oE "[0-9]{3,}(/[0-9]{3,})?|[0-9]{1,2}/[0-9]{1,2}" | sort -u | head -5 | tr '\n' '|' | sed 's/|$//')
  fi
  [ -n "$MSGSTOK" ] || [ -n "$INSTR" ] || [ "$FENCE_LOAD" = yes ] || [ "$TRUNC" = yes ] || [ "$GUARD" = yes ] || [ -n "$TOKENS" ] || continue

  DETAILS=""; STALE=no; UNMET_TOK=""
  for D in $(echo "$DAYS" | tr ',' ' '); do
    LOG="$AUDIT/cycle-$D.log"
    REQ="$AUDIT/REQUESTS.log"
    REQ1="$AUDIT/REQUESTS.log.1"
    DD=""
    # MSGS requirement
    if [ -n "$MSGSTOK" ]; then
      ok=no
      if [ -f "$LOG" ] && grep -q -E "(${MSGSTOK}|msgs ${MSGSN}).*(fired|warning|blocked)|((fired|warning|blocked)).*(${MSGSTOK}|msgs ${MSGSN})" "$LOG" 2>/dev/null; then
        ok=yes; DD="${DD}msgs:STRONG"
      fi
      if [ "$ok" = no ] && { [ -f "$REQ1" ] && grep -q -E "^\[${D}.*REQ .*START.*msgs=${MSGSN} roles=" "$REQ1" 2>/dev/null; } || { [ "$ok" = no ] && [ -f "$REQ" ] && grep -q -E "^\[${D}.*REQ .*START.*msgs=${MSGSN} roles=" "$REQ" 2>/dev/null; }; then
        ok=yes; DD="${DD}msgs:REQFIELD"
      fi
      [ "$ok" = no ] && { DD="${DD}msgs:UNMET"; STALE=yes; UNMET_TOK="${UNMET_TOK}${MSGSTOK} "; }
    fi
    # INSTR requirement. Receipt ladder (v4.3, c316):
    #   a. PARSE specs=execute_code_local naming the instrument (request logs)
    #   b. HISTORY.log line dated D naming the instrument (the self-written
    #      audit line -- weaker than a, but it is the agent's own witness)
    #   c. a git commit by this agent dated D touching the instrument file
    #      (a fix/land claim is receipted by the commit itself)
    #   d. NOLOG: request logs do not cover day D (blind-witness gaps,
    #      c187 class) -> reported as GAP, not UNMET -- absence of
    #      evidence in a known-blind window is not evidence of absence.
    if [ -n "$INSTR" ]; then
      ok=no; how=""
      # v4.5 (aria c16): RESULT receipt (strongest rung) -- the instrument's
      # own completion signature in the dated request logs. Command-issuance
      # receipts (below) witness that a run was STARTED, not that it
      # COMPLETED: the 09-17 truncation case (suite result cut at test
      # 13/1308, completion line never in the claimant's context) receipted
      # "suite passed (1308/1308)" claims under cmd-only. Require the
      # completion signature with a NONZERO pass count (a "Summary: 0 passed"
      # podman-skip must not receipt a "suite passed" claim).
      if [ "$SUITE_CLAIM" = yes ]; then
        if grep -h -E "^\[${D}.*(Ran [0-9]+ tests, [0-9]+ results as expected|Summary: [1-9][0-9]* passed, 0 failed)" "$REQ1" "$REQ" 2>/dev/null | grep -q .; then
          ok=yes; how="result"
        fi
      fi
      if [ "$ok" = no ] && [ -f "$REQ1" ] && grep -q -E "^\[${D}.*PARSE.*specs=execute_code_local.*(${INSTR})" "$REQ1" 2>/dev/null; then
        ok=yes; how="cmd"
      elif [ "$ok" = no ] && [ -f "$REQ" ] && grep -q -E "^\[${D}.*PARSE.*specs=execute_code_local.*(${INSTR})" "$REQ" 2>/dev/null; then
        ok=yes; how="cmd"
      elif [ -f "$AUDIT/HISTORY.log" ] && grep -q -E "^\[${D}.*(${INSTR})" "$AUDIT/HISTORY.log" 2>/dev/null; then
        ok=yes; how="history"
      else
        # commit receipt: any commit by this agent on day D touching the
        # instrument's file (strip .el/.sh suffix for the path grep)
        for F in $(echo "$INSTR" | tr '|' ' ' | sed 's/\\.//g; s/\.sh$//; s/\.el$//'); do
          if git -C "$ROOT" log --format="%ai" --since="${D} 00:00" --until="${D} 23:59" --author="${AGENT}-agent" -- "knowledge/aria/bin/${F}*" 2>/dev/null | grep -q "^${D}"; then
            ok=yes; how="commit"; break
          fi
        done
      fi
      if [ "$ok" = yes ]; then DD="${DD}instr:MET(${how})"; else
        # blind-witness check: do the request logs cover day D at all?
        if { [ -f "$REQ1" ] && grep -q -E "^\[${D}" "$REQ1" 2>/dev/null; } || { [ -f "$REQ" ] && grep -q -E "^\[${D}" "$REQ" 2>/dev/null; }; then
          DD="${DD}instr:UNMET"; STALE=yes; UNMET_TOK="${UNMET_TOK}instrument(${INSTR}) "
        else
          DD="${DD}instr:NOLOG"; STALE=yes; UNMET_TOK="${UNMET_TOK}instrument(${INSTR},log-blind) "
        fi
      fi
    fi
    # FENCE_LOAD requirement ("the msgs fence is live" -> it loaded that day)
    if [ "$FENCE_LOAD" = yes ]; then
      ok=no
      if [ -f "$LOG" ] && grep -q "iar-msgs-fence.el" "$LOG" 2>/dev/null; then
        ok=yes
      elif { [ -f "$REQ1" ] && grep -q -E "^\[${D}.*(Msgs soft cap|msgs-fence).*(fired|warning|blocked)" "$REQ1" 2>/dev/null; } || { [ -f "$REQ" ] && grep -q -E "^\[${D}.*(Msgs soft cap|msgs-fence).*(fired|warning|blocked)" "$REQ" 2>/dev/null; }; then
        ok=yes
      fi
      if [ "$ok" = yes ]; then DD="${DD}fence:MET"; else DD="${DD}fence:UNMET"; STALE=yes; UNMET_TOK="${UNMET_TOK}msgs-fence "; fi
    fi
    # TRUNC requirement (truncated-output guard fired = [+N chars] markers)
    if [ "$TRUNC" = yes ]; then
      ok=no
      if { [ -f "$REQ1" ] && grep -q -E "^\[${D}.*\[\+[0-9]+ chars\]" "$REQ1" 2>/dev/null; } || { [ -f "$REQ" ] && grep -q -E "^\[${D}.*\[\+[0-9]+ chars\]" "$REQ" 2>/dev/null; }; then
        ok=yes
      elif [ -f "$LOG" ] && grep -q -iE "truncat" "$LOG" 2>/dev/null; then
        ok=yes
      fi
      if [ "$ok" = yes ]; then DD="${DD}trunc:MET"; else DD="${DD}trunc:UNMET"; STALE=yes; UNMET_TOK="${UNMET_TOK}truncated-guard "; fi
    fi
    # GUARD requirement (loop-guard fire receipt)
    if [ "$GUARD" = yes ]; then
      ok=no
      if [ -f "$LOG" ] && grep -q -E "loop-guard-chain. (SOFT BLOCK|HARD STOP)" "$LOG" 2>/dev/null; then
        ok=yes
      elif [ -f "$LOG" ] && grep -q -E "Loop guard|loop guard" "$LOG" 2>/dev/null; then
        ok=yes
      fi
      if [ "$ok" = yes ]; then DD="${DD}guard:MET"; else DD="${DD}guard:UNMET"; STALE=yes; UNMET_TOK="${UNMET_TOK}loop-guard "; fi
    fi
    # GENERIC ladder
    if [ -n "$TOKENS" ]; then
      if [ ! -f "$LOG" ]; then
        DD="${DD}gen:NOLOG"; STALE=yes; UNMET_TOK="${UNMET_TOK}tokens "
      elif grep -q -E "(${TOKENS}).*(fired|warning|blocked|Ran|ERR|error|commit|pushed)|((fired|warning|blocked|Ran|ERR|error|commit|pushed)).*(${TOKENS})" "$LOG" 2>/dev/null; then
        DD="${DD}gen:STRONG"
      elif [ -f "$REQ" ] && grep -q -E "^\[${D}.*\] REQ .*msgs=[0-9]+ roles=" "$REQ" 2>/dev/null && echo "$CLAIM" | grep -qE "msgs [0-9]+|msgs=[0-9]+"; then
        DD="${DD}gen:REQ"
      elif grep -q -E "${TOKENS}" "$LOG" 2>/dev/null; then
        DD="${DD}gen:WEAK"; STALE=yes; UNMET_TOK="${UNMET_TOK}weak-tokens "
      else
        DD="${DD}gen:NONE"; STALE=yes; UNMET_TOK="${UNMET_TOK}tokens "
      fi
    fi
    DETAILS="$DETAILS $D[$DD]"
  done

  if [ "$STALE" = no ]; then
    LEGIT=$((LEGIT+1))
    echo "REPETITIVE-RECEIPTED (days:$DAYS reps:$REPS) -- template repeats, work receipted"
    echo "  claim: ${CLAIM:0:160}"
    echo
    continue
  fi

  CAND=$((CAND+1))
  echo "STALE-CANDIDATE #$CAND (days:$DAYS reps:$REPS receipts:$DETAILS)"
  echo "  claim: ${CLAIM:0:220}"
  if [ -n "$UNMET_TOK" ]; then
    echo "  unmet: ${UNMET_TOK%% }"
  fi
  # Pass 3: borrowed check against sibling dated logs (for unmet tokens)
  if [ -n "$SIBLING" ] && [ -n "$UNMET_TOK" ]; then
    # v4.4 (c325): normalize to BARE numbers. The claim carries "msgs=401"
    # (the model's spelling) but the fence's own log line carries
    # "msgs 401" (the guard's spelling) -- a form-anchored BTOK never
    # matches and the borrowed check silently no-ops (verified live
    # 2026-09-14: continuo's msgs=401 claims borrowed from aria's
    # 09-11..14 fence fires, BORROWED-CANDIDATE never printed).
    # Bare numbers match both forms.
    BTOK=$(echo "$UNMET_TOK" | grep -oE "[0-9]{3,}" | sort -u | head -3 | tr '\n' '|' | sed 's/|$//')
    if [ -n "$BTOK" ]; then
      FOUND=""
      for SD in 2026-09-09 2026-09-10 2026-09-11 2026-09-12 2026-09-13 2026-09-14; do
        SLOG="$ROOT/audit/iar/$SIBLING/cycle-$SD.log"
        [ -f "$SLOG" ] || continue
        if grep -q -E "(${BTOK}).*(fired|warning|blocked|ERR|error)|((fired|warning|blocked|ERR|error)).*(${BTOK})" "$SLOG" 2>/dev/null; then
          FOUND="$SLOG"
          break
        fi
      done
      if [ -n "$FOUND" ]; then
        echo "  BORROWED-CANDIDATE: unmet tokens + event markers found in sibling"
        echo "    $SIBLING's log: $FOUND"
        echo "    -> claim likely describes the SIBLING's event, re-asserted as own."
      fi
    fi
  fi
  echo
done < "$TMP.sh"

echo "=== done: $CAND stale candidates, $LEGIT repetitive-but-receipted claims ==="
exit 0