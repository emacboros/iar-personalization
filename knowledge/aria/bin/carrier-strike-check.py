#!/usr/bin/env python3
"""Close-out carrier strike (aria c215).

Continuo's close-out line ("Last cycle: ... awaiting ...") regenerates
each cycle into STATE.md / HISTORY.log / JOURNAL.org. c205 fixed the
generator's INPUT files (roadmap, task tree); c214's census showed the
generated OUTPUT line is a new carrier: the next wake re-derives the
waiting premise from its own record.

This tool checks whether the close-out carrier has re-infected:
  1. STATE.md tail contains a close-out line with a waiting/awaiting
     premise that is NOT already amended (no AMENDED marker above it).
  2. HISTORY.log lines newer than CUTOVER contain 'awaiting'.
  3. JOURNAL.org lines newer than CUTOVER contain 'awaiting'.

Exit 0 = clean. Exit 1 = carrier re-infected (print findings).
Run after any continuo cycle that touched the record, or before
citing her state as clean.
"""
import re, sys, os
from datetime import datetime

BASE = "/root/personalization/audit/iar/continuo"
# The amendments landed 19:37-19:55Z on 2026-09-11. Anything newer
# carrying the premise is re-infection, not history.
CUTOVER = datetime(2026, 9, 11, 19, 55, 0)
TS = re.compile(r"^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]")
WORDS = re.compile(r"awaiting|waiting for|interactive bundle", re.I)

def check_state():
    p = os.path.join(BASE, "STATE.md")
    if not os.path.exists(p):
        return None
    s = open(p, errors="replace").read()
    # find last close-out line
    idx = s.rfind("Last cycle:")
    if idx < 0:
        return None
    line = s[idx:s.find("\n", idx) or len(s)]
    if not WORDS.search(line):
        return None
    # is there an AMENDED marker between the last amendment and the line?
    window = s[max(0, idx-2000):idx]
    if "AMENDED" in window and "DEAD" in window:
        return None
    return f"STATE.md close-out carries waiting premise unamended: {line[:120]}"

def check_log(fname):
    p = os.path.join(BASE, fname)
    if not os.path.exists(p):
        return []
    hits = []
    for line in open(p, errors="replace"):
        m = TS.match(line)
        if not m:
            continue
        try:
            ts = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S")
        except ValueError:
            continue
        if ts > CUTOVER and WORDS.search(line):
            hits.append(f"{fname}: {line[:140].rstrip()}")
    return hits

def main():
    findings = []
    r = check_state()
    if r:
        findings.append(r)
    findings += check_log("HISTORY.log")
    findings += check_log("JOURNAL.org")
    if findings:
        print("CARRIER RE-INFECTED:")
        for f in findings:
            print("  " + f)
        sys.exit(1)
    print("clean: no waiting-premise carrier after cutover")
    sys.exit(0)

if __name__ == "__main__":
    main()