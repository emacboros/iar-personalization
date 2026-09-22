#!/bin/bash
# fc1f-belt.sh -- fixture suite for fleet-check block 1f (RECORDER-GAP CENSUS)
# Tests the awk analysis + classification logic in isolation (the walk is
# exercised by the live run). 6 fixtures = the full contract.
set -u
PASS=0; FAILS=0
run_awk() {
  local cam="$1"; local expect_sub="$2"; local desc="$3"; shift 3
  local out
  out=$(printf '%s\n' "$@" | sort -n | awk -v cam="$cam" '
    NR==1 { prev=$1; prevname=$2; next }
    {
      d=$1-prev
      if (d>45) {
        gaps++
        hstart=strftime("%H", prev, 1)
        inr=(hstart+0>=1 && hstart+0<=7)
        if (inr) { rgaps++ }
        else { if (d>longest) { longest=d; ls=prevname; le=$2 } }
        if (d>longestall) { longestall=d; lsa=prevname; lea=$2 }
      }
      prev=$1; prevname=$2
    }
    END {
      gaps+=0; rgaps+=0; longest+=0; longestall+=0
      printf "%s GAP-CENSUS: gaps=%d (reboot-window=%d) longest_nonR=%ds longest_any=%ds (24h, name-only)\n", cam, gaps, rgaps, longest, longestall
      if (longest>300) printf "FAIL-LINE: %s RECORDER-GAP: %ds hole %s->%s outside reboot window -- recording loss (E10 class)\n", cam, longest, ls, le
      else if (longest>0) printf "%s gap-note: longest non-reboot-window hole %ds (%s->%s) -- ledger data, not fail\n", cam, longest, ls, le
    }')
  if echo "$out" | grep -qF "$expect_sub"; then
    PASS=$((PASS+1)); echo "PASS: $desc"
  else
    FAILS=$((FAILS+1)); echo "FAIL: $desc -- expected [$expect_sub], got: $out"
  fi
}
D=$(date -u -d "today 00:00" +%s)  # today's midnight; hours 01-07 = in-R
# T1: healthy contiguous hour -> gaps=0, no FAIL, no note
rows=(); for s in $(seq 0 2 3598); do rows+=("$((D + 7200 + s)) $(printf '%02d.%02d' $((s/60)) $((s%60)))"); done
run_awk ext_1 "gaps=0" "T1 healthy hour: zero gaps" "${rows[@]}"
# T2: in-window gap (542s at 01:58) -> reboot-window=1, no FAIL
rows=(); for s in $(seq 0 2 1258) $(seq 1800 2 3598); do rows+=("$((D + 3600 + s)) $(printf '%02d.%02d' $((s/60)) $((s%60)))"); done
run_awk ext_1 "reboot-window=1" "T2 in-window 542s gap: counted R, no FAIL" "${rows[@]}"
# T3: small non-window gap (242s at 12:58) -> gap-note, no FAIL
rows=(); for s in $(seq 0 2 1858) $(seq 2100 2 3598); do rows+=("$((D + 43200 + s)) $(printf '%02d.%02d' $((s/60)) $((s%60)))"); done
run_awk ext_1 "gap-note: longest non-reboot-window hole 242s (30.58->35.00)" "T3 non-window 242s gap: ledger note" "${rows[@]}"
# T4: large non-window hole (1142s at 12:58) -> FAIL-LINE
rows=(); for s in $(seq 0 2 1258) $(seq 2400 2 3598); do rows+=("$((D + 43200 + s)) $(printf '%02d.%02d' $((s/60)) $((s%60)))"); done
run_awk ext_1 "FAIL-LINE: ext_1 RECORDER-GAP: 1142s hole 20.58->40.00" "T4 non-window 1142s hole: FAIL" "${rows[@]}"
# T5: inter-hour hole (12h absent) -> counted, FAIL if non-R
rows=(); for s in $(seq 0 2 3598); do rows+=("$((D + 43200 + s)) $(printf '%02d.%02d' $((s/60)) $((s%60)))"); done
for s in $(seq 0 2 3598); do rows+=("$((D + 86400 + s)) $(printf '%02d.%02d' $((s/60)) $((s%60)))"); done
run_awk ext_1 "39602s" "T5 12h inter-hour hole: counted, FAIL" "${rows[@]}"
# T6: exactly-at-threshold 301s non-R -> FAIL; 300s -> note (boundary)
rows=(); for s in $(seq 0 2 1798) 1800 $(seq 2100 2 3598); do rows+=("$((D + 43200 + s)) $(printf '%02d.%02d' $((s/60)) $((s%60)))"); done
run_awk ext_1 "gap-note" "T6 300s boundary: note not fail" "${rows[@]}"
echo "== fc1f-belt done: PASS=$PASS FAIL=$FAILS =="
[ "$FAILS" -eq 0 ]
