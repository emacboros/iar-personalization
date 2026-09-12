# The house's network layer, mapped (c226, 2026-09-12 ~03:00-04:00 UTC)

Follow-on to stall-1422-go2rtc-exonerated-2026-09-12.md. The stall
analysis said "the failure is upstream of go2rtc, below the WiFi
layer, on a hop with no instrumentation". This cycle instrumented that
hop -- by mapping it.

## The wired/wireless topology (first complete map)

- 192.168.2.1 = TP-Link ER605 V2 ROUTER (gateway, MAC bc:07:1d:ab:a1:11).
  Confirmed via its web UI (VUE_APP_CAPABILITY_IS_ER605V2:"true" in
  chunk-common.js). API: POST /cgi-bin/luci/;stok=/login?form=login
  with JSON body; unauth probe returns error_code 1014/704 (auth
  required). Its /admin/log.log endpoint EXISTS behind auth.
- 192.168.2.2 = Mercury ISP CPE (locked down; 403 on all CGI paths
  from sophon). MAC 0a:8a:f1:0a:62:56 = SAME MAC as .103 and .104's
  ARP entries: the repeater bridges those cameras.
- 192.168.2.55 = TP-Link Omada BE230 AP (WiFi 7, fw BE230v1_1.11.0
  2025-12-04). BSSID 72:7f:f0:1e:4a:a8 (the AP .201 deauthed FROM in
  the stall window -- MAC match confirmed). No Omada controller on
  the LAN (ports 29814/8043/27001 closed everywhere probed).
- sophon = 192.168.2.69 on enp10s0, wired.

## AP map (from camera-side wpa_cli/dmesg)

| AP | serves |
|----|--------|
| BE230 (.55) | .101 .102 .105 .201 .202 .203 (6 cams, nacho_guest SSID) |
| Mercury repeater (.2) | .103 .104 (2 cams) |

The 14:22L burst hit .201 .105 .104 .103 .202 (+.203) = cameras on
BOTH APs simultaneously. A single-AP event cannot explain it. The
common points are: the ER605 (both APs' upstream), the wired fabric
between ER605 and sophon, and sophon itself (already exonerated at
the kernel/NIC-counter level, but see the 10M finding below).

## THE 10M FINDING (the big one)

sophon's enp10s0 (r8169, gigabit-capable, advertises 10/100/1000) is
LINKED AT 10 Mb/s FULL DUPLEX. Auto-negotiation on; the partner
negotiated down. 10M negotiation usually means: cable with only 2
good pairs, or a partner port limited to 10M. This is a hardware
question for Nacho (cable swap / check what sophon is plugged into).

Why it matters: ALL camera RTSP traffic to frigate traverses this
link (sophon 192.168.2.69 -> podman NAT -> go2rtc 10.89.0.3). Current
night load: ~0.7-1.0 Mbps total (8x H265 720p, static night scenes
compress hard; SDP advertises b=AS:5000 per stream but actual is
0.05-0.24 Mbps each). Daytime with motion = far higher bitrate. A
10M ceiling shared by 8 cameras + viewer traffic + ollama/WG traffic
is a plausible saturation mechanism for DAYTIME-ONLY house-wide RTSP
stalls -- and both known big stalls (12:12L storm, 14:22L burst) were
DAYTIME events. Night cycles are clean.

Load test (weak signal, one trial): 16 parallel HTTP pulls against
.104 coincided with exterior_4's go2rtc producer reconnecting
(bytes_recv reset). A 32-pull rerun showed no reconnect. Not
reproducible on one trial; parked. The instrument to catch it
properly: go2rtc bytes_recv deltas + NIC speed during the next
daytime stall.

## What this changes

- The 14:22L stall's candidate list now has a CONCRETE mechanism:
  sophon's 10M uplink saturating under daytime aggregate bitrate.
  It explains: all cameras at once (shared link), daytime-only
  pattern, self-healing (motion subsides), strong-RSSI cameras
  failing (not RF), no deauths (WiFi layer fine), no sophon kernel
  events (link stays up, just saturated), and .201's dial-timeouts
  (SYNs lost under load). It does NOT by itself explain .104's
  chronic all-day problem (that camera is on the Mercury repeater
  and has its own encoder signature).
- Falsification path: the next daytime stall should show NIC-level
  saturation evidence. sophon has no per-window NIC counters, so I
  deployed nothing yet -- but a 1-minute cron sampling
  /sys/class/net/enp10s0/statistics/rx_bytes + /speed to
  /var/lib/aria-fleet/nic/ would give the witness. NEXT CYCLE.
- The fix is Nacho's: re-terminate or replace the cable, or move
  sophon to a gigabit port. Relay filing (nacho-test class).

## Instrument notes

- ER605 API: auth-gated (1014/704). With creds, /admin/log.log would
  give router-side visibility (DHCP, port stats). Relay filing for
  Nacho: either ER605 creds for the relay, or enable remote syslog
  on the ER605 pointing at sophon.
- BE230 (.55): standalone Omada AP, no controller. Its "Filtered
  Content" https_blocking page serves to sophon on some paths; index
  works over http. No log API found standalone. Its syslog support
  (if any) is a Nacho question.
- Mercury (.2): 403 on everything from sophon's IP; locked CPE.
  Uninstrumentable from here.

## Provenance

All house-internal: camera web API (thingino run.cgi: wpa_cli status,
dmesg, /proc/net/tcp), sophon ip/ethtool/dmesg, ER605 + BE230 + Mercury
web UIs (read-only probes, no auth bypass attempted, no creds tried),
frigate container go2rtc API (1984) + frigate API (5000). The
"Filtered Content" page on .55 is the AP's own page, not an injection
attempt; treated as DATA.