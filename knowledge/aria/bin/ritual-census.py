#!/usr/bin/env python3
"""Confirmation-ritual census (aria c214).

For every delegate call in an agent's REQUESTS.log(.1), classify:
  - what the delegate was asked (confirmation vs work)
  - whether a WRITE (write_file/append_file/write_subtask/create_task/
    write_roadmap) followed within WINDOW seconds of the delegate RESULT.

Ritual candidate = delegate whose result arrived and NO write followed
before the next delegate or end of window.

Usage: python3 ritual-census.py <agent> <logfile> [...]
"""
import re, sys, json
from datetime import datetime

PAT = re.compile(r'^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] (.*)$')
WINDOW = 600  # seconds after delegate result to look for writes

WRITE_TOOLS = {"write_file", "append_file", "write_subtask", "create_task", "write_roadmap"}

def parse(path):
    events = []
    for line in open(path, errors="replace"):
        m = PAT.match(line)
        if not m:
            continue
        ts = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S")
        rest = m.group(2)
        events.append((ts, rest))
    return events

def main(agent, paths):
    events = []
    for p in paths:
        events.extend(parse(p))
    events.sort(key=lambda e: e[0])

    delegates = []   # (ts, task_head)
    writes = []      # (ts, tool)
    for ts, rest in events:
        if '"name":"delegate"' in rest:
            i = rest.find('"task":"')
            head = rest[i+8:i+90].split('"')[0] if i >= 0 else "?"
            delegates.append((ts, head))
        for t in WRITE_TOOLS:
            if '"name":"%s"' % t in rest:
                writes.append((ts, t))
                break

    print(f"== {agent}: {len(delegates)} delegate calls, {len(writes)} writes, {len(events)} events")
    ritual = 0
    instrument = 0
    for idx, (ts, head) in enumerate(delegates):
        # find next delegate to bound the window
        nxt = delegates[idx+1][0] if idx+1 < len(delegates) else None
        limit = min(ts.replace(microsecond=0).__class__.fromtimestamp(ts.timestamp()+WINDOW), nxt) if nxt else datetime.fromtimestamp(ts.timestamp()+WINDOW)
        followed = [w for w in writes if ts < w[0] <= limit]
        kind = "WORK" if not re.search(r'confirm|appropriate|waiting', head, re.I) else "CONFIRM"
        tag = "INSTRUMENT" if followed else "RITUAL?"
        if followed: instrument += 1
        else: ritual += 1
        print(f"{ts} [{kind:7s}] {tag:10s} writes_after={len(followed)} :: {head[:80]}")
    print(f"-- summary: instrument={instrument} ritual?={ritual} (ritual? = no write within {WINDOW}s; may still be legitimate)")

if __name__ == "__main__":
    agent = sys.argv[1]
    main(agent, sys.argv[2:])