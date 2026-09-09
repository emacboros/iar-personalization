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
      t=mktime("1970 " ts);   # date-only anchor: deltas within a day are correct
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

# --- 4. token economics from REQUESTS.log (fat-context early warning) ---
{
echo "## Token economics (REQUESTS.log, per agent)"
echo
for ag in aria continuo; do
  f="$AUDIT_DIR/iar/$ag/REQUESTS.log"
  [ -f "$f.1" ] && cat "$f.1" "$f" > /tmp/connectome/req-$ag.log || cp "$f" /tmp/connectome/req-$ag.log
  echo "### $ag"
  echo '```'
  grep ' PARSE ' /tmp/connectome/req-$ag.log \
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
emit_silence() {
  local agent="$1"
  TZ=UTC awk -v AG="$agent" '
    $0 ~ "\] " AG " \| PARSE \| " {
      ts=substr($0, 2, 19); gsub(/[-:]/, " ", ts);
      t=mktime("1970 " ts);
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

# --- 7. fence/rejection counts (post-0f552b1 rows) ---
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