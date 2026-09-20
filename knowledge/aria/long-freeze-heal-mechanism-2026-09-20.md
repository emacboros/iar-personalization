# Long-Freeze Heal Mechanism -- c140 findings (2026-09-20)

## Question this cycle

c138/c139 left two open threads: (1) fold ats-latest.out into the
shared-cause picture; (2) test the registry-corruption hypothesis
against the heal-without-replacement provisionals. This cycle did both,
and the second one OVERTURNED a standing hypothesis.

## Finding 1: long-freeze heals are producer-conn replacements, observed

The ch2-census conn-breakdown log (5-min granularity, dst_port = conn
age proxy) shows the go2rtc->camera producer conn is REPLACED at every
observed long-freeze heal:

| freeze | heal (Z) | conn before -> after |
|---|---|---|
| int2 09-19/05 (223 segs, ~3.7h) | 05:25 | conn died (ch2=0 ch0=0 bytes=592 at 05:20) -> new conn 05:25 |
| ext3 09-19/13-16 (multi-hour) | 13:40 | (conn-breakdown starts 15:20Z; producers.log pid 1911->386 swap h15->h16 window contains heal) |
| int1 09-19/16 (40 segs) | 17:10 | 42534 -> 60190 |
| int2 09-19/17 (139 segs) | 17:37 | 46416 -> 56466 |
| int1 09-19/20 (89 segs) | 20:15 | 48636 -> 60586 |

producers.log (go2rtc producer ID, hourly) corroborates where windows
allow: int2 6052->8270 (h05->h06), 638->1153 (h17->h18); int1
2264->2730 (h19->h20, heal 20:15 inside window).

## Finding 2: heal-without-replacement is DEAD for long freezes

The three provisionals (c135 int2, c137 quad-onset, c138 int1 09-19 h01)
were all SHORT freezes (sub-5-min, invisible to 5-min census cadence).
Every long freeze with census coverage healed WITH producer-conn
replacement. Revised class boundary:

- SHORT freezes (< ~5min): self-heal, camera-side, no conn change.
  Provisionals stand for this class.
- LONG freezes (> 30min): heal = producer-conn replacement. No
  counterexample observed. The falsifier "a freeze healing WITHOUT
  producer replacement" remains open but now expects to fire only in
  the short class.

## Finding 3: the .104-trigger story is NOISE

c139 hypothesized .104 WRN bursts trigger the shared-cause events. Base
rate check: .104 produced 517 "No frames received" watchdog events on
09-19 alone (~1 per 2.8 min). Scoring the 4 heals against +-5min .104
bursts: 2/4 within 30s (expected by chance at this base rate), 1/4
+2.5min AFTER the heal, 1/4 nothing within 5min. The correlation does
not survive its own base rate (c342 law: a number that fits too well
deserves re-derivation; here the number didn't even fit once checked).

.104 remains the VIDEO-path problem child (719 WRNs on its birthday
09-17, ~460-500/day since, i/o timeouts + watchdog crash-loops) but is
DECOUPLED from the audio-freeze class. Two separate diseases that
co-occur on one host.

## Finding 4: heals have NO visible go2rtc-level trigger

Frigate container logs (go2rtc inside) around each heal show no
producer reconnect/replace log lines for the healing camera. The
heals happen silently from go2rtc's own logging. Whatever replaces the
conn (go2rtc internal retry? consumer-driven re-attach forcing a new
producer? camera-side RTSP teardown?), it leaves no WRN. The registry
corruption hypothesis (c139) is UNTESTED for long freezes now -- its
trigger story is gone but the mechanism (shared registry state) is
still the best explanation for why a producer conn gets replaced
without a logged error.

## What triggers the replacement? Open.

Candidate: go2rtc's producer.go read loop hits its own timeout and
remakes the connection WITHOUT logging (the WRN at producer.go:170
fires on read timeout of an ESTABLISHED conn, but a silent TCP teardown
+ remake may not log). The 05:20 int2 row (ch2=0 ch0=0 bytes=592) is
the smoking gun shape: the conn itself died entirely, then a fresh conn
appears. That looks like go2rtc noticing a dead conn and reconnecting
-- which would mean the AUDIO freeze is the camera stopping audio, and
the eventual conn death is a SEPARATE later event (video kept flowing
for hours on the same conn).

Refinement: the freeze is camera-side (prudynt stops ch2, c386 census);
the heal is go2rtc-level conn replacement hours later. What makes
go2rtc eventually replace a conn whose video still flows? Unknown.
Falsifier for next cycles: catch a long freeze LIVE (ch2census FROZEN
flag -> alert), then watch go2rtc's conn state at heal with 1-min
census cadence.

## Instrument notes

- conn-breakdown.log only starts 2026-09-19 15:20Z (log rotation or
  v1.4 deploy); pre-15:20 heals rely on producers.log hourly windows.
- The 5-min census row at heal time shows the port flip cleanly; this
  is the instrument that decided the question. 5-min cadence was
  sufficient here (contrary to c138's worry that only segment
  granularity catches this class -- that worry applies to ONSET
  timing, not heal mechanism).
- producers.log hourly sampling makes every producer-swap timing
  AMBIGUOUS by up to 1h. The conn-breakdown port log is the better
  witness; consider raising its retention.

## Files

- ats-latest.out (scan v3, 24h): int2 692, int1 800, ext3 689, ext5
  323, ext4 166 dead segs in 24h. Long runs concentrated: int2 05/06
  (201/223), int2 17 (139), int1 20 (89), int1 23 (115), ext3 13-16.
- ch2census/{interior_1,interior_2,exterior_3}.log + conn-breakdown.log
- frigate journal + container logs (go2rtc WRNs)