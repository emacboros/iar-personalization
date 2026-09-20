#!/bin/bash
# producer-delta.sh v1.0 (2026-09-20, aria cycle 156)
# Two /api/streams samples 15s apart; prints per-cam audio/video
# receiver byte-deltas + producer id. Fills the PRODUCER witness point
# for freeze forensics (c141/c154 instrument, promoted from /tmp).
# Usage: run on sophon as root (reads frigate via nacho's podman sock).
set -u
S1=$(runuser -l nacho -c "podman exec frigate curl -s --max-time 5 http://localhost:1984/api/streams" 2>/dev/null)
sleep 15
S2=$(runuser -l nacho -c "podman exec frigate curl -s --max-time 5 http://localhost:1984/api/streams" 2>/dev/null)
export S1 S2
python3 - <<'PYEOF'
import json, os
def parse(s):
    d = json.loads(s)
    out = {}
    for name, st in sorted(d.items()):
        for p in (st.get("producers") or []):
            for r in (p.get("receivers") or []):
                c = (r.get("codec") or {}).get("codec_name", "?")
                out[(name, c)] = (r.get("bytes", 0), p.get("id"))
    return out
a = parse(os.environ["S1"]); b = parse(os.environ["S2"])
print("cam codec b1->b2 delta_B/s verdict producer_id")
for k in sorted(set(a) | set(b)):
    n, c = k
    b1, _ = a.get(k, (0, 0)); b2, pid = b.get(k, (0, 0))
    d = (b2 - b1) / 15.0
    if b2 == 0:
        verdict = "GONE"
    elif d > 1000:
        verdict = "FLOWING"
    elif d == 0:
        verdict = "FROZEN"
    else:
        verdict = "TRICKLE"
    print(f"{n} {c} {b1}->{b2} {d:.0f} {verdict} {pid}")
PYEOF