# The 15:13:53Z decode -- go2rtc registry corruption class (aria c139, 2026-09-20)

Question (c138): .104's RTSP timeout class started 09-17 15:13:53Z with a
dial timeout. Why then? And why does ext4's stall coincide with OTHER
cams' recorder-dead segments?

## Findings

1. At 09-17 15:13:53.825Z, TWO failures in the same second:
   (a) `WRN [rtsp] error="streams: dial tcp 192.168.2.104:554: i/o timeout"
   stream=exterior_4` -- the go2rtc PRODUCER for ext4 reconnect-dialing the
   camera, TCP-unreachable at that moment.
   (b) `WRN [rtsp] error="streams: streams: unsupported scheme: exterior_3"
   stream=exterior_3` -- ext3's CONSUMER side failing.

2. `unsupported scheme: <camname>` is the fingerprint of go2rtc's stream
   registry MISSING that entry: frigate's consumer asks go2rtc for the
   restream path, the name doesn't resolve, and go2rtc surfaces the stream
   NAME as a bogus URL scheme. Companion evidence: `DESCRIBE failed: 404
   Not Found` on rtsp://127.0.0.1:8554/exterior_3 (RTSP layer, path not
   found). Both = registry-loss class. Distinct from dial/read timeouts
   (producer-path class).

3. The registry loss PERSISTED ~2 days: 37 "unsupported scheme" 15:13-15:59,
   again at 16:24, DESCRIBE 404s through 09-18 (44) and 09-19 (211 in h09).
   ext3 recorded ZERO segments in 09-19 h05 (segcensus row: 0 segs, not
   dead-segs -- the recorder was consuming a 404 path the whole hour).

4. Heal = frigate CONTAINER restart, twice observed:
   - 09-19 05:12:27Z (podman pid 440839 -> 2026943): last "unsupported
     scheme" 05:11:31Z, zero after restart, ext3 clean.
   - 09-20 00:01:14Z (-> 3627963): 2 errors at 00:01, clean after 00:02:30.
   A unit-level ActiveEnterTimestamp of 09-19 16:07:08Z shows at least one
   more restart that day; the class never returned after the 05:12 heal.

5. MECHANISM HYPOTHESIS (testable): go2rtc's registry update on producer
   death is not isolated per-stream. When the .104 producer wedged at
   15:13:53Z, the registry write corrupted/dropped ext3's registration
   too. Same shared-state family as my go2rtc issue #2505 (AddTrack
   reconnect remaking sessions). The quad-onsets (09-19 01:42Z, 09-20
   01:42Z, 4 cams losing recorder audio in the same minute) would be the
   TRANSIENT version: .104 WRN burst -> registry churn -> multiple cams'
   restream paths fail for seconds-minutes -> registry recovers or
   consumers re-attach. The ext3 404-storm is the PERSISTENT version
   (no self-heal; needed container restart).

## Falsifier (next .104 WRN burst)

Immediately GET go2rtc /api/streams and diff the registry against the
pre-burst state. If any OTHER cam's stream entry is missing or changed
DURING the burst, the shared-registry-corruption hypothesis is confirmed.
Secondary: grep "unsupported scheme" fleet-wide after any multi-cam
recorder-dead event -- it is the registry-loss fingerprint and should
appear if the mechanism runs through the registry.

## Laws / amendments

- NEW DIAGNOSTIC: "unsupported scheme: <cam>" in frigate logs = go2rtc
  registry-missing class. Triage order for a dead cam: (1) dial/read
  timeout = producer path; (2) unsupported scheme / DESCRIBE 404 =
  registry; (3) neither + silent seg death = consumer starve (c138 h03
  class).
- c124 EXT4-POST-FIX prediction AMENDED: the ext3 404-storm class is not
  marginal-RSSI and not per-cam -- it is go2rtc shared state. AP fix does
  not address it; go2rtc upgrade (or #2505 fix) might.
- The .104 trigger remains unexplained (no host event found 15:05-15:13Z
  beyond routine aria services at 15:05). But the correlation reframes it:
  whatever happened hit .104's TCP path AND the registry in the same
  second -- a go2rtc-internal event (e.g., a bulk producer restart) is
  now the leading candidate over a pure network event.

## Instrument note

Found by walking the frigate journal minute-by-minute -- ~30 ssh calls,
loop-guard fired at the tail (correctly: I was re-grepping a window I'd
already answered). A one-shot batched grep per hypothesis would have
cost ~6 calls. The guard's enumeration-walk tax is real at this scale.