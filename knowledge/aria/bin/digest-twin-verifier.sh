#!/bin/bash
# digest-twin-verifier v1.0 (2026-09-06, continuo cycle 66)
# ---------------------------------------------------------
# Digest twin verifier. Runs from the i.ar container (which IS the
# sophon iar-personalization checkout via bind mount -- inode-identical).
# Spec: knowledge/iar/digest-twin-census-2026-09-06.md (corrected c66).
#
# Live is defined by the READER: iar--read-memory-file-full reads
#   <pers>/audit/iar/<personality>/DIGEST.md  (per-personality audit path)
# The top-level <pers>/DIGEST.md is NOT read by injection -- it is a
# SYNC COPY of aria's digest (her memory pass). i.ar-repo copies are
# FOSSILS (pre-Step5 migration), marker-marked (line 155, 52142bf).
#
# ALERT (exit 1 + lab-notes message) ONLY when a NON-fossil copy
# diverges from the per-personality live path. i.ar fossil divergence
# is expected and ignorable (marker checked first).
#
# CALLER: run at cycle wake, batched into the pulse ssh (one call).
# Local paths (container = sophon checkout) + one ssh for the sophon
# i.ar checkout.

PERS=/root/personalization
IAR_LOCAL=/root/i.ar
KNOWN_HOSTS=/tmp/continuo_known_hosts
SOPHON=root@10.66.0.5
IAR_SOPHON=/var/home/nacho/repos/i.ar

FAIL=0
ALERT_MSG=""

# --- md5 helper: returns "" on missing file ---
md5of() { [ -f "$1" ] && md5sum "$1" | awk '{print $1}' || echo ""; }

# --- fossil-marker check: 1 if marked, 0 if not ---
is_fossil() { grep -q "FOSSIL NOTE" "$1" 2>/dev/null && echo 1 || echo 0; }

echo "== digest twin verifier =="

for P in aria continuo; do
  live=$(md5of "$PERS/audit/iar/$P/DIGEST.md")
  echo "-- $P live (audit path): ${live:-MISSING}"
  if [ -z "$live" ]; then
    echo "ALERT: $P live DIGEST.md MISSING"
    FAIL=1
    continue
  fi

  # top-level sync copy (aria's mirror; continuo has none -- skip)
  if [ "$P" = "aria" ]; then
    top=$(md5of "$PERS/DIGEST.md")
    if [ -z "$top" ]; then
      echo "ALERT: aria top-level DIGEST.md MISSING"
      FAIL=1
    elif [ "$top" != "$live" ]; then
      echo "ALERT: aria top-level DIGEST.md DIVERGED from live ($top != $live)"
      FAIL=1
    else
      echo "  top-level sync copy: MATCH ($top)"
    fi
  fi

  # i.ar-repo copies (container + sophon checkout) -- fossil-check first
  for pair in "local:$IAR_LOCAL/audit/iar/$P/DIGEST.md" "sophon:$IAR_SOPHON/audit/iar/$P/DIGEST.md"; do
    loc=${pair%%:*}; path=${pair#*:}
    if [ "$loc" = "local" ]; then
      m=$(md5of "$path"); f=$(is_fossil "$path")
    else
      # ssh for the sophon i.ar checkout
      out=$(ssh -o UserKnownHostsFile=$KNOWN_HOSTS -o ConnectTimeout=8 $SOPHON \
        "if [ -f '$path' ]; then echo \"\$(md5sum '$path' | awk '{print \$1}') \$(grep -q 'FOSSIL NOTE' '$path' && echo 1 || echo 0)\"; else echo 'MISSING 0'; fi" 2>/dev/null)
      m=${out%% *}; f=${out##* }
    fi
    if [ -z "$m" ] || [ "$m" = "MISSING" ]; then
      echo "  i.ar $loc copy: MISSING"
      continue
    fi
    if [ "$f" = "1" ]; then
      echo "  i.ar $loc copy: FOSSIL (ignored, $m)"
    elif [ "$m" != "$live" ]; then
      echo "ALERT: i.ar $loc copy UNMARKED and DIVERGED ($m != $live)"
      FAIL=1
    else
      echo "  i.ar $loc copy: unmarked, MATCH ($m)"
    fi
  done
done

echo "== digest-twin-verifier done (FAIL=$FAIL) =="
exit $FAIL
