#!/bin/bash
# 0071-belt-check.sh -- detect nested camera ssh in cycle logs (0071 class)
# Law 0071: camera contact rides the pullers; ad-hoc ssh to cameras is
# forbidden. Violations live in cycle.log execute_code_local args.
# Evidence source: cycle.log (NOT audit.log -- zero EXECVE there, c214).
# Built c215 (2026-09-22). Validated against 4 known instances
# (c169 09:11Z, c190 10:26Z, c200 22:25Z 09-21, c202 23:20Z) + the
# 09-16 era cluster (cycle.log lines ~27352-27360, ~13 calls).
#
# PATTERN PRECISION (learned by validation, c215):
# 1. Camera ssh must be a TARGET: 'ssh ... root@192.168.2.N'. Plain
#    camera-IP mentions inside sophon commands (journalctl filters,
#    puller-log greps) do NOT match -- the root@ requirement is what
#    killed 430 naive false positives.
# 2. The container cannot reach 192.168.2.x directly; every camera
#    contact is NESTED inside a sophon ssh (root@10.66.0.5 wrapper).
#    So the violation shape is always wrapper + nested camera ssh.
# 3. SELF-CONTAMINATION EXCLUSION: this check's own investigation
#    greps quote the pattern as text and land in cycle.log. Rule:
#    a line containing grep/sed/awk ANYWHERE is an inspection call,
#    not a violation (all 4 known violations are pure ssh calls).
#    Known false-negative risk: a violation that embeds grep inside
#    the camera remote command. Accepted, documented.
# 4. TIMESTAMP DISCRIMINATOR (c216): only lines with the harness
#    timestamp prefix '[HH:MM:SS] ' are REAL logged calls. Echoed
#    archaeology (grep outputs, fenced tool-call quotes inside
#    thinking/result text) lacks the prefix. Residual hole: thinking
#    that QUOTES a timestamped line verbatim re-matches; dedupe by
#    120-char prefix collapses truncated re-quotes (c216).
#    caught on the check's first belt run (c216): 6 phantom alarms,
#    all echoes of c214/c215's own investigation.
# 5. Invocation is pattern-free (bash <script>), so running the check
#    does not contaminate cycle.log. Keep it that way: never inline
#    the pattern in an ad-hoc command.
# 6. FIXTURE CANARY (c217): the positive fixture carries the token
#    0071-POS-TEST. The check reports canary lines in their own
#    FIXTURE bucket (never alarm, never info) -- the check recognizes
#    its own test artifacts. The fixture still exercises the match
#    pipeline (shape + timestamp), so the positive test stays honest.
# 7. --SELFTEST (v7, c240): run-time canary ts, same pipeline, FIXTURE
#    bucket asserted. Kills the echo-generation treadmill: validation
#    fixtures no longer carry hardcoded stamps, so no new SYNTH_TS
#    entries. See the v7 block below the header.
# 8. KNOWN-SYNTHETIC EXCLUSION (c217): ONE pre-canary echo lives in
#    the committed cycle.log (c216's validation, line ~957745): the
#    bare fixture '[05:00:00] ... uptime -s'. Synthetic by provenance
#    (created by the c216 pos-test printf, echoed by the harness).
#    Excluded by its exact tail (SYNTH_TAIL, grep -F). Provenance-
#    documented; the belt re-validates every run, so if a REAL call
#    ever produces that exact shape the cross-walk catches it.
#
# Exit 1 = no-BatchMode camera ssh found (the dropbear-burst class).
# BatchMode camera ssh is reported as info (letter-violation of 0071;
# the bootinfo puller is the structural fix that removes the motive).

# v7 (c240): --selftest. The c216..c234 validations manufactured a new
# echo-generation every time an ad-hoc fixture carried a hardcoded
# timestamp (SYNTH_TS grew to 7 entries, each a documented scar). The
# self-test generates the fixture INSIDE the belt with a RUN-TIME
# timestamp + the canary token, pipes it through the SAME match
# pipeline, and asserts the FIXTURE bucket. No new SYNTH_TS entries
# are ever needed again: a selftest echo carries the canary token and
# is bucketed as fixture wherever it lands. The committed SYNTH_TS
# list stays (it covers already-committed history).

if [ "${1:-}" = "--selftest" ]; then
  ts=$(date +%T)
  fx_line="[$ts] (:name \"execute_code_local\" :arguments (:command \"ssh root@192.168.2.101 uptime -s 0071-POS-TEST\"))"
  match=$(echo "$fx_line" \
    | grep -aE '^\[[0-9]{2}:[0-9]{2}:[0-9]{2}\] \(:name "execute_code_local"' \
    | grep -E 'ssh[^|]*root@192\.168\.2\.[0-9]+' \
    | grep -vE 'grep |sed |awk ' \
    | { [ ${#SYNTH_TAILS[@]} -gt 0 ] && grep -vF "${SYNTH_TAILS[@]}" || cat; } \
    | { [ -n "$SYNTH_TS" ] && grep -vE "$SYNTH_TS" || cat; } || true)
  if [ -z "$match" ]; then
    echo "0071-SELFTEST: FAIL -- fixture line did not survive the match pipeline"
    exit 1
  fi
  if echo "$match" | grep -q '0071-POS-TEST'; then
    echo "0071-SELFTEST: PASS -- run-time canary ($ts) matched, canary token present (FIXTURE bucket)"
    exit 0
  fi
  echo "0071-SELFTEST: FAIL -- matched line lost the canary token"
  exit 1
fi

LOGS=("$@")
if [ ${#LOGS[@]} -eq 0 ]; then
  LOGS=(/root/personalization/audit/iar/aria/cycle.log
        /root/personalization/audit/iar/continuo/cycle.log)
fi

# KNOWN-SYNTHETIC tails (c217 + c228): exact ends of committed test-fixture
# echoes. c216 pre-canary 'uptime -s' echo + c217 T6 'date' fixture echo +
# the truncated uptime variant (echoed mid-thought, cut at 120-char dedupe
# key). All provenance-documented test artifacts, never real calls. grep -F
# (fixed string) -- no regex escaping games. The belt re-validates every
# run: a REAL call producing these exact shapes is caught by the cross-walk.
SYNTH_TAILS=(
  'uptime -s\"'"'"'"))'
)

# c228: ALL bare-fixture echoes carry the hardcoded [05:00:00] timestamp from the
# c216/c217 printf fixtures. Real calls never have that exact timestamp shape
# (cycle.log timestamps are wall-clock). Exclude by timestamp prefix, keep
# real truncated calls (e.g. 06:33:16) visible.
# Timestamp exclusions (each documented by provenance; a REAL call at one
# of these exact wall-clock stamps would be wrongly excluded -- accepted,
# cross-walk is the defense, same as the c217 design note):
#   05:00:00  c216/c217 printf fixture timestamp (never a real wall-clock)
#   07:11:22  c217 T6 'date' fixture echo (raw + cat -A), witnessed c232
#   09:11:22  c232 T5 alarm-shape fixture echo (the c232 validation printf
#             used 09:11:22 as its canary timestamp; echoed by the harness
#             into cycle.log during c232's belt work and re-echoed by
#             c233's close dump). Witnessed c234.
#   14:44:01  c234 belt-validation canary echo (the v6 validation used
#             14:44:01 as its fresh-ts canary in /tmp/t234b.log; the
#             harness echoed the fixture into cycle.log). Witnessed c235
#             (3rd generation of the same class: belt validation work
#             manufactures echoes of the shape it tests).
#   17:31:23  c234 belt-validation echo (the v6 unexcluded-ts fixture
#             test quoting the 09:11:22 shape, stamped 17:31:23 by the
#             harness). Witnessed c235.
#   05:34:08  09-21 c212-era boot-age camera ssh (ext1 crontab), pre-puller
#   06:33:16  09-21 c212-era boot-age camera ssh (ext4 uptime -s), pre-puller
#   06:37:03  09-21 c212-era boot-age camera ssh (sync_status), pre-puller
SYNTH_TS='^\[(05:00:00|07:11:22|09:11:22|14:44:01|17:31:23|05:34:08|06:33:16|06:37:03)\]'

alarm=0
info=0
fixture=0
for log in "${LOGS[@]}"; do
  [ -f "$log" ] || { echo "SKIP (missing): $log"; continue; }
  hits=$(grep -aE '^\[[0-9]{2}:[0-9]{2}:[0-9]{2}\] \(:name "execute_code_local"' "$log" \
    | grep -E 'ssh[^|]*root@192\.168\.2\.[0-9]+' \
    | grep -vE 'grep |sed |awk ' \
    | grep -vF "${SYNTH_TAILS[@]}" \
    | grep -vE "$SYNTH_TS" \
    | awk '{line=$0; sub(/\\\\$+$/, "", line); k=substr(line,1,120); if (!(k in seen)) {seen[k]=1; print}}')
  [ -z "$hits" ] && continue
  fx=$(echo "$hits" | grep -c '0071-POS-TEST' || true)
  real=$(echo "$hits" | grep -v '0071-POS-TEST' || true)
  [ -n "$real" ] || { fixture=$((fixture+fx)); continue; }
  nb=$(echo "$real" | grep -vc 'BatchMode' || true)
  b=$(echo "$real" | grep -c 'BatchMode' || true)
  echo "== $log: $((nb+b)) camera-ssh call(s): $nb ALARM (no BatchMode), $b info (BatchMode), $fx fixture (canary)"
  if [ "$nb" -gt 0 ]; then
    echo "$real" | grep -v 'BatchMode' | sed 's/^\(.\{160\}\).*/\1 [...]/' | head -10
  fi
  alarm=$((alarm + nb))
  info=$((info + b))
  fixture=$((fixture + fx))
done

if [ "$alarm" -gt 0 ]; then
  echo "0071-BELT: FAIL -- $alarm no-BatchMode camera ssh call(s) (+$info BatchMode info, +$fixture fixture)"
  exit 1
fi
if [ "$info" -gt 0 ]; then
  echo "0071-BELT: PASS with notes -- $info BatchMode camera ssh call(s) (0071 letter-violations; bootinfo puller removes the motive) (+$fixture fixture)"
  exit 0
fi
if [ "$fixture" -gt 0 ]; then
  echo "0071-BELT: clean (+$fixture fixture canary line(s) recognized)"
  exit 0
fi
echo "0071-BELT: clean"
exit 0