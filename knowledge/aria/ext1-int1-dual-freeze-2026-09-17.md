# ext1 + int1 simultaneous audio freezes -- 2026-09-17 ~23:40 UTC (cycle 36)

## What happened tonight

TWO cameras froze audio at nearly the same time, on DIFFERENT producer
connections, with go2rtc holding both connections alive:

- **ext1 (.101)**: audio died 22:37:41Z (seg boundary, hour-22 dir:
  00.11-37.41 alive, 37.41+ dead; hour-23 dir ALL 150 segs dead and
  counting). ch2 census FROZEN rows from 22:40Z onward, continuous
  through 23:40Z. Producer id 15 (born ~21:52Z), STILL the same
  producer at 23:40Z. API packet-delta 23:31-23:32Z: hevc +179/20s
  (video FLOWING), aac +0/20s (audio DEAD). No WRN for .101 since
  18:00:17Z. This is MECHANISM 2: track death on a LIVING conn, no
  re-dial, now 60+ minutes.
- **int1 (.201)**: audio died ~23:02:25Z (hour-23 seg boundaries:
  DEAD 02.25-05.55, ALIVE 05.55-06.27, DEAD 06.27-06.38, ALIVE
  06.38-12.55, DEAD 12.55-33.49, ALIVE from 33.49). Producer 461 ->
  617 replaced somewhere in there (producers.log 22h row still said
  461; API at 23:36Z says 617). API 23:31-23:32Z: hevc +570/30s,
  aac +0/30s (audio dead on conn 461). At 23:36Z producer 617 has
  aac 1045 pkts (new conn, audio flowing again). ch2 census: FROZEN
  23:05-23:30Z, alive row 23:35Z (175/206). Self-healed via
  producer replacement -- the usual int1 pattern (chronic churn +
  track-death healing by replacement).

## The new fact: SIMULTANEITY

Two cameras, two separate producer connections, audio dead in the
same 25-minute window (ext1 22:37Z, int1 23:02Z). ext1's death was
FIRST, ~25 min before int1's. If this were pure per-camera prudynt
flakiness, the coincidence is unexplained. Candidates:

1. **Chance**: int1 has ~100 stalls/day (its normal churn); ext1's
   track death is rarer. Two independent events 25 min apart --
   possible but the window is suspicious.
2. **Shared infrastructure between the two**: both are on the same
   AP? Both wifi. A wifi-side event (channel change, AP reboot,
   interference burst) could hit multiple cameras without killing
   TCP (the conns stayed alive -- that is the signature: TCP alive,
   track dead).
3. **Common cause upstream of both**: the switch/AP or power.
   But video kept flowing on both, so it was not a link-level event.

## The ch2-census sample-error class (IMPORTANT instrument finding)

Tonight the census produced rows that are WRONG as "ground truth":

- ext1 22:10-22:35Z rows: ch2=1..12 with segs FULLY ALIVE (audio
  flowing in recordings 22:00-22:37). The 20s capture anchored on a
  near-end-of-stream position or caught a partial window: counts
  tiny but nonzero, then 0 at 22:40Z (true death).
- ext2 22:00-22:20Z rows: ch2=14..36 with segs 225/225 ALIVE and
  API aac packets flowing (99157 -> 99468 in 15s at 23:40Z). Same
  low-count artifact. ext2 audio NEVER died; the census read low.
- int1 23:10Z row: ch2=211, ch0=0 -- the INVERSE pattern (audio
  counted, video zero) while segs were ALIVE 23:06:38-23:12:55.
- int3/ext3/ext5: partial rows (160, 172, 121) while segcensus says
  those hours fully or mostly alive -- partial-hour reads.

PATTERN: low-but-nonzero rows (1-100) appear at times when the
segs say audio was HEALTHY. The census's 20s capture + anchor walk
is sampling a 20s window of a 5-min interval; a capture that starts
near a track transition, or a capture whose TCP reassembly lost
segments (tcpdump drop under load), reads partial. **A low row is
NOT a freeze claim. Only ch2=0 with FROZEN flag (anchored walk,
zero ch2) is a freeze claim, and even that needs the API packet
cross-check before it becomes a mechanism claim.** This extends
the c34 census-sample scar: rows are samples; the API is the
confirming instrument; segcensus is the hour-level ground truth.

## Reading law for tonight's events

- ext1 freeze: REAL (ch2=0 FROZEN rows 22:40-23:40Z + segcensus
  hour-22 row 84/225 dead + hour-23 150/150 dead + API aac flat).
  Mechanism 2, ongoing at cycle close.
- int1 freeze: REAL (segs + API + census agree), self-healed by
  producer replacement (461 -> 617) between 23:30-23:36Z.
- ext2 low rows: ARTIFACT (API packets flowing, segs alive).
- The producers.log "audio-yes" for ext1 22h row is the KNOWN
  SDP-ADVERTISED != PACKETS-FLOWING trap (v1.2 stale flag only
  fires when segcensus says dead -- it did: 84/225. Check whether
  the STALE-MAJ flag fired on that row).

## Next falsifier for ext1 (if still frozen next cycle)

Producer 15 has been alive since ~21:52Z with aac frozen since
22:37:41Z. If it is STILL frozen at next cycle with no WRN and no
producer replacement, that is a >2h mechanism-2 event on ext1 --
the c33/c34 disease shape on a camera that previously only did the
ext3-style hours-long freeze (c28). The heal will come from a full
stall (read-timeout WRN -> producer replacement) or a frigate
restart. Watch: does the watchdog eventually fire?

## Cross-camera freeze timeline today (UTC)

- 03:54-10:16Z ext1 audio freeze (c20's 6h22m, healed by producer
  replacement + watchdog)
- 16:44Z+ ext3 frozen (c28), 17:15Z+ ext5 frozen (c28)
- 22:37:41Z ext1 audio freeze (THIS EVENT, ongoing)
- 23:02:25Z int1 audio freeze (THIS EVENT, self-healed ~23:33Z)
- ext2 22:00-22:20Z low rows = artifact, not freeze
## Addendum (23:43Z): ext1 still frozen at cycle close

- Producer 15 unchanged, aac pkts 39723 FLAT (23:31Z, 23:36Z, 23:42Z,
  23:43Z checks), hevc growing. 65+ min of mechanism-2 on ext1, no
  WRN, no watchdog, no heal. ext1's detect ffmpeg restarted at
  18:54Z (its own crash class) but the AUDIO freeze does not trip
  the detect watchdog -- detect consumes video only. The recorder
  ffmpeg (audio-bearing) is the one that would notice, and its
  watchdog has not fired. Falsifier for next cycle: does the ext1
  freeze heal via (a) full-stall WRN + producer replacement, (b)
  recorder re-attach, (c) nothing until intervention?
- STALE-MAJ correctly did not fire on the ext1 22h producers.log row
  (84/225 = 37% < 50% threshold). The v1.2 flag logic is fine; the
  row is honest (audio-yes is what the SDP says).
- int1 heal CONFIRMED: producer 617, aac 1045 pkts at 23:36Z and
  hour-23 segs alive from 33.49 onward.
