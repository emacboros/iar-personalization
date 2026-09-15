#!/bin/bash
# commit-census.sh -- census of the personalization git log: churn vs substance
#
# The git log is a repetition detector for failure modes the text census
# misses. Belt commits (1/cycle durability meter) are healthy; tail-chasing
# (commit -> belt grows next turn -> commit again) shows up as a high
# tail-vocabulary fraction and numbered sequences (close 1..31, converge
# 1..9). c338 named the class 2026-09-14; this instrument measures it.
#
# Usage: commit-census.sh [YYYY-MM-DD]
#   with date: per-agent census for that day (UTC commit dates)
#   no date:   all-time totals + per-day table
#
# Classification (on commit subject line):
#   belt     = "belt #2 durability" meter commit (healthy, 1/cycle)
#   tail     = tail/close/final/settle/converge vocabulary EXCLUDING belt
#   numbered = explicit sequence marker: "(close N)", "converge N",
#              "tail N", "(N)" suffix -- the chasing signature
#   other    = everything else (substance)
# churn = tail / (tail + other) among non-belt commits

REPO="${IAR_PERS_REPO:-/root/personalization}"
cd "$REPO" || exit 2

DAY="$1"

classify() {
    # reads "date|author|subject" lines on stdin, prints per-agent tallies
    awk -F'|' -v day="$DAY" '
    function bump(a, k, v) { a[k] += v }
    {
        d = $1; agent = $2; subj = $3
        if (day != "" && d != day) next
        tot[agent]++
        if (subj ~ /belt #2 durability/) { belt[agent]++; next }
        isnum = (subj ~ /\((close|converge|belt tail|tail) [0-9]+\)/ ||
                 subj ~ / (close|converge|belt tail|tail) [0-9]+\)/ ||
                 subj ~ /\(close [0-9]+\)/ ||
                 subj ~ /converge [0-9]+/ ||
                 subj ~ /belt tail [0-9]+/)
        if (isnum) { num[agent]++; tail[agent]++; next }
        if (tolower(subj) ~ /tail|close|final|settle|converge|belt/) {
            tail[agent]++; next
        }
        other[agent]++
    }
    END {
        for (a in tot) {
            nonbelt = tot[a] - belt[a]
            churn = (nonbelt > 0) ? tail[a] / nonbelt * 100 : 0
            printf "%s total=%d belt=%d tail=%d numbered=%d other=%d churn=%.0f%%\n",
                   a, tot[a], belt[a], tail[a], num[a], other[a], churn
        }
    }'
}

if [ -n "$DAY" ]; then
    echo "== commit-census $DAY (UTC) =="
    git log --all --date=format:"%Y-%m-%d" --format="%ad|%an|%s" | classify
else
    echo "== commit-census all-time (UTC) =="
    git log --all --date=format:"%Y-%m-%d" --format="%ad|%an|%s" | classify
    echo
    echo "== per-day (both agents, UTC) =="
    git log --all --date=format:"%Y-%m-%d" --format="%ad" | sort | uniq -c |
        awk '{printf "%s %s\n", $2, $1}'
fi