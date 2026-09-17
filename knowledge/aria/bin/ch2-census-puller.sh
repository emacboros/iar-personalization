#!/bin/bash
# aria-ch2-census-puller.sh v1.0 (2026-09-17, aria cycle 13)
# -------------------------------------------------------------
# ch2-census: counts interleaved RTSP audio-channel (ch2) frames on the
# ESTABLISHED camera->sophon producer connections, per camera, per run.
#
# WHY (c386->c388, audio-freeze class): the disease is CAMERA-SIDE --
# prudynt silently stops sending the audio track on an established
# RTSP-over-TCP connection (zero ch2 frames on the producer conn while
# video ch0 flows). Recorder-side instruments (segcensus, ear-check)
# see the effect an hour later or at 6h cadence; the producer probe
# reads the SDP claim, not delivery (SDP-ADVERTISED != PACKETS-FLOWING,
# law-50 member). The ch2 census reads the NETWORK layer directly and
# discriminates frozen vs healthy in one 20s capture:
#   frozen cam: ch2=0 on the producer conn (c386 packet census)
#   healthy cam: hundreds of ch2 frames in 20s
#   healing cam: small nonzero (partial hour)
# Validated 2026-09-17 ~08:17Z against segcensus same-hour rows:
#   ext1 ch2=0  <-> 225/225 segments dead   (frozen)   CONSISTENT
#   int2 ch2=50 <-> 1/229 dead              (healed)   CONSISTENT
#   ext3 ch2=19 <-> 96/235 dead             (healing)  CONSISTENT
#
# METHOD (c386 census, hardened):
#   1. ss -tn: find established conns 192.168.2.69 -> <cam>:554
#   2. tcpdump 20s full-snaplen capture on those conns (-s 0; the -s 96
#      mistake truncated payloads and broke frame parsing -- c388 scar)
#   3. reassemble per connection in TCP seq order (interleaved frames
#      SPAN TCP segments; per-packet parsing misses frame starts)
#   4. walk $-interleaved frames from the first clean frame boundary
#      (stream may start mid-frame; require 3 clean frames to anchor)
#   5. append "<epoch> <cam> <ch2> <ch0> <bytes>" per cam to
#      /var/lib/aria-fleet/ch2census/<cam>.log; ch2=0 rows get FROZEN flag
#
# READ-ONLY toward the network and recordings; writes only to its own dir.
# Reversible (D-011 aria-reversible): rm -rf /var/lib/aria-fleet/ch2census
#   + rm the service/timer units + revert this file.
#
# INSTALL:
#   cp aria-ch2-census.service /etc/systemd/system/
#   cp aria-ch2-census.timer   /etc/systemd/system/
#   systemctl daemon-reload && systemctl enable --now aria-ch2-census.timer
# UNDO: systemctl disable --now aria-ch2-census.timer
#       rm /etc/systemd/system/aria-ch2-census.{service,timer}
#       rm -rf /var/lib/aria-fleet/ch2census
# -------------------------------------------------------------
set -u

OUT=/var/lib/aria-fleet/ch2census
HOSTIP=192.168.2.69
CAMS="192.168.2.101 192.168.2.102 192.168.2.103 192.168.2.105 192.168.2.201 192.168.2.202 192.168.2.203"
# cam ip -> name map (matches segcensus naming)
declare -A NAME=(
  [192.168.2.101]=exterior_1
  [192.168.2.102]=exterior_2
  [192.168.2.103]=exterior_3
  [192.168.2.105]=exterior_5
  [192.168.2.201]=interior_1
  [192.168.2.202]=interior_2
  [192.168.2.203]=interior_3
)
TS=$(date +%s)

mkdir -p "$OUT" 2>/dev/null || { echo "ch2census: cannot create $OUT" >&2; exit 0; }

# 1. map established producer conns: cam ip -> local port
declare -A CONN
while read -r _ _ laddr lport _ raddr rport _; do
  ip="$raddr"; [ -n "${NAME[$ip]:-}" ] && CONN[$ip]=$lport
done < <(ss -tn state established 2>/dev/null | awk -v h="$HOSTIP" '
  NR>1 && $3 ~ h":" && $4 ~ /:554$/ {split($3,a,":"); split($4,b,":"); print "x x " a[1] " " a[2] " x " b[1] " " b[2] " x"}')

if [ "${#CONN[@]}" -eq 0 ]; then
  echo "$TS no-conns" >> "$OUT/census-errors.log"
  exit 0
fi

# 2. capture 20s on all established cam conns (full snaplen)
FILTER=""
for ip in "${!CONN[@]}"; do
  FILTER="$FILTER or (src host $ip and src port 554 and dst port ${CONN[$ip]})"
done
FILTER="${FILTER# or }"
timeout 25 tcpdump -i any -nn -s 0 "$FILTER" -w /tmp/ch2census-run.pcap >/dev/null 2>&1
PCAP_BYTES=$(stat -c %s /tmp/ch2census-run.pcap 2>/dev/null || echo 0)
if [ "$PCAP_BYTES" -lt 1000 ]; then
  echo "$TS pcap-too-small ($PCAP_BYTES bytes)" >> "$OUT/census-errors.log"
  exit 0
fi

# 3+4+5. reassemble + walk + append (python3, stdlib only)
tcpdump -nn -r /tmp/ch2census-run.pcap -x 2>/dev/null | python3 -c '
import sys, re, collections
NAME = {"192.168.2.101":"exterior_1","192.168.2.102":"exterior_2",
        "192.168.2.103":"exterior_3","192.168.2.105":"exterior_5",
        "192.168.2.201":"interior_1","192.168.2.202":"interior_2",
        "192.168.2.203":"interior_3"}
cur = None; buf = bytearray(); seq = None
streams = collections.defaultdict(dict)
def flush():
    global buf
    if cur is not None and len(buf) >= 40 and seq is not None:
        try:
            ihl = (buf[0] & 0xF) * 4
            total = int.from_bytes(buf[2:4], "big")
            doff = ((buf[ihl + 12] >> 4) & 0xF) * 4
            pay = bytes(buf[ihl + doff : ihl + total])
            if pay: streams[cur][seq] = pay
        except Exception: pass
    buf = bytearray()
for line in sys.stdin:
    m = re.match(r"(\d\d:\d\d:\d\d\.\d+)\s+\S+\s+(?:In|Out)\s+IP\s+(\d+\.\d+\.\d+\.\d+)\.(\d+)\s+>\s+(\d+\.\d+\.\d+\.\d+)\.(\d+).*?seq (\d+):(\d+)", line)
    if m:
        flush(); cur = (m.group(2), int(m.group(5))); seq = int(m.group(6)); continue
    hm = re.match(r"\s+0x([0-9a-f]{4}):\s+((?:[0-9a-f]{2,4}\s+)+)", line)
    if hm and cur is not None:
        try: buf.extend(bytes.fromhex(hm.group(2).replace(" ", "")))
        except ValueError: pass
flush()
import sys as _s
ts = _s.argv[1] if len(_s.argv) > 1 else "0"
for key in sorted(streams):
    cam_ip = key[0]
    name = NAME.get(cam_ip)
    if not name: continue
    segs = streams[key]
    data = b"".join(segs[k] for k in sorted(segs))
    n = len(data)
    # anchor: first $ that walks >=3 clean frames (stream may start mid-frame)
    start = None
    for i in range(n - 4):
        if data[i:i+1] == b"$":
            off = i; ok = 0
            while off + 4 <= n and data[off:off+1] == b"$":
                ln = int.from_bytes(data[off+2:off+4], "big")
                if off + 4 + ln > n: break
                off += 4 + ln; ok += 1
                if ok >= 3: break
            if ok >= 3: start = i; break
    counts = [0,0,0,0]
    if start is not None:
        off = start
        while off + 4 <= n and data[off:off+1] == b"$":
            ch = data[off+1]; ln = int.from_bytes(data[off+2:off+4], "big")
            if off + 4 + ln > n: break
            if ch <= 3: counts[ch] += 1
            off += 4 + ln
    flag = " FROZEN" if (start is not None and counts[2] == 0) else ""
    print(f"{ts} {name} {counts[2]} {counts[0]} {n}{flag}")
' "$TS" 2>/dev/null | while read -r row; do
  cam=$(echo "$row" | awk "{print \$2}")
  echo "$row" >> "$OUT/$cam.log"
done

rm -f /tmp/ch2census-run.pcap
exit 0