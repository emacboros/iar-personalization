#!/bin/bash
# nocturne-digest.sh v3 (2026-09-14, aria cycle 330)
# ---------------------------------------------------------
# Nocturne daily digest pass: change-gated one-shot consolidation.
# Gate: personalization repo HEAD vs audit/nocturne/nocturne/LAST-DIGESTED-HEAD.
# Unchanged HEAD -> exit 0, model never loads (iara/heartbeat gate pattern).
# Changed -> compose delta prompt -> iar.sh --one-shot --agent nocturne.
# Never touches DIGEST.md (Nocturne writes DIGEST.proposed.md only).
# Never exits nonzero (feeder pattern: failures land in the log).
#
# v2: audit path unified to audit/<project>/<agent>/ (iar.sh c223 fix).
# The wrapper artifacts (LAST-DIGESTED-HEAD, oneshot logs) now live in
# the same tree the elisp path builders write (REQUESTS/USAGE/cycle.log).
# Back-compat: if the new STATE file is absent but the old
# audit/iar/nocturne/ one exists, it is migrated (mv) so the gate
# never re-digests an already-digested range.
#
# v3 (c330): three gate hardenings.
#   1. PULL-REEXEC: the section-0 pull can rewrite THIS script (patches
#      land via sophon-bare; the checkout ff-forwards here). Bash reads
#      scripts incrementally, so continuing to execute a rewritten file
#      at a stale byte offset is undefined. After the pull, re-exec the
#      fresh bytes. NOC_REEXEC guard prevents a loop.
#   2. RECEIPT ENFORCEMENT (c327 made real): the c327 prompt text asked
#      for a RECEIPT line but nothing checked it. Now the extracted
#      final response must contain a RECEIPT line whose stat output
#      matches this run's proposal stat (second-precision timestamp +
#      byte size).
#   3. ECHO-CHECK (c328 law): this run's final response is extracted
#      (anchored to this run's log line range -- block-boundary law)
#      and md5-compared against every prior final response in the log.
#      Byte-match = context-echo recycling = the record is input, not
#      work = gate does NOT advance.
# Gate advance now requires ALL of: rc=0, proposal mtime fresh this run
# (c317), receipt present+matching, no echo match.

set -u

PERS=/var/home/nacho/repos/iar-personalization
IAR=/var/home/nacho/repos/i.ar
LOGTAG="nocturne-digest"
STATE="$PERS/audit/nocturne/nocturne/LAST-DIGESTED-HEAD"
STATE_OLD="$PERS/audit/iar/nocturne/LAST-DIGESTED-HEAD"
PROPOSED="$PERS/audit/iar/aria/DIGEST.proposed.md"
DIGLOG=/var/log/nocturne-digest.log
MODEL="deepseek-v4.1-flash:cloud"
CTX=262144
TIMEOUT=1800
WEEKLY=0
[[ "${1:-}" == "--weekly" ]] && WEEKLY=1

ts() { date -u +%FT%TZ; }
log() { echo "[$(ts)] $LOGTAG: $*"; }

# resolve BEFORE any cd (a relative $0 must be resolved in the caller's cwd)
SCRIPT_PATH=$(readlink -f "$0")

cd "$PERS" || { log "FATAL: cannot cd $PERS"; exit 0; }

# --- 0. pull latest record, then RE-EXEC the fresh script (c330)
# file:// remote avoids ssh key questions. If the pull rewrote this
# script, the pre-exec bytes are stale -- re-exec gets the new ones.
if [[ -z "${NOC_REEXEC:-}" ]]; then
    git fetch file:///home/git/repos/iar-personalization.git main -q 2>/dev/null
    if git merge --ff-only FETCH_HEAD -q 2>/dev/null; then
        log "record fast-forwarded to $(git rev-parse --short HEAD)"
    else
        log "record NOT fast-forwarded (diverged or dirty) -- continuing on local state"
    fi
    export NOC_REEXEC=1
    exec bash "$SCRIPT_PATH" "$@"
fi

# --- 0b. one-time state migration (v1 path -> v2 path)
if [[ ! -f "$STATE" && -f "$STATE_OLD" ]]; then
    mkdir -p "$(dirname "$STATE")"
    mv "$STATE_OLD" "$STATE"
    rmdir "$PERS/audit/iar/nocturne" 2>/dev/null || true
    log "migrated LAST-DIGESTED-HEAD from v1 path (gate preserved)"
fi

HEAD_NOW=$(git rev-parse HEAD)
LAST=$(cat "$STATE" 2>/dev/null || echo "")

# --- 1. gate
if [[ -n "$LAST" && "$LAST" == "$HEAD_NOW" ]]; then
    log "no change since last digest ($LAST) -- no-op"
    exit 0
fi

if [[ -z "$LAST" ]]; then
    log "first run: no LAST-DIGESTED-HEAD -- digesting last 24h of commits"
    LAST=$(git rev-parse HEAD~20 2>/dev/null || git rev-list --max-parents=0 HEAD)
fi

# --- 1b. range cap (v4, c332): a range the model cannot hold produces
# context-echo recycling, not digestion (the 09-14 16:04Z pass burned
# 1.38M tokens on a 534-commit range and re-emitted the 09-12 response
# verbatim). Cap the range to the last MAX_RANGE commits; the gate
# advances to the CAPPED head -- the range actually digested -- and the
# skipped remainder is logged, never silently dropped. The next pass
# continues from there; the timer catches up over multiple days.
MAX_RANGE=300
RANGE_COUNT=$(git rev-list --count "$LAST..$HEAD_NOW" 2>/dev/null || echo 0)
if [[ "$RANGE_COUNT" -gt "$MAX_RANGE" ]]; then
    CAPPED_HEAD=$(git rev-list -n "$MAX_RANGE" --first-parent HEAD 2>/dev/null | tail -1)
    if [[ -n "$CAPPED_HEAD" && "$CAPPED_HEAD" != "$LAST" ]]; then
        log "RANGE-CAP: $RANGE_COUNT commits since $LAST exceeds MAX_RANGE=$MAX_RANGE -- digesting $LAST..$CAPPED_HEAD, $(git rev-list --count "$CAPPED_HEAD..$HEAD_NOW") commits deferred to later passes"
        HEAD_NOW="$CAPPED_HEAD"
    fi
fi

log "digesting $LAST..$HEAD_NOW (weekly=$WEEKLY)"

# --- 2. compose the delta
DELTA=$(git -C "$PERS" diff --stat "$LAST" "$HEAD_NOW" 2>/dev/null | tail -30)
CHANGED_FILES=$(git -C "$PERS" diff --name-only "$LAST" "$HEAD_NOW" 2>/dev/null | head -40)
COMMIT_LOG=$(git -C "$PERS" log --oneline "$LAST..$HEAD_NOW" 2>/dev/null | head -40)

# The memory files that changed -- Nocturne reads them itself via
# read_file (one-shot archetype injects no memory by design).
MEM_CHANGED=$(git -C "$PERS" diff --name-only "$LAST" "$HEAD_NOW" 2>/dev/null \
    | grep -E "audit/iar/(aria|continuo)/(JOURNAL|LOGS|DIGEST|HISTORY)|relay/|DECISIONS" | head -20)

# --- 3. build the instruction
PROMPT_FILE=$(mktemp /tmp/nocturne-prompt-XXXXXX)
{
echo "Run type: $([[ $WEEKLY -eq 1 ]] && echo WEEKLY || echo DAILY)"
echo "Range: $LAST..$HEAD_NOW"
echo ""
echo "== Commits in range =="
echo "$COMMIT_LOG"
echo ""
echo "== Changed files (stat) =="
echo "$DELTA"
echo ""
echo "== Memory/relay files changed (READ THESE with read_file) =="
echo "$MEM_CHANGED"
echo ""
echo "== Current live digest (audit/iar/aria/DIGEST.md) =="
cat "$PERS/audit/iar/aria/DIGEST.md" 2>/dev/null | head -100
echo ""
echo "TASK: Produce the proposed updated digest. Write it to"
echo "/root/personalization/audit/iar/aria/DIGEST.proposed.md"
echo "$([[ $WEEKLY -eq 1 ]] && echo 'WEEKLY PASS: also do the repetition audit, THREADS gardening proposals, attic-move proposals, and file the debrief to the relay (relay file ours-direction ...).')"
echo "Read the changed memory files listed above before writing."
echo "Your fence: DIGEST.proposed.md only (plus weekly: one relay filing + proposals appendix)."
echo "RECEIPT REQUIREMENT (c327, ENFORCED by the wrapper since c330): after"
echo "the write_file call succeeds, run"
echo "  stat -c '%y %s' /root/personalization/audit/iar/aria/DIGEST.proposed.md"
echo "and quote its output VERBATIM on its own line in your final response"
echo "(format: RECEIPT: <stat output>). The wrapper extracts your final"
echo "response and verifies the RECEIPT against the disk. A final response"
echo "without a matching RECEIPT line will not advance the gate and the"
echo "pass does not count."
} > "$PROMPT_FILE"

PROMPT=$(cat "$PROMPT_FILE")
rm -f "$PROMPT_FILE"

# --- 3b. STALE-PROPOSAL RESERVOIR DRAIN (c358, relay 0068 mechanism arm)
# An unratified proposal OLDER than the previous pass is an echo
# reservoir: the pass reads it, the text enters context, the model
# echoes it as its final response (09-14 16:04Z, 1.38M tokens burned).
# The echo-check catches the echo; the reservoir still burns the read.
# Mechanism (mine, per 0068 alternative): at wrapper start, if the
# proposal exists AND was last modified BEFORE this wrapper invocation
# began (i.e. it was not written by a concurrent pass -- trivially true
# at start), archive it to the attic. The pass then starts with no
# proposal on disk; anything Nocturne writes fresh is hers. Ratification
# policy stays Nacho's (0068 open); this only removes the reservoir.
# ATTIC LAW: move, never delete.
if [[ -f "$PROPOSED" ]]; then
    ATTIC="$PERS/audit/nocturne/nocturne/attic"
    mkdir -p "$ATTIC"
    STAMP=$(date -u +%Y%m%dT%H%M%SZ)
    ARCHIVED="$ATTIC/DIGEST.proposed.$STAMP.md"
    mv "$PROPOSED" "$ARCHIVED"
    chmod 644 "$ARCHIVED" 2>/dev/null
    log "RESERVOIR-DRAIN: unratified proposal archived to $ARCHIVED (0068 mechanism; pass starts clean)"
fi

# --- 4. run the one-shot (frozen-copy pattern per relay 0041)
# c317: snapshot the proposal mtime -- the gate must only advance if
# THIS run rewrote the proposal. A stale proposal from a previous run
# (e.g. the 09-12 one that survived the 429 wall) existing on disk
# must not mask an undigested range.
PROP_MTIME_BEFORE=$(stat -c %Y "$PROPOSED" 2>/dev/null || echo 0)
# c330: log line watermark -- the echo-check and receipt check must only
# consider THIS run's log output (block-boundary law: position in an
# append-only log is not evidence of which run a block belongs to).
LOG_LINES_BEFORE=0
if [[ -f "$DIGLOG" ]]; then
    LOG_LINES_BEFORE=$(wc -l < "$DIGLOG")
fi
iar_wrap="/tmp/nocturne-wrap-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$iar_wrap/utils"
cp -a /var/home/nacho/repos/i.ar/utils/iar.sh "$iar_wrap/utils/iar.sh"
ln -sfn /var/home/nacho/repos/i.ar/metaconfig "$iar_wrap/metaconfig"
ln -sfn /var/home/nacho/repos/i.ar/emacs.d "$iar_wrap/emacs.d"
ln -sfn /var/home/nacho/repos/i.ar/prompts "$iar_wrap/prompts"

log "launching one-shot (model $MODEL, ctx $CTX, timeout ${TIMEOUT}s)"
IAR_REPO_DIR=/var/home/nacho/repos/i.ar \
bash "$iar_wrap/utils/iar.sh" --one-shot \
    --project nocturne \
    --personalization "$PERS" \
    --agent nocturne \
    --prompt "$PROMPT" \
    --ollama-host 10.66.0.5:11434 \
    --model "$MODEL" \
    --ctx "$CTX" \
    --timeout "$TIMEOUT" \
    --gptel-fork /var/home/nacho/repos/gptel \
    --ssh-key aria_ed25519 \
    >> "$DIGLOG" 2>&1
rc=$?

log "one-shot exit=$rc"

# --- 5. gate decision (c317 mtime + c330 receipt + c330 echo-check)
# v4 (c332): echo-check + claim-receipt-check run on EVERY rc=0 run,
# NOT only when the proposal was rewritten. The 09-14 16:04Z pass
# recycled the 09-12 final response verbatim (b3==b4, zero writes,
# 1.38M tokens) and the mtime gate classified it as "stale proposal"
# -- the echo never fired because the checks were nested inside the
# mtime branch. The echo-check exists precisely for the no-write case.
ADVANCE=0
ECHO_STATUS=""
if [[ $rc -eq 0 ]]; then
    # extract this run's final response (watermark-anchored) and run
    # the echo-check regardless of proposal state
    TMPD=$(mktemp -d /tmp/nocturne-echo-XXXXXX)
    extract_blocks() {
        awk -v out="$2" '
            index($0, "=== BEGIN FINAL RESPONSE ===") {inb=1; buf=""; next}
            index($0, "=== END FINAL RESPONSE ===") {
                if (inb && length(buf) > 0) {n++; printf "%s", buf > (out "b" n ".txt")}
                inb=0; buf=""; next
            }
            inb {buf = buf $0 "\n"}
        ' "$1"
    }
    norm_block() {
        awk '{ gsub(/\r/,""); sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); if (length($0)>0) print }' "$1" | md5sum | cut -d' ' -f1
    }
    extract_blocks <(head -n "$LOG_LINES_BEFORE" "$DIGLOG") "$TMPD/prior_"
    extract_blocks <(tail -n +$((LOG_LINES_BEFORE+1)) "$DIGLOG") "$TMPD/cur_"
    CURFILE=$(ls "$TMPD"/cur_b*.txt 2>/dev/null | sort -V | tail -1)
    if [[ -z "$CURFILE" ]]; then
        log "ECHO-CHECK: no final-response block in this run's log range (lines $((LOG_LINES_BEFORE+1))..) -- nothing fresh to trust"
    else
        CUR_MD5=$(norm_block "$CURFILE")
        for pf in "$TMPD"/prior_b*.txt; do
            [[ -f "$pf" ]] || continue
            if [[ "$(norm_block "$pf")" == "$CUR_MD5" ]]; then
                ECHO_HIT="$pf"
                break
            fi
        done
        if [[ -n "${ECHO_HIT:-}" ]]; then
            ECHO_STATUS="echo"
            log "ECHO-RECEIPT (c332): this run's final response byte-matches prior block $ECHO_HIT -- context-echo recycling, NOT advancing gate (c328 law)"
        else
            ECHO_STATUS="clean"
            log "echo-check clean (this run's response is novel)"
        fi
        # claim-receipt check: if the response CLAIMS a write, require
        # the RECEIPT line matching the proposal's CURRENT disk stat
        if grep -qiE "written|RECEIPT:" "$CURFILE"; then
            PROP_STAT_NOW=$(stat -c '%y %s' "$PROPOSED" 2>/dev/null || echo "")
            STAT_DT=$(printf '%s' "$PROP_STAT_NOW" | cut -c1-19)
            STAT_SIZE=$(printf '%s' "$PROP_STAT_NOW" | awk '{print $NF}')
            RECEIPT_LINE=$(grep -h "RECEIPT:" "$CURFILE" 2>/dev/null | head -1)
            if [[ -z "$RECEIPT_LINE" ]]; then
                log "CLAIM-RECEIPT-FAIL (c332): final response claims a write but carries no RECEIPT line -- the claim is narration, not evidence"
            elif [[ "$RECEIPT_LINE" != *"$STAT_DT"* || "$RECEIPT_LINE" != *"$STAT_SIZE"* ]]; then
                log "CLAIM-RECEIPT-FAIL (c332): RECEIPT line does not match proposal disk stat ($STAT_DT $STAT_SIZE) -- claim is narration, not evidence"
            else
                log "claim-receipt verified against disk"
            fi
        fi
    fi
    rm -rf "$TMPD"
fi

if [[ $rc -eq 0 && -f "$PROPOSED" ]]; then
    PROP_MTIME_AFTER=$(stat -c %Y "$PROPOSED" 2>/dev/null || echo 0)
    if [[ "$PROP_MTIME_AFTER" -gt "$PROP_MTIME_BEFORE" ]]; then
        # proposal rewritten this run: verify the RECEIPT against the
        # fresh stat (c327 enforcement). Echo-check already ran above
        # (v4: on every rc=0 run).
        PROP_STAT_AFTER=$(stat -c '%y %s' "$PROPOSED" 2>/dev/null || echo "")
        STAT_DT=$(printf '%s' "$PROP_STAT_AFTER" | cut -c1-19)
        STAT_SIZE=$(printf '%s' "$PROP_STAT_AFTER" | awk '{print $NF}')
        RECEIPT_LINE=$(grep -h "RECEIPT:" "${CURFILE:-/dev/null}" 2>/dev/null | head -1)
        RECEIPT_OK=0
        if [[ -n "$PROP_STAT_AFTER" && -n "$RECEIPT_LINE" \
              && "$RECEIPT_LINE" == *"$STAT_DT"* \
              && "$RECEIPT_LINE" == *"$STAT_SIZE"* ]]; then
            RECEIPT_OK=1
        fi
        if [[ "$ECHO_STATUS" == "echo" ]]; then
            log "NOT advancing gate: echo-recycle already logged above"
        elif [[ $RECEIPT_OK -ne 1 ]]; then
            log "RECEIPT-FAIL (c330): final response lacks a RECEIPT line matching this run's proposal stat ($STAT_DT $STAT_SIZE) -- NOT advancing gate (c327 enforcement)"
        else
            ADVANCE=1
        fi
    else
        if [[ "$ECHO_STATUS" == "echo" ]]; then
            log "NOT advancing gate: proposal NOT rewritten AND final response is an echo-recycle (c328) -- the run produced nothing fresh"
        else
            log "NOT advancing gate (rc=0 but proposal NOT rewritten this run -- stale proposal would mask $LAST..$HEAD_NOW)"
        fi
    fi
    if [[ $ADVANCE -eq 1 ]]; then
        echo "$HEAD_NOW" > "$STATE"
        log "proposal rewritten this run; receipt verified; no echo; gate advanced to $HEAD_NOW"
    fi
else
    log "NOT advancing gate (rc=$rc, proposal_exists=$([[ -f $PROPOSED ]] && echo yes || echo no))"
fi

exit 0