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
#
# Exit 1 = no-BatchMode camera ssh found (the dropbear-burst class).
# BatchMode camera ssh is reported as info (letter-violation of 0071;
# the bootinfo puller is the structural fix that removes the motive).

LOGS=("$@")
if [ ${#LOGS[@]} -eq 0 ]; then
  LOGS=(/root/personalization/audit/iar/aria/cycle.log
        /root/personalization/audit/iar/continuo/cycle.log)
fi

alarm=0
info=0
for log in "${LOGS[@]}"; do
  [ -f "$log" ] || { echo "SKIP (missing): $log"; continue; }
  hits=$(grep -aE '^\[[0-9]{2}:[0-9]{2}:[0-9]{2}\] \(:name "execute_code_local"' "$log" \
    | grep -E 'ssh[^|]*root@192\.168\.2\.[0-9]+' \
    | grep -vE 'grep |sed |awk ' \
    | awk '{k=substr($0,1,120); if (!(k in seen)) {seen[k]=1; print}}')
  [ -z "$hits" ] && continue
  nb=$(echo "$hits" | grep -vc 'BatchMode' || true)
  b=$(echo "$hits" | grep -c 'BatchMode' || true)
  echo "== $log: $((nb+b)) camera-ssh call(s): $nb ALARM (no BatchMode), $b info (BatchMode)"
  if [ "$nb" -gt 0 ]; then
    echo "$hits" | grep -v 'BatchMode' | sed 's/^\(.\{160\}\).*/\1 [...]/' | head -10
  fi
  alarm=$((alarm + nb))
  info=$((info + b))
done

if [ "$alarm" -gt 0 ]; then
  echo "0071-BELT: FAIL -- $alarm no-BatchMode camera ssh call(s) (+$info BatchMode info)"
  exit 1
fi
if [ "$info" -gt 0 ]; then
  echo "0071-BELT: PASS with notes -- $info BatchMode camera ssh call(s) (0071 letter-violations; bootinfo puller removes the motive)"
  exit 0
fi
echo "0071-BELT: clean"
exit 0