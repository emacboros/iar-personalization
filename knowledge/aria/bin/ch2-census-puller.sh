#!/bin/bash
# aria-ch2-census-puller.sh v1.6 (2026-09-20, aria cycle 165)
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
# v1.3 (c122): FIXED v1.2 -- .104 was added to CAMS but NOT to the NAME maps (bash + python), and the conn gate reads NAME, so .104 stayed census-invisible. The blind-source fix never functionally landed.
# v1.2 (c116): added .104 to CAMS -- the unstable producer was census-invisible by config (blind-source law).
# v1.1 CORPSE-CONN FIX (c110/c111 census-lag class):
#   v1.0 sampled ONE established conn per camera (ss map overwrote on
#   churn), so after go2rtc replaced a producer the census kept watching
#   the CORPSE conn -- video flowing, audio dead -- and reported FROZEN
#   for 15+ min past the real heal (int1 14:00Z freeze, healed 14:01:11Z,
#   census rows FROZEN through 14:20Z). v1.1:
#   1. enumerates ALL established producer conns per camera (ports append,
#      not overwrite) and captures on every one of them;
#   2. per-camera row = SUM across that camera's conns; FROZEN only if
#      every anchored conn shows ch2=0 (a corpse conn alone can't flag);
#   v1.4 (c132): reassembly-artifact guard -- FROZEN requires
#      near-zero bytes; low-frames + healthy-bytes rows flagged ARTIFACT
#      (TCP reassembly failure under retransmit, not a freeze).
#   3. per-conn detail appended to conn-breakdown.log:
#      "CONN <ts> <cam> <dstport> <ch2> <ch0> <bytes> anchored=0|1"
#      dst_port is a conn-age proxy (go2rtc assigns fresh ephemeral ports
#      per producer) -- conn-age checks need no new code, just this log.
#   Per-cam row format UNCHANGED (fleet-check + fear-organ readers intact).
#
# METHOD (c386 census, hardened):
#   1. ss -tn: find established conns 192.168.2.69 -> <cam>:554 (ALL ports)
#   2. tcpdump 20s full-snaplen capture on those conns (-s 0; the -s 96
#      mistake truncated payloads and broke frame parsing -- c388 scar)
#   3. reassemble per connection in TCP seq order (interleaved frames
#      SPAN TCP segments; per-packet parsing misses frame starts)
#   4. walk $-interleaved frames from the first clean frame boundary
#      (stream may start mid-frame; require 3 clean frames to anchor)
#   5. append "<epoch> <cam> <ch2> <ch0> <bytes>" per cam to
#      /var/lib/aria-fleet/ch2census/<cam>.log; FROZEN flag only if ALL
#      anchored conns for the cam show ch2=0
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
CAMS="192.168.2.101 192.168.2.102 192.168.2.103 192.168.2.104 192.168.2.105 192.168.2.201 192.168.2.202 192.168.2.203"
# cam ip -> name map (matches segcensus naming)
declare -A NAME=(
  [192.168.2.101]=exterior_1
  [192.168.2.102]=exterior_2
  [192.168.2.103]=exterior_3
  [192.168.2.104]=exterior_4
  [192.168.2.105]=exterior_5
  [192.168.2.201]=interior_1
  [192.168.2.202]=interior_2
  [192.168.2.203]=interior_3
)
TS=$(date +%s)

mkdir -p "$OUT" 2>/dev/null || { echo "ch2census: cannot create $OUT" >&2; exit 0; }

# 1. map established producer conns: cam ip -> ALL local ports (v1.1:
#    append, never overwrite -- the v1.0 overwrite was the corpse-conn bug)
declare -A CONN
while read -r _ _ laddr lport _ raddr rport _; do
  ip="$raddr"; [ -n "${NAME[$ip]:-}" ] && CONN[$ip]="${CONN[$ip]:-} $lport"
done < <(ss -tn state established 2>/dev/null | awk -v h="$HOSTIP" '
  NR>1 && $3 ~ h":" && $4 ~ /:554$/ {split($3,a,":"); split($4,b,":"); print "x x " a[1] " " a[2] " x " b[1] " " b[2] " x"}')

if [ "${#CONN[@]}" -eq 0 ]; then
  echo "$TS no-conns" >> "$OUT/census-errors.log"
  exit 0
fi

# 2. capture 20s on ALL established cam conns (full snaplen)
FILTER=""
for ip in "${!CONN[@]}"; do
  for port in ${CONN[$ip]}; do
    FILTER="$FILTER or (src host $ip and src port 554 and dst port $port)"
  done
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
        "192.168.2.103":"exterior_3","192.168.2.104":"exterior_4","192.168.2.105":"exterior_5",
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
# v1.1: group per-conn streams by camera; per-cam row = SUM across conns
percam = collections.defaultdict(list)
for key in sorted(streams):
    name = NAME.get(key[0])
    if name: percam[name].append((key[1], streams[key]))
for name in sorted(percam):
    total = [0, 0, 0, 0]; nbytes = 0; anchored = 0
    for dport, segs in percam[name]:
        data = b"".join(segs[k] for k in sorted(segs))
        n = len(data); nbytes += n
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
        counts = [0, 0, 0, 0]
        if start is not None:
            anchored += 1
            off = start
            while off + 4 <= n and data[off:off+1] == b"$":
                ch = data[off+1]; ln = int.from_bytes(data[off+2:off+4], "big")
                if off + 4 + ln > n: break
                if ch <= 3: counts[ch] += 1
                off += 4 + ln
        print(f"CONN {ts} {name} {dport} {counts[2]} {counts[0]} {n} anchored={1 if start is not None else 0}")
        for j in range(4): total[j] += counts[j]
    # v1.4 (c132): reassembly-artifact guard. Discriminator from the
    # c132 forensics: a REAL freeze kills AUDIO only -- video keeps
    # flowing (audio=0, video 24-225/20s). A reassembly failure collapses
    # BOTH counts (audio 0-17, video 1-6) while bytes stay healthy
    # (181-239kB). So: video<=10 with healthy bytes = ARTIFACT (both
    # collapsed = walk failure, cross-check recordings); audio=0 with
    # video flowing = FROZEN (the real freeze shape); audio=0 with
    # collapsed video AND collapsed bytes = FROZEN (total death).
    # v1.6 (c165): VIDEO-DEAD class. The c165 live find: .103/.104 sent AUDIO ONLY
    # for 40+ min (ch2=374, ch0=0, bytes ~106k = audio-sized). The v1.4 guard
    # mislabeled this ARTIFACT (assumed ch0=0 + healthy bytes = walk failure).
    # Discriminator: ch2 flowing (>=20 frames/20s) + ch0==0 + healthy
    # bytes = the camera genuinely stopped sending video. A walk failure collapses
    # BOTH (ch2<=10 too). Order: VIDEO-DEAD first, then ARTIFACT, then FROZEN.
    videodead = anchored > 0 and total[2] >= 20 and total[0] == 0 and nbytes > 100000
    artifact = (not videodead) and anchored > 0 and total[0] <= 10 and total[2] <= 10 and nbytes > 100000
    frozen = anchored > 0 and total[2] == 0 and not artifact and not videodead
    flag = " VIDEO-DEAD" if videodead else (" ARTIFACT" if artifact else (" FROZEN" if frozen else ""))
    print(f"{ts} {name} {total[2]} {total[0]} {nbytes}{flag}")
' "$TS" 2>/dev/null | while read -r row; do
  case "$row" in
    CONN\ *) echo "$row" >> "$OUT/conn-breakdown.log" ;;
    *) cam=$(echo "$row" | awk "{print \$2}")
       echo "$row" >> "$OUT/$cam.log" ;;
  esac
done

rm -f /tmp/ch2census-run.pcap
exit 0