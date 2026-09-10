#!/bin/bash
# connectome-snapshot.sh -- i.ar connectome weekly snapshot (D-009 fossil-instrument family)
# Design: knowledge/iar/connectome-metrics-design.md (session VIII, ratified)
# Runs ON sophon (ssh 'bash -s' < connectome-snapshot.sh). Merges BOTH hosts'
# audit logs (the single-host blind-spot fix) + REQUESTS.log token economics.
#
# Data sources (verified 2026-09-08):
#   sophon: /var/home/nacho/repos/iar-personalization/audit/audit.log{,.1}
#   container: audit/audit.log -- shipped via scp to sophon /tmp per run
#
# Traps honored: census-echo law (anchor on line structure, never query
# tokens), nil-agent rows excluded, status=rejected counted separately,
# first snapshot = baseline only (no trend claims).
#
# REQUESTS.log LINE SHAPE (verified 2026-09-09, c115 -- the c115 scar):
#   [ts] REQ <id> PARSE status=... error=X stop=Y tokens_in=N tokens_out=M
#   [ts] REQ <id> START backend=... model=... msgs=N ...
#   [ts] REQ <id> RESPONSE http=200 body_tail=...
# There is NO agent field in REQUESTS.log lines. The per-agent partition
# IS the file path (audit/iar/<agent>/REQUESTS.log). Any grep that anchors
# on "] <agent> | PARSE | " matches ONLY self-echo (census commands
# quoting the pattern in specs=) and NEVER a genuine line. All REQUESTS.log
# greps here anchor on '] REQ <id> PARSE ' instead.
set -u
REPO=/var/home/nacho/repos/iar-personalization
AUDIT_DIR=$REPO/audit
OUT_DIR=$REPO/knowledge/aria/connectome
COFIRE_WINDOW=5   # seconds
TOPN=15
WEEK=$(date -u +%G-W%V)
OUT=$OUT_DIR/snapshot-$WEEK.md
mkdir -p "$OUT_DIR" /tmp/connectome

# --- merge: sophon logs + container log shipped to /tmp ---
cat "$AUDIT_DIR/audit.log.1" "$AUDIT_DIR/audit.log" > /tmp/connectome/merged.log
if [ -s /tmp/connectome/container-audit.log ]; then
    cat /tmp/connectome/container-audit.log >> /tmp/connectome/merged.log
fi
MERGED=/tmp/connectome/merged.log

# tool_call lines only; drop nil-agent rows (pre-fix window) and mirror noise
grep ' | tool_call | ' "$MERGED" \
  | grep -v 'name=nil' \
  | grep -vE '\| (mirror|convagent|bessie|unknown|agent-assistant) \|' \
  > /tmp/connectome/tools.log
TOOL_LINES=$(wc -l < /tmp/connectome/tools.log)
ARIA_LINES=$(grep -c '] aria | tool_call' /tmp/connectome/tools.log)
CONT_LINES=$(grep -c '] continuo | tool_call' /tmp/connectome/tools.log)

{
echo "# Connectome snapshot $WEEK"
echo
echo "Generated: $(date -u '+%Y-%m-%d %H:%M UTC') | window: $COFIRE_WINDOW s | TOPN: $TOPN"
echo
echo "## Population"
echo
echo "| source | tool_call lines |"
echo "|---|---|"
echo "| merged (both hosts) | $TOOL_LINES |"
echo "| aria | $ARIA_LINES |"
echo "| continuo | $CONT_LINES |"
echo
} > "$OUT"

# --- 1. co-firing matrix: tool pairs within N seconds, per agent ---
# line shape: [ts] agent | tool_call | name=X status=Y result_len=N ...
emit_cofire() {
  local agent="$1"
  TZ=UTC awk -v W=$COFIRE_WINDOW -v AG="$agent" '
    $0 ~ "\\] " AG " \\| tool_call \\| " {
      match($0, /name=[a-z_]+/); tool=substr($0, RSTART+5, RLENGTH-5);
      ts=substr($0, 2, 19); gsub(/[-:]/, " ", ts);
      t=mktime(ts);            # six fields exactly; the "1970 " anchor SHIFTED all fields (mktime takes 6) -- see knowledge/aria/mktime-seven-field-bug-2026-09-09.md
      if (last && t-last <= W && t-last >= 0) print pair_prev"->"tool;
      pair_prev=tool; last=t;
    }' /tmp/connectome/tools.log | sort | uniq -c | sort -rn | head -$TOPN
}
{
echo "## Co-firing (top pairs, ${COFIRE_WINDOW}s window)"
echo
echo "### aria"
echo '```'
emit_cofire aria
echo '```'
echo
echo "### continuo"
echo '```'
emit_cofire continuo
echo '```'
echo
} >> "$OUT"

# --- 2. n-gram motifs: 2-grams and 3-grams per agent ---
emit_ngrams() {
  local agent="$1" n="$2"
  TZ=UTC awk -v AG="$agent" -v N="$n" '
    $0 ~ "\\] " AG " \\| tool_call \\| " {
      match($0, /name=[a-z_]+/); tool=substr($0, RSTART+5, RLENGTH-5);
      k = k % N; hist[k] = tool; k++;
      if (k == N) {
        s = "";
        for (i = 0; i < N; i++) s = s hist[i] (i < N-1 ? "->" : "");
        print s;
      }
    }' /tmp/connectome/tools.log | sort | uniq -c | sort -rn | head -$TOPN
}
{
echo "## N-gram motifs (2-grams, 3-grams)"
echo
for ag in aria continuo; do
  echo "### $ag 2-grams"
  echo '```'; emit_ngrams "$ag" 2; echo '```'
  echo "### $ag 3-grams"
  echo '```'; emit_ngrams "$ag" 3; echo '```'
done
echo
} >> "$OUT"

# --- 3. file-touch graph (write side full history; read side post-0f552b1) ---
{
echo "## File-touch graph (write side; read side only post 2026-09-08)"
echo
echo "### aria writes (top $TOPN)"
echo '```'
grep '] aria | tool_call' /tmp/connectome/tools.log \
  | grep -oE 'name=(write_file|append_file|write_subtask|create_task|git_commit) ' \
  | sort | uniq -c | sort -rn
grep '] aria | tool_call' /tmp/connectome/tools.log \
  | grep -oE '(path|filepath)=[^ ]+' | sort | uniq -c | sort -rn | head -$TOPN
echo '```'
echo
echo "### continuo writes (top $TOPN)"
echo '```'
grep '] continuo | tool_call' /tmp/connectome/tools.log \
  | grep -oE '(path|filepath)=[^ ]+' | sort | uniq -c | sort -rn | head -$TOPN
echo '```'
echo
echo "### load-bearing (touched by BOTH citizens)"
echo '```'
comm -12 <(grep '] aria | tool_call' /tmp/connectome/tools.log | grep -oE '(path|filepath)=[^ ]+' | sort -u) \
         <(grep '] continuo | tool_call' /tmp/connectome/tools.log | grep -oE '(path|filepath)=[^ ]+' | sort -u) | head -$TOPN
echo '```'
echo
} >> "$OUT"

# --- 9. c162 ROTATION-LOSS FIX: cycle.log is the complete REQ record ---
# REQUESTS.log rotates to .1 at 10MB keeping ONE generation (rename
# overwrites the old .1). Chunks rotated out are LOST: verified 09-10
# (c162) -- continuo's 09-09 12:00-18:00 UTC chunk vanished from both
# REQUESTS.log(.1) while cycle.log (never rotated) holds all 32 REQ
# lines of that window. The silence column read the truncated pair and
# reported max_gap_s=27032 -- a ROTATION-LOSS ARTIFACT, not a hang.
# The fire census undercounted the same window (8 vs 12 on 09-09).
# FIX: build the REQ census from cycle.log (complete, unrotated, same
# '] REQ <id> ...' line shape, ANSI-free on REQ lines) when it exists;
# REQUESTS.log(.1) stays the fallback. cycle.log is per-agent (the
# directory IS the partition), so no agent-name anchor needed.
build_req_source() {
  local agent="$1"
  local cyc="$AUDIT_DIR/iar/$agent/cycle.log"
  local f="$AUDIT_DIR/iar/$agent/REQUESTS.log"
  if [ -s "$cyc" ] && grep -aq '] REQ ' "$cyc" 2>/dev/null; then
      grep -aE '^\[2026-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] REQ [0-9]+-[0-9]+ ' "$cyc" > /tmp/connectome/req-$agent.log
      REQ_SRC[$agent]="cycle.log"
  else
      [ -f "$f.1" ] && cat "$f.1" "$f" > /tmp/connectome/req-$agent.log || cp "$f" /tmp/connectome/req-$agent.log
      REQ_SRC[$agent]="REQUESTS.log(.1)"
  fi
}
declare -A REQ_SRC
for ag in aria continuo; do build_req_source "$ag"; done
{
echo "## REQ source note (c162)"
echo
echo "REQ census built from: aria=${REQ_SRC[aria]}, continuo=${REQ_SRC[continuo]}."
echo "REQUESTS.log rotates to .1 keeping ONE generation; chunks rotated out"
echo "are lost (verified 09-10: continuo 09-09 12-18h UTC window absent from"
echo "REQUESTS.log(.1), present in cycle.log). cycle.log is never rotated and"
echo "carries the same '] REQ <id> ...' lines, so it is the primary source"
echo "when present. Silence gaps computed from a rotated-out window are"
echo "ARTIFACTS -- cross-check any gap > 600s against cycle.log before"
echo "claiming a hang."
echo
} >> "$OUT"

# --- 4. token economics from REQUESTS.log (fat-context early warning) ---
# Anchored on '] REQ <id> PARSE ' -- genuine line shape; unanchored
# ' PARSE ' greps count census commands' own specs= echo (c115).
{
echo "## Token economics (REQUESTS.log, per agent)"
echo
for ag in aria continuo; do
  build_req_source "$ag"
  echo "### $ag"
  echo '```'
  grep -E '\] REQ [0-9]+-[0-9]+ PARSE ' /tmp/connectome/req-$ag.log \
    | grep -oE 'tokens_in=[0-9]+' | cut -d= -f2 \
    | sort -n | awk '{a[NR]=$1} END {if(NR>0) printf "n=%d p50=%d p90=%d p99=%d max=%d\n", NR, a[int(NR*0.5)], a[int(NR*0.9)], a[int(NR*0.99)], a[NR]}'
  echo '```'
done
echo
} >> "$OUT"


# --- 6. silence (hang-signal channel; c105/106 hang-witness asymmetry) ---
# REQUESTS.log PARSE lines are the only witness of a hang: requests stop
# arriving during a hang, then resume. Max gap between consecutive PARSE
# timestamps per agent = the silence column. Gaps > 600s (the tool
# timeout ceiling) are hang-class candidates.
# c115 FIX: was anchored on '] <agent> | PARSE | ' -- a shape that does
# not exist in REQUESTS.log (no agent field; the file IS the partition).
# It matched only self-echo and would have reported fiction forever.
emit_silence() {
  local agent="$1"
  TZ=UTC awk '
    $0 ~ "\] REQ [0-9]+-[0-9]+ PARSE " {
      ts=substr($0, 2, 19); gsub(/[-:]/, " ", ts);
      t=mktime(ts);
      if (prev && t-prev > max) { max=t-prev; from=sprev; to=ts }
      if (prev && t-prev > 600) hang++
      prev=t; sprev=ts;
    }
    END {
      if (max > 0) printf "max_gap_s=%d from=%s to=%s gaps_over_600s=%d\n", max, from, to, hang+0;
      else print "no PARSE lines";
    }' /tmp/connectome/req-$agent.log
}
{
echo "## Silence (hang-signal channel, REQUESTS.log PARSE gaps)"
echo
echo "Max gap between consecutive PARSE lines per agent. Gaps > 600s"
echo "(tool-timeout ceiling) are hang-class candidates; cross-check the"
echo "from/to stamps against journalctl rotation logs before claiming a hang."
echo
for ag in aria continuo; do
  echo "### $ag"
  echo '```'
  emit_silence "$ag"
  echo '```'
  echo
done
} >> "$OUT"

# --- 7. fire census (truncated-output fires; c114 methodology, baked) ---
# A fire = a PARSE line whose tail is exactly `error=<X> stop=length
# tokens_in=<N> tokens_out=<M>` at LINE END. Anchoring the TAIL is the
# whole method: census greps that match substrings count their own
# specs= echo (c32 self-inflation; c114's 73-fictional-fires recount).
# stop=length + tokens_out at the 32768 halved cap = generation hit the
# output ceiling mid-turn. Per-agent counts + per-day histogram.
# c115 FIX: no agent-name anchor -- REQUESTS.log lines have no agent
# field; the per-agent file IS the partition (see header).
emit_fires() {
  local agent="$1"
  grep -E 'error=[^ ]+ stop=length tokens_in=[0-9]+ tokens_out=[0-9]+$' /tmp/connectome/req-$agent.log \
    | TZ=UTC awk '
      { ts=substr($0, 2, 10); day[ts]++; n++ }
      END {
        for (d in day) printf "%s: %d\n", d, day[d] | "sort";
        if (n > 0) printf "TOTAL fires: %d\n", n;
        else print "TOTAL fires: 0";
      }'
}
{
echo "## Fire census (truncated-output fires, REQUESTS.log PARSE lines)"
echo
echo "A fire = PARSE line ending exactly with \`error=<X> stop=length"
echo "tokens_in=<N> tokens_out=<M>\` -- tail-anchored so census commands"
echo "never count their own specs= echo (c32/c114). stop=length at the"
echo "32768 halved cap = output ceiling hit mid-turn. Cross-check bursts"
echo "against journalctl before attributing cause (law 26: two data"
echo "points make a line, never a mechanism)."
echo
for ag in aria continuo; do
  echo "### $ag"
  echo '```'
  emit_fires "$ag"
  echo '```'
  echo
done
} >> "$OUT"

# --- 8. fence/rejection counts (post-0f552b1 rows) ---
{
echo "## Fence rejections (status=rejected, post 0f552b1)"
echo '```'
grep -c 'status=rejected' "$MERGED" || true
echo '```'
echo
echo "## Baseline caveat"
echo
echo "FIRST SNAPSHOT = baseline only. No trend claims until snapshot 2."
echo
} >> "$OUT"

echo "snapshot written: $OUT"
echo "population: total=$TOOL_LINES aria=$ARIA_LINES continuo=$CONT_LINES"
