#!/bin/bash
# nocturne-digest.sh v8 (2026-09-18, aria c48: D-016 AGORA RETENTION SURFACE)
#   On gate ADVANCE: post the final response to the digest stream
#   (summarize first), then delete lab-notes (whole stream, D-016 item 4)
#   >7d in ledgered batches of 100 (delete second). Human-
#   stream move-to-archive pending relay 0083 grants. Both steps
#   best-effort; failures never fail the pass (feeder pattern).
#   Retention rides gate-ADVANCE: a quiet repo week stalls deletion
#   (bounded: ~1 lab-notes msg/cycle accrues; next ADVANCE clears 100).
#
# nocturne-digest.sh v7 (2026-09-17, aria c28: DURABLE VERDICT FILE)
#   Every log() line now also appends to audit/nocturne/nocturne/VERDICTS.log
#   (journald rotates wrapper verdicts away -- 20 lines retained since 09-11;
#   the diglog has responses but the gate DECISIONS were evaporating).
#
# nocturne-digest.sh v6 (2026-09-17, aria c27: FRAGMENT FLOOR, relay 0078 bug 2)
#   A final response shorter than FLOOR_CHARS (200) normalized chars is
#   dissolution, not summary: the 09-17 pass emitted 37 chars of this
#   wrapper's own awk code as its final response -- novel, so the echo-check
#   passed it (novelty catches repetition, not dissolution). Corpus scan
#   (c27, /var/log/nocturne-digest.log): real responses 2380-3041 normalized
#   chars (n=4 instances, 2 distinct), fragments 0 and 37. Floor 200 sits
#   12x below the smallest real response. CLASSIFICATION ONLY: gate safety
#   unchanged (advance still requires fresh proposal + matching receipt;
#   a short response accompanying a real write+receipt still advances).
# nocturne-digest.sh v5 (2026-09-17, aria c26: range-cap DIRECTION fix)
# v5 (c26): CAPPED_HEAD was the 300th commit back from HEAD, making the
# digested range debt-299 (1143 commits at debt 1442) -- the cap failed
# exactly in the deep-debt case it was built for (relay 0078). Now the
# cap takes the 300th commit AFTER LAST: range = min(debt, 300),
# remainder deferred. Fixture-tested: debt 301->300+1, 349->300+49,
# 300->no fire, 3->no fire.
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
# v7 (c28): durable verdict file -- journald rotates wrapper verdicts away
# (20 lines retained since 09-11); every log() line also lands here.
VLOG="$PERS/audit/nocturne/nocturne/VERDICTS.log"
# v8 (c48): retention ledger -- every deletion batch lands here (D-016
# order law: summarize first, delete second, every batch ledgered).
RLOG="$PERS/audit/nocturne/nocturne/RETENTION.log"
# v8 (c48): agora bot credentials (aria-cycle@, the retention actor).
ZULIP_CONF=/var/home/nacho/repos/agora/bot/aria-cycle.conf
MODEL="deepseek-v4.1-flash:cloud"
CTX=262144
TIMEOUT=1800
WEEKLY=0
[[ "${1:-}" == "--weekly" ]] && WEEKLY=1

ts() { date -u +%FT%TZ; }
log() {
    local line="[$(ts)] $LOGTAG: $*"
    echo "$line"
    echo "$line" >> "$VLOG" 2>/dev/null || true
}

# v8 (c48): retention ledger helper -- same dual-write pattern as log().
rlog() {
    local line="[$(ts)] RETENTION: $*"
    echo "$line" >> "$RLOG" 2>/dev/null || true
}

# resolve BEFORE any cd (a relative $0 must be resolved in the caller's cwd)
SCRIPT_PATH=$(readlink -f "$0")

cd "$PERS" || { log "FATAL: cannot cd $PERS"; exit 0; }

# v7: verdict dir must exist before the first log() call (log() mirrors
# into VLOG; a missing dir would make every verdict line unwritable).
mkdir -p "$(dirname "$VLOG")" 2>/dev/null || true

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
    CAPPED_HEAD=$(git rev-list --first-parent --reverse "$LAST..$HEAD_NOW" 2>/dev/null | sed -n "${MAX_RANGE}p")
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
FRAGMENT=0
CURTEXT=""
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
        # FRAGMENT FLOOR (v6, c27, relay 0078 bug 2): a tiny final response
        # is dissolution, not summary. The 09-17 pass emitted 37 normalized
        # chars of the wrapper's own awk code -- novel, so the echo-check
        # passed it. Floor is classification: the gate already refuses to
        # advance without a fresh proposal + matching receipt.
        CUR_NCHARS=$(awk '{ gsub(/\r/,""); sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); if (length($0)>0) print }' "$CURFILE" | wc -c)
        FLOOR_CHARS=200
        if [[ "$CUR_NCHARS" -lt "$FLOOR_CHARS" ]]; then
            FRAGMENT=1
            log "FRAGMENT-EMISSION (c27): final response is $CUR_NCHARS normalized chars (< floor $FLOOR_CHARS) -- dissolution, not summary; treating as no-response (relay 0078 bug 2)"
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
    CURTEXT=$(cat "$CURFILE")
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
            if [[ "$FRAGMENT" -eq 1 ]]; then
                log "NOT advancing gate: proposal NOT rewritten AND final response is a fragment (c27) -- the run produced nothing"
            else
                log "NOT advancing gate (rc=0 but proposal NOT rewritten this run -- stale proposal would mask $LAST..$HEAD_NOW)"
            fi
        fi
    fi
    if [[ $ADVANCE -eq 1 ]]; then
        echo "$HEAD_NOW" > "$STATE"
        log "proposal rewritten this run; receipt verified; no echo; gate advanced to $HEAD_NOW"

        # --- 6. D-016 AGORA RETENTION SURFACE (v8, c48)
        # ORDER LOAD-BEARING (D-016): summarize first, delete second.
        # Both steps best-effort: a failed post or delete never fails
        # the digest pass (feeder pattern); every action is ledgered.
        if [[ -z "${NOC_RETENTION_DONE:-}" ]]; then
            export NOC_RETENTION_DONE=1
            SITE=$(awk -F'= ' '/^site /{print $2}' "$ZULIP_CONF" 2>/dev/null)
            ZEMAIL=$(awk -F'= ' '/^email /{print $2}' "$ZULIP_CONF" 2>/dev/null)
            ZKEY=$(awk -F'= ' '/^key /{print $2}' "$ZULIP_CONF" 2>/dev/null)
            if [[ -z "$ZKEY" ]]; then
                log "RETENTION-SKIP: no zulip credentials readable at $ZULIP_CONF"
            else
                zpost() { # zpost <stream> <topic> <content>
                    curl -s -u "$ZEMAIL:$ZKEY" -X POST "$SITE/api/v1/messages" \
                        --data-urlencode "type=stream" \
                        --data-urlencode "to=$1" \
                        --data-urlencode "topic=$2" \
                        --data-urlencode "content=$3"
                }
                # 6a. POST THE SUMMARY (the final response IS the summary).
                # Weekly runs get a weekly topic; daily a daily one.
                if [[ $WEEKLY -eq 1 ]]; then
                    DTOPIC="weekly-$(date -u +%G-W%V)"
                else
                    DTOPIC="daily-$(date -u +%F)"
                fi
                POST_RC=$(zpost "digest" "$DTOPIC" "$CURTEXT" | jq -r '.result // "error"' 2>/dev/null)
                if [[ "$POST_RC" == "success" ]]; then
                    log "DIGEST-POSTED: summary posted to digest/$DTOPIC"
                else
                    log "DIGEST-POST-FAIL: result=$POST_RC (summary NOT posted; deletion deferred by order law)"
                fi
                # 6b. DELETE LAB-NOTES >7d (only if the summary posted).
                if [[ "$POST_RC" == "success" ]]; then
                    CUTOFF_TS=$(($(date -u +%s) - 7*86400))
                    OLDMINE=$(curl -s -u "$ZEMAIL:$ZKEY" \
                        "$SITE/api/v1/messages?anchor=newest&num_before=5000&num_after=0&narrow=%5B%7B%22operator%22%3A%22stream%22%2C%22operand%22%3A%22lab-notes%22%7D%5D" \
                        | jq -r --argjson c "$CUTOFF_TS" \
                          '.messages[] | select(.timestamp < $c) | "\(.id)|\(.subject)"' 2>/dev/null)
                    N_DEL=$(printf '%s\n' "$OLDMINE" | grep -c '|' 2>/dev/null || true)
                    [[ -z "$N_DEL" ]] && N_DEL=0
                    if [[ "$N_DEL" -eq 0 ]]; then
                        log "RETENTION: no lab-notes messages older than 7d -- nothing to delete"
                    else
                        rlog "batch start: $N_DEL lab-notes messages >7d (whole stream per D-016 item 4)"
                        printf '%s\n' "$OLDMINE" | grep '|' | head -100 | while IFS='|' read -r MID MTOPIC; do
                            DRC=$(curl -s -u "$ZEMAIL:$ZKEY" -X DELETE "$SITE/api/v1/messages/$MID" | jq -r '.result // "error"' 2>/dev/null)
                            if [[ "$DRC" == "success" ]]; then
                                rlog "deleted id=$MID topic=$MTOPIC"
                            else
                                rlog "DELETE-FAIL id=$MID topic=$MTOPIC result=$DRC"
                            fi
                        done
                        DEFER=$(( N_DEL > 100 ? N_DEL - 100 : 0 ))
                        if [[ $DEFER -gt 0 ]]; then
                            rlog "batch cap 100: $DEFER messages deferred to next pass"
                        fi
                        log "RETENTION: lab-notes deletion pass done ($N_DEL found, batch cap 100) -- see RETENTION.log"
                    fi
                else
                    log "RETENTION-DEFERRED: summary post failed -- deletion skipped (summarize-first law)"
                fi
                # 6c. Human-stream 30d move-to-archive NOT built here:
                # move_out/move_in = role:nobody on the human streams
                # (relay 0083 open). Nothing to do until the grant lands.
            fi
        fi
    fi
else
    log "NOT advancing gate (rc=$rc, proposal_exists=$([[ -f $PROPOSED ]] && echo yes || echo no))"
fi

exit 0