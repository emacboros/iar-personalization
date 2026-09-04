# ext4 audio loss + SELF-HEAL -- 2026-09-03/04 (cycle 3, flash)

Follow-up to c2's flag 367 (NEW deafness exterior_4, boundary
23:53:48 UTC Sep 3). This cycle: quiet-system full walk, packet
counts, producer state. The headline: **ext4 self-healed at
~00:24-00:29 UTC Sep 4** -- no frigate restart, no intervention.
Flag 367 is RESOLVED; withdraw via for-nacho follow-up next cycle.

## Verified timeline (UTC; frigate container logs are UTC-3 --
## convert before correlating, this bit me mid-analysis)

- 23:33-23:39 Sep 3: rolling camera reboot (turn 168).
- 23:47:21 - 23:50:51: SIX go2rtc WRN read-timeouts on
  192.168.2.104 (ext4) -- camera RTSP session unstable.
- 23:47-23:53: flappy recordings. 37 segments in 7 min vs 27
  normal; 1-1.2s segments with 16-19 audio packets interleaved
  with normal 16s/250-packet segments.
- Packet ramp (the decay, -count_packets): 50.01=108, 50.18=248,
  51.06=541, 51.45=611, 52.18=326, 52.37=250, 52.50=250,
  53.06=144, 53.35=4, 53.37=19, 53.38=4. >250 = duplicated/
  interleaved audio during renegotiation; 4-19 = dying.
- 23:53:22: go2rtc WRN read-timeout on .104 -- 16-26s BEFORE the
  boundary. The producer's read loop died first.
- 23:53:38-48: last aac (53.38) -> first video-only (53.48).
  c2's boundary CONFIRMED by full walk, no islands, monotone.
- 00:13-23.56 Sep 4: video-only, recordings CONTINUOUS (video
  never broke; 204 segs, no gaps).
- 00:24:12: first recovered aac (1 packet), 24.29=19, 25.03=250
  (full). go2rtc WRN read-timeouts 00:24:25, 00:28:09, 00:28:54
  -- the reconnect that healed it.
- 00:29:54 UTC (21:29:54 container): LAST ext4 watchdog line.
  Frigate never restarted ext4's ffmpeg around the recovery.
- 00:50:57: fleet-check ear check: ext4 FLOWING (-49.7/-33.2 dB).
- 00:59:40: volumedetect on newest segment: mean -47.8, max
  -32.5 dB -- real signal, not a hollow track.

## Verdict

Renegotiation-class death (e2/int3 class), CONFIRMED with packet-
level detail. Camera reboot -> reconnect churn (read-timeouts,
flaps, packet ramp) -> audio track lost mid-renegotiation at
23:53:48 -> producer SDP kept offering audio (codec-presence law)
-> ~31 min later the producer's own read-timeout forced a
reconnect -> new receiver -> audio back. The heal lever is the
producer reconnect; ext4 got one for free because its session was
sick enough to time out.

## The new mechanism insight (law-material)

**The healer is the producer read-timeout.** A zombie session
(video flowing, audio dead) never times out, so it never heals:
ext2 ~20h deaf, int3 silent-for-days, both with alive TCP and
flowing video. ext4's session degraded until the read loop timed
out and re-dialed. Flag 326 (frigate restart to heal e2/int3) now
has a positive control: ext4's recovery is exactly the mechanism
the restart would force. The restart remains Nacho's call.

## ext4's other Sep-3 events (context, not fully reconstructed)

- Audio loss #1: 04:23-04:27 UTC (hour 04 boundary 22.59->23.22).
- Recovery #1: 16:41-16:57 UTC (hour 16 boundary 32.41/32.57).
  Mechanism unknown; producer generation unknown (producer-id
  law: I only have the current generation, 6824, born ~23:33-39
  with the reboot). Frigate restart storm at container 16:38-46 =
  UTC 19:38-46 does NOT match this recovery.
- Video island: 19:27-19:37 UTC (10 min, video-only while
  surrounded by aac; camera-side outage, matches nothing in
  go2rtc logs I pulled).
- ext3 unrelated: camera unreachable ~16 min, 18:10-18:26 UTC
  (go2rtc dial timeouts 15:10-15:26 container TZ). ext3 hour-18
  recording state unchecked. Separate event, same day, same
  corner of the network as the rolling reboot.

## Method notes (next instance pays zero)

- ffprobe -count_packets is the sharpest decay witness: 250 =
  healthy (16s seg), 4-19 = dying, 541-611 = renegotiation
  duplication, 1 = hollow (int3 signature).
- Segment-name density is the flap witness: >4 segs/min = churn.
- go2rtc WRN lines are CONTAINER TZ (UTC-3); recordings are UTC.
  I nearly mis-correlated the 20:53 WRN with the 23:53 boundary
  before checking -- they are the same event (20:53 -03 = 23:53
  UTC). Always convert before correlating.
- The full-hour walk with transition-only printing (prev-state
  compare) is ~1 ssh and finds every boundary without parser
  assumptions -- the c2 basename-parser bug class stays dead.