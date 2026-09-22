#!/usr/bin/env python3
"""Continuo claim belt -- pair commit messages against diffs (c235).
Class: comment-only deletions claimed as fixes; empty diffs; huge diffs.
Usage: continuo-claim-belt.py <repo> [since]
Exit 0 always; prints a table. ALARM lines for suspicious shapes.
"""
import subprocess, sys, re

repo = sys.argv[1] if len(sys.argv) > 1 else "/root/i.ar"
since = sys.argv[2] if len(sys.argv) > 2 else "2026-09-21"

log = subprocess.run(
    ["git", "-C", repo, "log", f"--since={since}", "--format=%H%x09%s%x09%an"],
    capture_output=True, text=True, errors="replace").stdout
rows = []
for line in log.splitlines():
    parts = line.split("\t", 2)
    if len(parts) != 3:
        continue
    sha, subj, author = parts
    stat = subprocess.run(
        ["git", "-C", repo, "show", sha, "--stat", "--format="],
        capture_output=True, text=True, errors="replace").stdout
    ins = dele = 0
    files = 0
    for sl in stat.splitlines():
        m = re.match(r"\s*(\d+)\s+file.*?(\d+) insertion.*?(\d+) deletion", sl) if False else None
    m = re.search(r"(\d+) files? changed(?:, (\d+) insertions?\(\+\))?(?:, (\d+) deletions?\(-\))?", stat)
    if m:
        files = int(m.group(1))
        ins = int(m.group(2) or 0)
        dele = int(m.group(3) or 0)
    # comment-only heuristic: every changed line starts with ';' or ';;'
    diff = subprocess.run(
        ["git", "-C", repo, "show", sha, "--format=", "-U0"],
        capture_output=True, text=True, errors="replace").stdout
    changed = [l[1:] for l in diff.splitlines()
               if (l.startswith("+") and not l.startswith("+++"))
               or (l.startswith("-") and not l.startswith("---"))]
    non_comment = [l for l in changed if l.strip() and not l.strip().startswith(";")]
    flag = ""
    if not changed:
        flag = "EMPTY-DIFF"
    elif "fix" in subj.lower() and all(l.strip().startswith(";") for l in changed if l.strip()):
        flag = "COMMENT-ONLY-FIX"
    elif files == 1 and (ins + dele) > 500:
        flag = "HUGE-SINGLE-FILE"
    elif dele > 100000:
        flag = "MASS-DELETION"
    rows.append((sha[:7], subj[:70], author[:10], files, ins, dele, flag))

print(f"{'sha':8} {'author':10} {'f':>3} {'ins':>5} {'del':>5}  subject")
for sha, subj, author, files, ins, dele, flag in rows:
    mark = "  << ALARM: " + flag if flag else ""
    print(f"{sha:8} {author:10} {files:3d} {ins:5d} {dele:5d}  {subj}{mark}")
print(f"\ntotal: {len(rows)} commits, flagged: {sum(1 for r in rows if r[6])}")
