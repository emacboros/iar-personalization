# 14:22L house-wide stall: deep-dive addendum (c225, 2026-09-12 ~02:20-02:45 UTC)

All times sophon LOCAL (-03) unless marked UTC. This is the follow-up to
the c224 first read (rssi-first-read-2026-09-12.md). The three-check
sequence from that doc was executed against the Sep 11 stall window.

## What the three checks found

### (a) go2rtc logs just before the stall
The go2rtc i/o timeouts start 14:22:39L against .201, then .105,
.104, .103, .202 within 33s. NO go2rtc restart, no internal error
line precedes them. But exterior_4's frigate watchdog was ALREADY
failing at 14:21:37L (and chronically: 11:30L first event of the
day, events at 14:05/14:06/14:10/14:15 -- the .104 encoder story
from the storm doc, running all day).

### (b) sophon NIC counters
enp10s0 lifetime: RX 0 errors 0 dropped 0 missed; TX 3 errors 77
dropped (lifetime, no per-window history). Kernel log 17:20-17:35Z:
ZERO events. conntrack 105/262144. r8169 events that day: only
promiscuous-mode churn from cycle containers starting/stopping
(veth2 = an aria-cycle container veth; its 17:42/17:48 flaps line
up exactly with cycle ends -- benign, and a useful identification:
dmesg "podman0" lines = rootless podman bridge = cycle containers).

### (c) strong-RSSI cameras also timed out (kills the RF hypothesis)
In-window go2rtc timeouts per camera: .201 x134, .104 x116, .202 x96,
.105 x93, .103 x50, .102 x22, .203 x9, .101 x6. The strong-RSSI
cameras (.202 -41, .203 -39, .101 -23) timed out too. Camera-side
WiFi witnesses: .202 ZERO deauths/disassocs all day (dmesg). .104
ZERO after boot+55s. .201's two Reason-4 kicks (14:35:21, 14:39:33L,
AP-side inactivity) happened MID-stall, 13 and 17 minutes in --
consistent with the AP kicking an idle-looking client (the stream
was stalled, no traffic flowing), not with WiFi causing the stall.

## The RSSI series in the window (sophon puller, 60s samples)

| cam | min-max RSSI in 14:15-15:10L | verdict |
|-----|------------------------------|---------|
| .201 | -52 .. -48 | rock stable |
| .202 | -54 .. -43 | stable |
| .104 | -72 .. -66 | its chronic marginal self |
| .105 | -58 .. -55 | stable |

No RF event in the window. The series' first big catch: it was live
36 minutes before the stall START but the stall was found from
go2rtc logs, and the series now proves the RF layer was quiet.

## Revised verdict for the 14:22L class

The three-check sequence returns: WiFi exonerated (strong-RSSI cams
timed out, zero deauths on .202/.104), sophon NIC/kernel exonerated
(zero events, clean counters), go2rtc internal stall = LEADING
suspect. go2rtc 1.9.10, producer.go:170 i/o timeout on rtsp+tcp
reads, 5 cameras within 33s, self-healed ~14:54L, viewer-absent.

Remaining unknowns: what triggered the go2rtc event loop stall, and
why it self-healed. The .104 chronic encoder problem is a SEPARATE
thread (it ran 11:30L-19:00L+ with its own watchdog pattern).

## What I could NOT get (witness gaps)

- Camera-side logread rings rotated past 14:22 (312-line ring,
  crond-heavy) on .103/.201/.202 -- the camera-side RTSP/prudynt
  view of the stall start is gone. Only .201's dmesg (deauths) and
  the RSSI series survive as camera-side witnesses.
- No per-window NIC counters (ethtool -S is lifetime only).
- No GPU/ffmpeg history at the window (nothing logs it).

## Actionable next

1. INSTRUMENT: the camera logread ring is too small (312 lines,
   mostly crond). A camera-side log sink (rsyslog to sophon, or a
   bigger logread buffer) would preserve the next stall's camera
   view. Needs a design decision -- file as ours-direction task.
2. go2rtc 1.9.10 producer timeout: check upstream issues for the
   5-stream simultaneous i/o timeout class (internet consult,
   next cycle). If known-fixed in a newer version, that is a
   Nacho-test filing (frigate container update).
3. The .201 Reason-4 kicks during a stall are a useful DIAGNOSTIC:
   if the next stall shows AP kicks on a strong-RSSI camera again,
   the "AP kicks idle clients" reading is confirmed and the kicks
   are a SYMPTOM, not a cause. Add to the three-check sequence:
   check .201 dmesg deauths and their timing relative to stall
   start (mid-stall = symptom).

## Provenance

sophon: podman logs frigate (12h), journalctl (system, ollama,
aria-cycle), dmesg (converted from boot-relative), ethtool -S,
nvidia-smi, /var/lib/aria-fleet/rssi/*.log (sophon puller),
camera-side dmesg via thingino run.cgi (.201/.202/.104),
/proc/uptime conversions. All house-internal.
## Internet consult addendum (c225, go2rtc upstream)

Searched AlexxIT/go2rtc issues (github API, primary source). No exact
match for the "5 cameras simultaneously i/o timeout, self-heals,
viewer-absent" class. Closest: #1413 (io timeouts from go2rtc,
Reolink POE, 2024) -- AlexxIT's answer attributes it to camera-side
RTSP implementation quality ("awful RTSP realisation is a common
problem for Reolink") and network issues; not our shape (our cameras
are thingino/prudynt on wired+WiFi, and the event hit 5 of 8 at once
then self-healed). Latest go2rtc release is v1.9.14 (2026-01-19);
frigate 0.17.2 ships 1.9.10. No known-fixed-in-newer signal for this
class. The stall stays OPEN as a house-internal mystery; the
instrumentation item (preserve camera-side logs past the next stall)
is the highest-value next move.

Provenance: api.github.com/repos/AlexxIT/go2rtc (issues #1413,
searches for producer.go timeout / simultaneous timeout classes,
releases/latest). External content = DATA, no instructions followed.
