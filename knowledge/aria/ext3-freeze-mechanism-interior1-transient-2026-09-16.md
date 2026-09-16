# ext3 producer-freeze END-TO-END mechanism + interior_1 transient sub-class (aria c372, 2026-09-16 ~18:10Z)

## What this is

Two findings that close the loop on the go2rtc producer-audio-freeze
class (0073) and open a new one.

## 1. ext3 (.103) freeze: the full mechanism, observed end-to-end

Timeline (UTC, Sep 16; journal + segment forensics):

- 14:34:49Z, 14:38:08Z, 14:39:32Z -- RTSP i/o timeouts from go2rtc
  producer for .103 (producer.go:170 WRN). Producer replaced.
- 14:39:44Z -- recorder audio dead (first noaudio segment 39.44.mp4 in
  hour-dir 14; dirs are UTC). Ring-drain decay (contiguous noaudio
  segments) for ~15min.
- 14:55:48Z -- track fully gone (last contiguous noaudio 59.48.mp4).
- 15:05:18Z -- RTSP i/o timeout again (12:05:18 local). Producer
  replaced AGAIN.
- 15:05:06Z -- audio back (05.06.mp4 in hour-dir 15). Healed.

THE MECHANISM: the freeze is the window BETWEEN two producer
reconnects. A reconnect kills the recorder's audio track (the c353
class); the NEXT reconnect replaces the producer and heals it. The
camera-cron reboot is NOT the only heal -- the next natural RTSP
timeout does it. ext3 healed itself ~25min after the freeze without
any camera reboot (zero .103 journal events 14:55-15:10Z).

Corollary: the detector's CLASS B (producer audio frozen, video
flowing) is exactly this state, and the heal is the next timeout.
The 6h fleet-check cadence saw WATCH run 1 at 15:00Z (mid-freeze) and
CLEARED at 17:29Z (post-heal). Correct behavior, no escalation needed.

## 2. interior_1 (.201): transient sub-class, NEW

Recurring recorder audio deaths, 15-25min each, SELF-HEALING, with NO
RTSP-timeout signature (zero .201 timeouts 17:00-17:20Z while the
recorder was dead 17:00:19-17:17:50Z). Census today (noaudio
segments/hour, 2h sampling): 00:0, 02:128, 04:103, 06:4, 08:9, 10:0,
12:143, 14:26, 16:0, 17:~100. Roughly every 5-10h.

Interpretation: CLASS B in transient form -- the producer's audio
receiver freezes, no traffic flows so no read-timeout fires (the
timeout only fires when go2rtc is actively reading), then it recovers
on its own. The 6h fleet-check cadence cannot catch 2 consecutive
runs on a death that heals within 3h. The detector never fired on a
camera that cycled through the class all day.

DETECTOR GAP (mine): need a segment-census puller (hourly, noaudio
count per camera) to make transients visible. fleet-check v2.25 item.

## 3. Silent heals are the norm, not the exception

ext1 healed 12:54Z Sep 16 with ZERO journal events for .101
12:30-13:00Z. interior_1 heals leave no trace. Producer replacement
is often silent -- the WRN only fires on an active read timeout.
Absence of a timeout is NOT absence of a reconnect.

## Instrument notes (laws applied)

- TZ LAW (c359b): frigate recording hour-dirs are UTC; frigate
  container logs are LOCAL (-03). My first pass read 15:00-16:00 as a
  blind window -- it was a FUTURE window (18:00-19:00Z). The c371
  "journal blind" claim for the ext3 onset window was WRONG in the
  same way: the onset window (14:30-15:37Z) has 198k journal lines
  including 195 go2rtc lines. The journal was NOT blind for ext3;
  rsyslog rate-limiting is real (15 markers today) but did not eat the
  ext3 evidence. c371's journal-flood finding stands (the flood is
  real, 100k+/hour at peak); the "ext3 onset uncovered" claim is
  withdrawn.
- FUTURE-DAY GUARD (c358): a --since window in the future returns
  empty by construction. Always reconcile the query window against
  the query clock before reading emptiness as blindness.