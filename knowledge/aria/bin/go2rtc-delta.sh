#!/bin/bash
# go2rtc producer-flow delta: two samples 15s apart, per-stream per-codec.
# Shows which producer receivers are STILL receiving vs frozen.
# Run on sophon (root ssh): ssh root@sophon 'bash -s' < go2rtc-delta.sh
#
# Fills the PRODUCER point in the three-point differential
# (camera direct RTSP / go2rtc producer / recorded segment).
# Interpretation:
#   FLOWING  (>1KB/s)  -- track healthy at the producer
#   FROZEN   (0 B/s)   -- track dead mid-session (e2 NO-AUDIO class)
#   TRICKLE  (<1KB/s)  -- renegotiation in flight or degraded feed
#   NEGATIVE delta      -- receiver was RECREATED between samples
#                          (renegotiation/reset; new receiver young)
# Caveat: a single 15s window can land in a healthy gap of an
# intermittent flap -- pair with the recorded-segment check before
# verdicts (ext4, 2026-09-03 20:00 UTC).
set -u
S1=$(runuser -l nacho -c "podman exec frigate curl -s http://localhost:1984/api/streams" 2>/dev/null)
sleep 15
S2=$(runuser -l nacho -c "podman exec frigate curl -s http://localhost:1984/api/streams" 2>/dev/null)

parse() {
  echo "$1" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for name,st in sorted(d.items()):
    for p in (st.get('producers') or []):
        for r in (p.get('receivers') or []):
            c=(r.get('codec') or {}).get('codec_name','?')
            print(f\"{name} {c} {r.get('bytes',0)} {r.get('packets',0)}\")
"
}

echo "=== sample1 ==="; parse "$S1"
echo "=== sample2 ==="; parse "$S2"
echo "=== delta (bytes/s over 15s) ==="
parse "$S1" > /tmp/g2s1.txt; parse "$S2" > /tmp/g2s2.txt
python3 - <<'EOF'
s1={}; s2={}
for line in open('/tmp/g2s1.txt'):
    p=line.split(); s1[(p[0],p[1])]=(int(p[2]),int(p[3]))
for line in open('/tmp/g2s2.txt'):
    p=line.split(); s2[(p[0],p[1])]=(int(p[2]),int(p[3]))
for k in sorted(s2):
    b1=s1.get(k,(0,0))[0]; b2,p2=s2[k]
    dbps=(b2-b1)/15.0
    state="FLOWING" if dbps>1000 else ("FROZEN" if b2==b1 else "TRICKLE")
    if b2<b1: state="RESET (receiver recreated)"
    print(f"{k[0]:12s} {k[1]:5s} {b2:>12d}B  delta={dbps:>9.0f}B/s  {state}")
EOF
