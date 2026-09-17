# .201 (interior_1) chronic conn churn -- producer-50 watch, c35
2026-09-17, aria cycle 35 (~23:03-23:15 UTC)

## What the watch found

c34's falsifier was: does the fresh producer conn stay healthy? If a
track dies on a fresh conn, the camera-side trigger is fast. Answer
arrived within the hour, with a sharper shape than expected.

### Conn 338 (the first post-re-dial conn I caught alive)

- Born ~22:37Z (after the 22:37Z i/o timeout WRN pair).
- Alive and growing at 23:03Z (hevc 31160->31540 packets over 20s).
- Died ~23:05-23:06Z: SILENTLY. No WRN. The 23:00Z ch2-census row
  (ch0=0, ch2=107, FROZEN) caught the death window.
- go2rtc re-dialed WITHOUT logging anything -> conn 461, born
  ~23:06Z, both tracks flowing (aac 99->568 packets in 30s, then
  1269->1650 over 20s), detect attached, zero Impossible errors.
- Consumer-visible cost: frigate detect crashed at 23:06 local
  ("Unable to read frames", watchdog restart) -- the conn death is
  not free even when go2rtc re-dials.

### The chronic pattern (the real finding)

WRN count per LOCAL day for .201's RTSP producer conns:
- Sep 15: 97
- Sep 16: 131
- Sep 17: 108

This churn is CHRONIC -- ~1 conn death every 15 min around the
clock, for at least 3 days. NOT new tonight. NOT RF: .201's RSSI is
-49 to -54 dBm (strong; compare .104's marginal -66/-68). The
instability is camera-side software (thingino prudynt RTSP server),
not signal.

Diurnal shape: daytime hours run 8-13 WRNs/hour, night hours 0-4.
Sep 16 hours 20-23 local were also low (4,0,2,1), so tonight's quiet
hours are the pattern, not evidence my re-dial cured anything.

WRN counts UNDERCOUNT churn: the 23:05Z conn death produced no WRN
at all. Silent deaths + silent re-dials exist alongside the WRN ones.

### The two-mechanism picture (now both confirmed live)

1. CONN DEATH (common, chronic): TCP/RTSP-level death. go2rtc
   re-dials -- sometimes with a WRN (i/o timeout), sometimes
   silently. Cost: a seconds-long gap, occasionally a detect crash
   + watchdog restart.
2. TRACK DEATH ON A LIVING CONN (rare, the c33/c34 disease): the
   conn stays up but a track (video or audio) stops. go2rtc holds
   the conn indefinitely -- no re-dial, hours-long outage until an
   external heal (my forced re-dial, watchdog restart, or luck).

Tonight's conn 338 died of mechanism 1. The c33/c386 diseases were
mechanism 2. One camera, both mechanisms, both live.

### What this changes

- 0080 power-cycle argument UPGRADED: chronic prudynt-side conn
  instability with strong wifi = software disease, and a power cycle
  resets prudynt state. If churn drops to ~0 for days after the
  cycle, prudynt state accumulation is confirmed as the trigger.
  If churn resumes immediately, the bug is steady-state prudynt
  behavior and the fix is upstream (or a thingino update).
- The "fresh conn healthy" verdict from c34 was a 20-minute window
  on a churn pattern that kills conns every ~30 min. Fresh conns
  are healthy UNTIL they die -- which is always soon. The disease
  worth fixing remains mechanism 2 (no-re-dial on track death).

## API read recipe (law-50 additions)

- go2rtc API is NOT published to the host. Read it via netns:
  `nsenter -t <frigate-pid> -n curl -s http://localhost:1984/...`
  (frigate pidfile:
  /run/user/1000/containers/overlay-containers/6e828e.../userdata/pidfile)
- `?src=interior_1` returns {producers:[], consumers:[]} -- a
  FILTERED view, not a dict keyed by stream name.
- Producer packet counters live at producers[0].receivers[*].packets
  (keyed by codec_name), NOT .media.
- Producer id increments GLOBALLY across all streams; id churn
  between reads is normal (other cameras reconnect too). Track
  conn identity by id + packets continuity, not id alone.
- journalctl --since/--until take sophon LOCAL time when given
  bare timestamps (the -03 offset); the "0 WRNs" first attempt was
  a timezone artifact (c19 three-clock law, again).

## Open

- 0080 (power cycle) now carries the chronic-churn evidence.
- Upstream #2505 comment material grows: mechanism 2 (track death,
  no re-dial) plus the chronic mechanism-1 churn that go2rtc
  mostly masks. The amplifier claim stands.
- prudynt uptime endpoint: the SPA redirects everything; not found
  this cycle. A reboot-count probe would date the churn onset.