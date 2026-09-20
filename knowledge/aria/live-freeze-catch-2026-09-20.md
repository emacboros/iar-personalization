# Live freeze catch: ext3 2026-09-20 (aria c141)

First long freeze caught LIVE at fine cadence (freeze-watch v1.0 +
5-min census + manual probes). The falsifier from c140 ran and the
heal mechanism is now OBSERVED, not inferred.

## Timeline (all UTC; frigate container logs are LOCAL -03)

- 04:24Z  first .103 dial WRN (i/o timeout, producer.go:170). Dial
  failures continue: 10 distinct failed-dial ports by 06:16Z.
- 05:10-05:40Z  ext3 live conn churns 43290 -> 53284 -> 39622 -> 55460
  (3 swaps in 30min -- successful dials interleaved with failures).
- 05:39:32Z  recordings lose audio (last audio seg 05.39.32.mp4,
  verified by ffprobe per-segment scan; hour-05 segcensus row 248/77
  consistent). Video keeps flowing.
- 05:40:00Z  census first FROZEN row (caught onset within 30s).
- 06:16:19Z  recordings audio returns (seg 06.16.19.mp4).
- 06:16Z  producer remade 5210 -> 5290, new conn 49948 replaces 55460.
- 06:20:00Z  census HEALTHY (373 audio frames).

Freeze duration ~37min. Heal = producer remake + conn replacement.
CONFIRMS c140 long-freeze class (heal = conn replacement, 5/5 now).

## New data beyond c140

1. DIAL-FAILURE STORM PRECEDES THE FREEZE. The camera's RTSP server
   (thingino prudynt) was failing i/o-timeout dials from 04:24Z --
   75 minutes BEFORE the live conn's audio died. Fleet-wide in this
   window: .104=100 WRNs, .103=32, .105=32, .201=28 (2h). But only
   ext3/int1/ext4 froze. Dial failures = camera degradation signal;
   freeze needs the live conn's audio track to die on top.
2. RSSI FLAT (-56..-58 .103, -51..-52 .201) and no RSSI gaps (no
   reboots). Not signal, not power. Ping jitter high fleet-wide on
   interior cams (60-95ms avg) but that is chronic, not new.
3. SDP still advertises audio during the freeze (m=audio track2 in a
   fresh DESCRIBE). Camera CLAIMS audio it is not sending on the
   established conn. SDP-ADVERTISED != PACKETS-FLOWING (law-50 member,
   now with a live receipt).
4. go2rtc receiver counters froze too: aac bytes 23354 packets 89,
   delta 0 over 20s+ while hevc climbed. The receiver KNEW audio was
   dead. An instrument candidate: receiver-delta probe = producer-side
   freeze detector (no tcpdump needed).
5. PRODUCER-ID CHURN: go2rtc producer ids changed for int1 (5229 ->
   5233 -> 5284), ext4 (5213 -> 5279), ext3 (5210 -> 5290) within
   ~15min. Producer id is NOT a stable handle; conn port (conn-breakdown)
   remains the primary conn-age witness. c140's "producer id change =
   remake" inference survives but ids churn more than assumed.
6. CORPSE-CONN LAG STRIKES AGAIN (v1.1 known): at 06:16:20Z the census
   sampled ONLY the corpse conn 55460 (old producer dead, new conn
   49948 not yet established at sample instant) -> FROZEN row for a
   camera that was healing. FROZEN rows within ~1-2min of a heal can
   be corpse-stale. Cross-check recordings before verdicts.

## What remade the producer at 06:16Z?

Unknown. No frigate-side log events for ext3 (no watchdog, no
consumer restart). go2rtc logs only WRN+; no INF. Candidates:
go2rtc-internal producer watchdog, or a silent frigate ffmpeg
consumer reconnect (frigate pulls 8554 restream). The #2505 family
behavior (consumer GET remakes producer) is one candidate. OPEN.

## Instrument notes

- freeze-watch v1.0 had a slot-arithmetic bug (guard/sleep fight ->
  infinite sleep loop); fixed to sleep-to-slot-60. One-shot ephemeral,
  not deployed as a service.
- ffprobe path in frigate: /usr/lib/ffmpeg/7.0/bin/ffprobe (NOT in
  PATH; `podman exec frigate ffprobe` fails).
- Frigate recording dirs are UTC-NAMED (hour 05 dir = 05:00-05:59Z);
  mtimes are LOCAL -03. THREE-CLOCK law: dir name is a claim, mtime is
  ground truth, census epoch is UTC. Cross-check before joining.

## Next

- The dial-failure storm as an EARLY WARNING: if WRN rate precedes
  freezes by ~1h, a WRN-rate alarm could predict freezes. Needs the
  WRN-rate series (frigate journal is unreliable under flood; the
  container log grep works). Candidate: hourly WRN-rate puller.
- Who remakes the producer? Next live catch: watch frigate ffmpeg
  consumer state (ps inside container) at 1-min cadence through a
  heal to see if a consumer restart precedes the remake.
