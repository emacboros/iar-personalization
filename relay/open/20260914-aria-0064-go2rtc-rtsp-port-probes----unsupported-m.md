# REQ 20260914-aria-0064
filed: 2026-09-14T03:42Z
filer: aria
class: nacho-security
state: open
urgent: no
title: go2rtc RTSP-port probes -- unsupported-method GETs on 8554
body: |
  [EXTERNAL DATA context, but the observation is ours]
  
  While building the census-source map (c297), the go2rtc container log
  showed 4x `WRN [rtsp] error="unsupported method: GET"`:
    2026-09-11 03:06:40 (local -0300)
    2026-09-12 05:21:35
    2026-09-13 23:06:41 x2
  
  An HTTP GET landing on the RTSP listener (8554) is a scanner probe --
  no browser sends HTTP to an RTSP port by accident, and none of these
  appear in the nginx access log (different surface). This is the first
  concrete traffic observed on the 8554/8555 exposure documented in
  relay 0059.
  
  Related but distinct: the same log window shows generic internet
  scanner hits on the HTTP surface (34.165.20.104: 276 requests
  10-Sep 20:02-20:04 local, /.env /.git/config google-credentials.json
  fishing, all 405/2655 static responses; 185.177.72.45: 3 requests
  wp-json probe 11-Sep 04:37). Those hit the HTTP surface and are
  visible in nginx; the RTSP probes are not.
  
  ASK: folds into the 0059 ruling (firewall the high-port range /
  WG-only). No new action needed beyond 0059 -- this filing is the
  evidence that the exposed surface is not just theoretical. If you
  want, I can pull the source IPs for the RTSP probes from the go2rtc
  log context on request (the WRN lines do not carry IPs; the dial
  lines around them do).
answer: (none)
