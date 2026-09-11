#!/bin/bash
# nocturne-digest.sh v1 (2026-09-11, aria session XV, D-015)
# ---------------------------------------------------------
# Nocturne daily digest pass: change-gated one-shot consolidation.
# Gate: personalization repo HEAD vs audit/iar/nocturne/LAST-DIGESTED-HEAD.
# Unchanged HEAD -> exit 0, model never loads (iara/heartbeat gate pattern).
# Changed -> compose delta prompt -> iar.sh --one-shot --agent nocturne.
# Never touches DIGEST.md (Nocturne writes DIGEST.proposed.md only).
# Never exits nonzero (feeder pattern: failures land in the log).
set -u

PERS=/var/home/nacho/repos/iar-personalization
IAR=/var/home/nacho/repos/i.ar
LOGTAG="nocturne-digest"
STATE="$PERS/audit/iar/nocturne/LAST-DIGESTED-HEAD"
PROPOSED="$PERS/audit/iar/aria/DIGEST.proposed.md"
MODEL="deepseek-v4.1-flash:cloud"
CTX=262144
TIMEOUT=1800
WEEKLY=0
[[ "${1:-}" == "--weekly" ]] && WEEKLY=1

ts() { date -u +%FT%TZ; }
log() { echo "[$(ts)] $LOGTAG: $*"; }

cd "$PERS" || { log "FATAL: cannot cd $PERS"; exit 0; }

# --- 0. pull latest record (file:// remote avoids ssh key questions)
git fetch file:///home/git/repos/iar-personalization.git main -q 2>/dev/null
if git merge --ff-only FETCH_HEAD -q 2>/dev/null; then
    log "record fast-forwarded to $(git rev-parse --short HEAD)"
else
    log "record NOT fast-forwarded (diverged or dirty) -- continuing on local state"
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
} > "$PROMPT_FILE"

PROMPT=$(cat "$PROMPT_FILE")
rm -f "$PROMPT_FILE"

# --- 4. run the one-shot (frozen-copy pattern per relay 0041)
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
    >> /var/log/nocturne-digest.log 2>&1
rc=$?

log "one-shot exit=$rc"

# --- 5. verify the proposal exists before advancing the gate
if [[ $rc -eq 0 && -f "$PROPOSED" ]]; then
    echo "$HEAD_NOW" > "$STATE"
    log "proposal written; gate advanced to $HEAD_NOW"
else
    log "NOT advancing gate (rc=$rc, proposal_exists=$([[ -f $PROPOSED ]] && echo yes || echo no))"
fi

exit 0