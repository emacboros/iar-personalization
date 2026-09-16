#!/bin/bash
# aria-batched-probe.sh v1.1 (2026-09-16, aria cycle 378)
# -------------------------------------------------------------
# ONE ssh connection, MANY probes, ONE output block.
#
# WHY (c376->c377->c378): the ssh-per-question pattern drove 150+
# execute_code_local calls per cycle for three consecutive cycles;
# the loop guard fired twice in c377. Investigations must be WRITTEN
# (a probe file) then RUN (one tool call), not typed question by
# question. This script is the run half. The write half is
# write_file into probes/<name>.probe.
#
# USAGE:
#   batched-probe.sh <probe-file-path>
#   batched-probe.sh <name>          # -> probes/<name>.probe
#   batched-probe.sh probes/<name>.probe
#
# PROBE FILE FORMAT:
#   ### <section label>
#   <shell command to run on sophon, one per line>
#   Lines starting with "### " are section banners. All other
#   non-empty lines are commands, each run as:
#       timeout 25 bash -c '<command>'
#   One command per line; compound logic goes in && chains or
#   for-loops on a single line. Probe files are read-only by
#   convention -- they run as root on sophon, so write nothing
#   you cannot undo.
#
# v1.1 fix (c378, first real run): the probe banner used
#   echo "--- probe: %s"
# which breaks when the probe line itself contains double quotes
# (SQL). Now the label is %q-escaped as a separate argument.
#
# OUTPUT: section banners, per-probe "rc=" lines, and a footer with
# elapsed time. A hung probe dies at its own 25s timeout, not the
# 600s tool kill.
#
# CONNECTION: ControlMaster socket in /tmp (fresh per container
# boot, like the known_hosts reseed). Later batched-probe or
# plain ssh calls within ControlPersist reuse the TCP connection.
# -------------------------------------------------------------
set -u

HOST=10.66.0.5
KEY=/root/.ssh/id_ed25519
KH=/tmp/aria_known_hosts
BINDIR=/root/personalization/knowledge/aria/bin

if [ ! -s "$KH" ]; then
  ssh-keyscan -T 5 "$HOST" > "$KH" 2>/dev/null
fi

SSH_OPTS="-i $KEY -o UserKnownHostsFile=$KH -o StrictHostKeyChecking=accept-new -o ControlMaster=auto -o ControlPath=/tmp/aria-ssh-cm-%r@%h:%p -o ControlPersist=300 -o ConnectTimeout=8 -o BatchMode=yes"

[ $# -ge 1 ] || { echo "usage: batched-probe.sh <probe-file|name>" >&2; exit 2; }
PF="$1"
case "$PF" in
  probes/*) PF="$BINDIR/$PF" ;;
  */) PF="$BINDIR/probes/$PF" ;;
  /*) : ;;
  *) PF="$BINDIR/probes/$PF.probe" ;;
esac
[ -f "$PF" ] || { echo "probe file not found: $PF" >&2; exit 2; }

TMP=$(mktemp /tmp/aria-probe.XXXXXX.sh)
trap 'rm -f "$TMP"' EXIT

# Build the remote script from the probe file.
{
  echo 'set +e'
  while IFS= read -r line; do
    case "$line" in
      '###'*)
        label="${line#"### "}"
        printf 'echo; echo "===== %s ====="\n' "$label"
        ;;
      *)
        [ -z "$line" ] && continue
        printf 'echo "--- probe:" %q\n' "$line"
        printf 'timeout 25 bash -c %q\n' "$line"
        printf 'echo "[rc=$?]"\n'
        ;;
    esac
  done < "$PF"
} > "$TMP"

T0=$(date +%s)
echo "### batched-probe: $PF at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
ssh $SSH_OPTS root@"$HOST" 'bash -s' < "$TMP" 2>&1
RC=$?
T1=$(date +%s)
echo "### batched-probe done: ssh-rc=$RC elapsed=$((T1-T0))s"
exit $RC