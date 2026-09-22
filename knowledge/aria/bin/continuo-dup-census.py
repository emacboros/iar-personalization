#!/usr/bin/env python3
"""Continuo journal dup census -- D-017 falsifier instrument (v3).
Registered lens (first-100-key, dup-entry, pooled) + decomposed lens v2
(ADJACENT/SPREAD x FULL/PARTIAL/PREFIX-ONLY). Encodes aria c186+c195
specs so the series stays comparable; control arm = aria's journal.
Usage: continuo-dup-census.py <journal> <start> <end> [--pairs]
"""
import sys, re, difflib
from collections import defaultdict, Counter

path, start, end = sys.argv[1], sys.argv[2], sys.argv[3]
show_pairs = "--pairs" in sys.argv
text = open(path, encoding='utf-8', errors='replace').read()
parts = re.split(r'(?m)^\* (\d{4}-\d{2}-\d{2})([^\n]*)\n', text)
entries = []
for i in range(1, len(parts) - 2, 3):
    date, body = parts[i], parts[i + 2]
    if not (start <= date <= end):
        continue
    lines = [l for l in body.strip().splitlines() if l.strip()]
    if not lines:
        continue
    joined = "\n".join(lines)
    if joined.strip().startswith("PULSE"):
        continue
    entries.append((date, joined[:100], joined))

total = len(entries)
seen = {}
dup_entries = 0
pairs = []
for idx, (date, key, body) in enumerate(entries):
    is_dup = key in seen
    if is_dup:
        dup_entries += 1
    if is_dup:
        for (pidx, pdate) in seen[key]:
            sep = idx - pidx
            rem_a = entries[pidx][2][100:].strip()
            rem_b = body[100:].strip()
            ratio = 1.0 if (not rem_a and not rem_b) else \
                difflib.SequenceMatcher(None, rem_a, rem_b).ratio()
            cls = "FULL" if ratio > 0.8 else ("PARTIAL" if ratio >= 0.5 else "PREFIX-ONLY")
            sepcls = "ADJACENT" if sep == 1 else "SPREAD"
            pairs.append((pdate, date, sep, cls, sepcls, round(ratio, 2)))
    seen.setdefault(key, []).append((idx, date))

label = "CONTINUO" if "continuo" in path else "ARIA(control)"
print(f"{label} window {start}..{end}: entries={total}")
print(f"REGISTERED LENS (dup-entry pooled): {dup_entries}/{total} = {dup_entries/total*100:.0f}%")
c = Counter((p[4], p[3]) for p in pairs)
for (sep, cls), n in sorted(c.items()):
    print(f"  {sep}/{cls}: {n}")
sf = [p for p in pairs if p[4] == "SPREAD" and p[3] == "FULL"]
print(f"DECOMPOSED SPREAD+FULL: {len(sf)}/{total} = {len(sf)/total*100:.0f}%")
if show_pairs:
    for p in sf:
        print(f"  {p[0]} -> {p[1]} sep={p[2]} ratio={p[5]}")
