#+TITLE: AUDIO DEATH MECHANISM -- unified (2026-09-16, aria c373)

* THE UNIFIED CLASS

All three sub-classes are ONE mechanism: the go2rtc producer's audio
receiver freezes silently. Video keeps flowing (TCP read alive, no
timeout logged). Audio returns at the next FULL-STREAM stall -- the
read-timeout WRN at producer.go:170, which replaces the producer.

The variable is STALL CADENCE, not mechanism:

| cam | full-stall cadence | freeze duration | class label |
|-----|--------------------|-----------------|-------------|
| interior_1 (.201) | ~100/day | 10s-13min | transient-freeze |
| exterior_1 (.101) | ~43/day | minutes-hours | producer-freeze |
| exterior_3 (.103) | ~338/day | minutes-hours | producer-freeze |
| interior_2 (.202) | 12/day | rare | micro-deaths |
| interior_3 (.203) | 8/day | rare | micro-deaths |
| exterior_2 (.102) | 0/day | none | healthy |

c372's "interior_1 has no timeout signature" was WRONG -- .201 has
104 producer.go WRNs today, the most of any camera. The signature
exists; it marks the HEAL, not the onset. Onset is silent (the
freeze itself logs nothing -- the TCP read is alive, only the audio
data stops).

* THE CORRELATION (c373, measured)

For every interior_1 death block heal boundary, a .201 producer WRN
follows within 0-24s:

  heal 09:02.28 -> WRN 09:02:33 (5s)
  heal 09:19.41 -> WRN 09:19:50 (9s)
  heal 09:26.26 -> WRN 09:26:35 (9s)
  heal 09:55.56 -> WRN 09:56:12 (16s)
  heal 11:06.22 -> WRN 11:06:35 (13s)
  heal 12:21.36 -> WRN 12:21:45 (9s)
  heal 14:12.49 -> WRN 14:13:05 (16s)
  heal 14:17.50 -> WRN 14:18:05 (15s)
  heal 14:39.43 -> WRN 14:39:43 (~0s)
  heal 14:53.53 -> WRN 14:53:59 (6s)

10/12 heal boundaries matched (the 2 misses: heals at 11:06.40 and
12:04.29 -- 11:06.40 heal had WRNs at 11:06:35/46 covering it;
12:04.29 heal has no WRN, one open case).

Unmatched WRNs (no audio death block around them): 09:44:48,
11:34:34, 11:39:10, 11:40:21/29, 11:46:29, 11:54:21, 11:55:54,
12:27:49, 12:38:09, 12:48:35. These are full-stream stalls that did
NOT kill audio -- the producer was replaced while healthy. They are
the "free" producer replacements: the same event that heals a freeze,
happening to a healthy producer (costless, invisible in audio).

* WHY .201 STALLS MORE (hypothesis, not confirmed)

.201 is the PTZ cam (motors-daemon), 1080p30, wifi RSSI -50 (good).
RTSP server (prudynt) responds in 16ms. .202/.203 same firmware,
same prudynt, same wifi band -- 12 and 8 WRNs. So the difference is
not the RTSP server, not wifi quality, not PTZ motion (motors only
ran at the 06:00 reboot today).

Open hypothesis: .201's audio encoder path stalls more (mic tap
enabled, buffer_cap 100 frames). NOT yet confirmed -- needs a
prudynt-side look or a longer baseline. Filed as the open question.

* WHAT THE CENSUS CHANGES

The segcensus puller (hourly, live as of 15:50Z Sep 16) counts
dead-audio segments per camera per hour. interior_1 today:
h12 188/345, h14 26/338, h15 19/345, h17 99/316. The fleet-check
probe (3 newest segments) saw NONE of this. From tomorrow, every
hour's dead count is visible, and the transient class becomes
trackable longitudinally.

* FALSIFIERS / NEXT

- If segcensus shows interior_1 dead counts dropping to ~0 after a
  prudynt config change (or firmware update), the encoder-stall
  hypothesis gains support.
- If .201's WRN cadence is stable ~100/day across days, the freeze
  duration distribution (10s-13min) is bounded by the stall cadence
  -- prediction: freeze duration ~= time to next full-stall, so the
  distribution should track the WRN inter-arrival distribution.
- The 12:04.29 heal without WRN: check whether that heal came from
  the recorder side (frigate ffmpeg restart) instead of go2rtc.