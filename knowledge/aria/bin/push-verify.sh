#!/usr/bin/env bash
# push-verify.sh -- verify that pushes actually landed.
#
# Why: the push path has failed SILENTLY three times in this house
# (0034 runuser-as-nacho, git@ authorized_keys gap, c228 force-move
# stranding 24 i.ar commits for a day). A push that returns success
# is not a push that landed. This script checks every hop it can
# reach:
#
#   local HEAD  ==  origin main (ls-remote)          [always]
#   local HEAD  ==  sophon bare main (ssh)           [when applicable]
#
# Sophon hop applicability:
#   - origin points at sophon (10.66.0.5): sophon IS the primary;
#     missing bare repo = FAIL.
#   - a bare repo of the same name exists on sophon: it is a mirror
#     target in the push chain (i.ar: checkout -> rammstein, sophon
#     bare mirrors out); verify it matches. Missing = SKIP.
#   - otherwise (e.g. scratch test repos): SKIP.
#
# Usage: push-verify.sh [repo-dir]...
#   default repos: /root/i.ar /root/personalization
# Exit 0 iff every repo verifies on every applicable hop. One line
# per repo. The line shows the accumulated status -- a FAIL from an
# earlier hop is never relabeled by a later skip.
set -u

KH=/tmp/aria_known_hosts
SOPHON=root@10.66.0.5
SSH_CMD=(timeout 15 ssh -i /root/.ssh/id_ed25519
         -o UserKnownHostsFile=$KH -o StrictHostKeyChecking=no
         -o ConnectTimeout=10 -o BatchMode=yes)

repos=("$@")
[ ${#repos[@]} -eq 0 ] && repos=(/root/i.ar /root/personalization)

fail=0
for repo in "${repos[@]}"; do
  name=$(basename "$repo")
  if [ ! -d "$repo/.git" ]; then
    echo "SKIP $name ($repo not a git repo)"; continue
  fi

  local_head=$(git -C "$repo" rev-parse HEAD 2>/dev/null)
  if [ -z "$local_head" ]; then
    echo "FAIL $name: no local HEAD"; fail=1; continue
  fi

  origin_url=$(git -C "$repo" remote get-url origin 2>/dev/null)
  origin_main=$(git -C "$repo" ls-remote origin refs/heads/main 2>/dev/null | cut -f1)

  status=OK
  [ -z "$origin_main" ] && { status=FAIL; fail=1; }
  [ "$origin_main" != "$local_head" ] && { status=FAIL; fail=1; }

  # Sophon hop: primary when origin is sophon; mirror-check when the
  # bare repo merely exists there.
  bare_main=""
  base=$(basename "${origin_url##*:}"); base=${base##*/}
  case "$base" in *.git) bare_name="$base" ;; *) bare_name="$base.git" ;; esac
  origin_is_sophon=0
  [[ "$origin_url" == *10.66.0.5* ]] && origin_is_sophon=1

  bare_main=$("${SSH_CMD[@]}" "$SOPHON" \
    "if [ -d /home/git/repos/$bare_name ]; then git -C /home/git/repos/$bare_name rev-parse main 2>/dev/null; else echo MISSING; fi" \
    2>/dev/null)

  if [ "$bare_main" = "MISSING" ]; then
    if [ "$origin_is_sophon" = 1 ]; then
      echo "FAIL $name: sophon bare /home/git/repos/$bare_name missing (origin is sophon)"; fail=1; continue
    fi
    echo "$status $name local=${local_head:0:12} origin=${origin_main:0:12} sophon-bare=skip"
    continue
  fi
  if [ -z "$bare_main" ]; then
    echo "FAIL $name: sophon ssh query failed"; fail=1; continue
  fi
  [ "$bare_main" != "$local_head" ] && { status=FAIL; fail=1; }

  echo "$status $name local=${local_head:0:12} origin=${origin_main:0:12} sophon-bare=${bare_main:0:12}"
done

exit $fail