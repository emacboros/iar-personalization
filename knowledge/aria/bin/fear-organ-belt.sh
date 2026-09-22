#!/bin/bash
# fear-organ-belt.sh -- belt suite for fear-organ.sh v2.3+ (c204, 2026-09-22)
# 26 fixtures covering: age-aware FAIL sev (v2.3 core), CENSUS-CONTRA
# (audio+video fields, fresh/stale/dead census), voice-class sev=3,
# stash-unpopped, cycle-failed, missing fleet, 27h fleet-stale,
# emit-on-delta, stale<->fresh transitions, flap sequence.
# Run: bash fear-organ-belt.sh [path-to-fear-organ.sh]
# Exit 0 = all pass, 1 = any fail.
set -u
ORGAN="${1:-$(dirname "$0")/fear-organ.sh}"
BELTDIR=$(mktemp -d /tmp/fear-belt.XXXXXX)
PASS=0; FAIL=0

mkfix() {
  local name=$1; local dir="$BELTDIR/$name"
  mkdir -p "$dir/affect" "$dir/ch2census" "$dir/audit/iar/aria" "$dir/audit/iar/continuo"
  (cd "$dir" && git init -q .)
  for a in aria continuo; do
    printf 'status: ok\nexit: 0\nagent: %s\nended: %s UTC\n' "$a" "$(date -u '+%Y-%m-%d %H:%M:%S')" > "$dir/audit/iar/$a/LAST-CYCLE.txt"
  done
  echo "$dir"
}

run() {
  local dir=$1; local expect=$2; local desc=$3
  local out
  out=$(ARIA_ORGAN_TEST=1 bash "$ORGAN" "$dir/fleet-latest" "$dir" 2>/dev/null | head -1)
  if echo "$out" | grep -q "sev=$expect"; then
    PASS=$((PASS+1)); echo "PASS: $desc (sev=$expect)"
  else
    FAIL=$((FAIL+1)); echo "FAIL: $desc (expected sev=$expect, got: $out)"
  fi
}

NOWEPOCH=$(date -u +%s)
OLD=$((NOWEPOCH - 10740))  # 179 minutes ago

# T1: c202 replay -- stale snapshot + FAIL + fresh census = sev=1 + annotations
d=$(mkfix t1)
cat > "$d/fleet-latest" <<EOF
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL-LINE: exterior_4 RECORDER-AUDIO-EVENTS: 3 stall-class event(s) in 24h (>2)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
echo "$((NOWEPOCH - 120)) exterior_3 220 70 1" > "$d/ch2census/exterior_3.log"
echo "$((NOWEPOCH - 120)) exterior_4 373 182 1" > "$d/ch2census/exterior_4.log"
run "$d" 1 "stale 179m FAIL + fresh census = sev1 + stale-annotation"
grep -q "fleet-FAIL-stale(179m" "$d/affect/fear.log" && { PASS=$((PASS+1)); echo "PASS: stale annotation present"; } || { FAIL=$((FAIL+1)); echo "FAIL: stale annotation missing"; }
grep -q "CENSUS-CONTRA:exterior_3(aframes=220,vframes=70" "$d/affect/fear.log" && { PASS=$((PASS+1)); echo "PASS: contra labels both fields"; } || { FAIL=$((FAIL+1)); echo "FAIL: contra label wrong"; }

# T2: fresh snapshot + FAIL = sev=2, no stale annotation
d=$(mkfix t2)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
run "$d" 2 "fresh FAIL = sev2"
grep -q "fleet-FAIL-stale" "$d/affect/fear.log" && { FAIL=$((FAIL+1)); echo "FAIL: stale annotation on fresh snapshot"; } || { PASS=$((PASS+1)); echo "PASS: no stale annotation on fresh"; }

# T3: stale snapshot + stale census = sev=1, no contra
d=$(mkfix t3)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
echo "$((NOWEPOCH - 3600)) exterior_3 0 0 1" > "$d/ch2census/exterior_3.log"
run "$d" 1 "stale FAIL + stale census = sev1 no contra"
grep -q "CENSUS-CONTRA" "$d/affect/fear.log" && { FAIL=$((FAIL+1)); echo "FAIL: contra on stale census"; } || { PASS=$((PASS+1)); echo "PASS: no contra on stale census"; }

# T4: stale + video-only fresh census = contra with vframes label
d=$(mkfix t4)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
echo "$((NOWEPOCH - 120)) exterior_3 0 182 1" > "$d/ch2census/exterior_3.log"
run "$d" 1 "stale + video-only census = sev1 + contra"
grep -q "CENSUS-CONTRA:exterior_3(aframes=0,vframes=182" "$d/affect/fear.log" && { PASS=$((PASS+1)); echo "PASS: video-only contra labeled"; } || { FAIL=$((FAIL+1)); echo "FAIL: video-only contra missing"; }

# T5: fresh + video-only census = sev2 + contra
d=$(mkfix t5)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
echo "$((NOWEPOCH - 120)) exterior_3 0 182 1" > "$d/ch2census/exterior_3.log"
run "$d" 2 "fresh + video-only census = sev2 + contra"
grep -qc "CENSUS-CONTRA" "$d/affect/fear.log" && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: contra missing"; }

# T6: fresh + audio-only census = sev2 + contra
d=$(mkfix t6)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
echo "$((NOWEPOCH - 120)) exterior_3 220 0 1" > "$d/ch2census/exterior_3.log"
run "$d" 2 "fresh + audio-only census = sev2 + contra"
grep -qc "CENSUS-CONTRA" "$d/affect/fear.log" && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: contra missing"; }

# T7: fresh + dead census (0/0) = sev2, no contra
d=$(mkfix t7)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
echo "$((NOWEPOCH - 120)) exterior_3 0 0 1" > "$d/ch2census/exterior_3.log"
run "$d" 2 "fresh + dead census = sev2 no contra"
grep -qc "CENSUS-CONTRA" "$d/affect/fear.log" && { FAIL=$((FAIL+1)); echo "FAIL: contra on dead census"; } || PASS=$((PASS+1))

# T8: voice class fresh = sev3
d=$(mkfix t8)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: agora authed GET: TIMEOUT
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
run "$d" 3 "voice class fresh = sev3"

# T9: voice class stale = sev3 + stale annotation survives
d=$(mkfix t9)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: agora authed GET: TIMEOUT
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
run "$d" 3 "voice class stale = sev3 (class wins)"
grep -q "fleet-FAIL-stale" "$d/affect/fear.log" && { PASS=$((PASS+1)); echo "PASS: stale annotation survives sev3"; } || { FAIL=$((FAIL+1)); echo "FAIL: stale annotation lost in sev3"; }

# T10: stale FAIL + failed cycle = sev2 (cycle-failed raises)
d=$(mkfix t10)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
printf 'status: failed\nexit: 2\nagent: aria\nended: %s UTC\n' "$(date -u '+%Y-%m-%d %H:%M:%S')" > "$d/audit/iar/aria/LAST-CYCLE.txt"
run "$d" 2 "stale FAIL + cycle-failed = sev2 (cycle signal raises)"

# T11: stale FAIL + stash = sev2 (stash raises)
d=$(mkfix t11)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
(cd "$d" && echo dirty > dirtyfile && git add dirtyfile && git commit -qm dirty && echo x >> dirtyfile && git stash -q)
run "$d" 2 "stale FAIL + stash = sev2 (stash signal raises)"

# T12: stale FAIL only (no other signal) = sev1 -- THE c202 SCENARIO
d=$(mkfix t12)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
run "$d" 1 "stale FAIL alone = sev1 (c202 scenario, v2.3 core)"

# T13: clean fleet = sev0
d=$(mkfix t13)
cat > "$d/fleet-latest" <<'EOF'
-- git bare health --
bare ownership ok (0 root-owned)
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
run "$d" 0 "clean fleet = sev0"

# T14: missing fleet file = sev0 (no fleet input)
d=$(mkfix t14)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
rm "$d/fleet-latest"
run "$d" 0 "missing fleet = sev0 (no fleet input)"

# T15: 27h-old clean fleet = fleet-stale sev1
d=$(mkfix t15)
cat > "$d/fleet-latest" <<'EOF'
-- git bare health --
bare ownership ok (0 root-owned)
EOF
touch -d @$((NOWEPOCH - 97200)) "$d/fleet-latest"
run "$d" 1 "27h-old clean fleet = sev1 fleet-stale"
grep -q "fleet-stale(27h)" "$d/affect/fear.log" && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: fleet-stale annotation missing"; }

# T16: emit-on-delta -- same state twice = no new log line
d=$(mkfix t16)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
[ "$(wc -l < "$d/affect/fear.log")" -eq 1 ] && { PASS=$((PASS+1)); echo "PASS: emit-on-delta (no dup line)"; } || { FAIL=$((FAIL+1)); echo "FAIL: duplicate log line"; }

# T17: stale->fresh transition emits sev1 then sev2
d=$(mkfix t17)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
touch -d @$NOWEPOCH "$d/fleet-latest"
out=$(ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" 2>/dev/null | head -1)
echo "$out" | grep -q "sev=2 delta=up" && { PASS=$((PASS+1)); echo "PASS: stale->fresh = sev2 up"; } || { FAIL=$((FAIL+1)); echo "FAIL: stale->fresh transition: $out"; }
[ "$(wc -l < "$d/affect/fear.log")" -eq 2 ] && { PASS=$((PASS+1)); echo "PASS: both transitions logged"; } || { FAIL=$((FAIL+1)); echo "FAIL: transition lines: $(wc -l < "$d/affect/fear.log")"; }

# T18: fresh->stale transition = sev1 down
d=$(mkfix t18)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
touch -d @$OLD "$d/fleet-latest"
out=$(ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" 2>/dev/null | head -1)
echo "$out" | grep -q "sev=1 delta=down" && { PASS=$((PASS+1)); echo "PASS: fresh->stale = sev1 down"; } || { FAIL=$((FAIL+1)); echo "FAIL: fresh->stale: $out"; }

# T19: flap sequence stale->fresh->stale->fresh = 4 log lines
d=$(mkfix t19)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$OLD "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
touch -d @$NOWEPOCH "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
touch -d @$OLD "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
touch -d @$NOWEPOCH "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
[ "$(wc -l < "$d/affect/fear.log")" -eq 4 ] && { PASS=$((PASS+1)); echo "PASS: flap sequence = 4 emissions"; } || { FAIL=$((FAIL+1)); echo "FAIL: flap lines: $(wc -l < "$d/affect/fear.log")"; }

# T20: fresh FAIL + LAST-CYCLE refresh = sev2 flat, no new line
d=$(mkfix t20)
cat > "$d/fleet-latest" <<'EOF'
FAIL-LINE: exterior_3 age=30s NO-AUDIO (3/3 segments dead)
FAIL=1
EOF
touch -d @$NOWEPOCH "$d/fleet-latest"
ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" >/dev/null 2>&1
printf 'status: ok\nexit: 0\nagent: aria\nended: %s UTC\n' "$(date -u '+%Y-%m-%d %H:%M:%S')" > "$d/audit/iar/aria/LAST-CYCLE.txt"
out=$(ARIA_ORGAN_TEST=1 bash "$ORGAN" "$d/fleet-latest" "$d" 2>/dev/null | head -1)
echo "$out" | grep -q "sev=2 delta=flat" && { PASS=$((PASS+1)); echo "PASS: heartbeat refresh = flat"; } || { FAIL=$((FAIL+1)); echo "FAIL: heartbeat refresh: $out"; }

echo ""
echo "=== belt suite: $PASS pass, $FAIL fail ==="
rm -rf "$BELTDIR"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1