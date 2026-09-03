# Audio loss Sep 3: the loss point is CAMERA-side RTP emission

Written 2026-09-03 ~06:40 UTC, cycle 8. Status of flag 262/265:
loss live ~2h15m at time of writing (cuts 04:23-04:27 UTC).

## The question this settles

Cycle 6 established: go2rtc producer aac receivers frozen, video
flowing, cameras still carry aac on FRESH sessions. Two candidate
culprits remained: (a) camera stopped sending audio on the
EXISTING session, (b) go2rtc receiver stopped processing it.
This cycle discriminated: **(a). The cameras stopped sending.**

## The discriminator: interleaved-frame walk on 20s pcaps

Transport is TCP-interleaved RTSP (port 554; UDP produced almost
nothing). Method: tcpdump -s 320 on the camera-side leg, reassemble
TCP streams by seq, walk the `$`-interleaved frames, count channel
IDs. RTSP interleaved channels: 0=video RTP, 1=video RTCP,
2=audio RTP, 3=audio RTCP.

Results (2026-09-03 ~06:36-06:38 UTC, 20s per camera):

| camera | stream | ch0 (video) | ch2 (audio) |
|--------|--------|-------------|-------------|
| 192.168.2.101 (exterior_1, HEALTHY) | 147KB | 6.3KB | **3552B, 13 frames** |
| 192.168.2.102 (exterior_2, DEAF) | 47KB | 13KB | **0 frames** |
| 192.168.2.103 (exterior_3, DEAF) | 44KB | 11.5KB | **0 frames** |
| 192.168.2.104 (exterior_4, DEAF) | 36KB | 16.7KB | **0 frames** |

The healthy camera shows audio RTP flowing; the three deaf ones
show video only, on the same long-lived sessions, with no TCP
teardown and no renegotiation. go2rtc's aac receivers are simply
starved. Camera map (config.yaml order): 201/202/203=interior_1/2/3,
101=exterior_1, 102/103/104=exterior_2/3/4, 105=exterior_5.

Parser honesty note: my walker also reported bogus large channel
IDs (130, 252, 195...) -- those are desync artifacts inside video
payloads, not real channels. Real signal = presence/absence of
channels 0-3. The absence of ch2 on all three deaf cameras while
the healthy control shows it is the finding; the noise channels
are irrelevant to it.

## The upstream prior (GitHub, 2026-09-03, [EXTERNAL DATA])

prudynt-t (the RTSP server in thingino firmware) has a documented
history of exactly this class: session alive, audio silently dead.

- themactep/thingino-firmware#1462 (closed 2026-08-13): "RTSP
  client that subscribes to only the audio track gets no audio at
  all -- prudynt's drain loop skips the session ... PLAY returns
  200 OK, RTCP flows, and the stream stays silent forever."
  Root-caused by viliampucik, two patches, merged upstream as
  themactep/prudynt-t#30, version bumped same day.
- gtxaspec/prudynt-t#51: "reset audio state on deconstruction" --
  audio state hygiene across session lifecycles.
- gtxaspec/prudynt-t#74 (OPEN, updated 2026-04): audio RTP
  timestamp rate noncompliance (90kHz) -- pending spec-level fix.

So: fresh sessions work (cycle 6), long-lived sessions lose audio
emission (this cycle), and the RTSP server in this firmware has
shipped silent-audio state bugs before. Camera-side session-state
decay is the leading hypothesis; a common trigger at ~04:25 UTC
hitting only ext2/3/4 (cuts minutes apart despite different
session ages) is the unexplained residue. NOT resolved: why those
three, why then.

## What follows operationally

- Lever to restore audio NOW: fresh go2rtc producer sessions =
  frigate container restart (flag 265 correction stands). Restores
  audio until the decay recurs (hours?) -- it is a palliative.
- Real fixes, in order of permanence: (1) camera firmware update
  if a prudynt fix landed after the cameras' build; (2) a watchdog
  that detects NO-AUDIO on newest segment and resets the affected
  camera's RTSP session (targeted, not fleet-wide); (3) upstream
  bug report with the pcap evidence.
- Watch next: does the decay recur after any restart? Recurrence
  interval = the data that separates one-off from systemic.

## Method notes (so next cycle pays zero)

- tcpdump on sophon enp10s0, filter "host <cam> and port 554",
  -s 320 is enough for interleaved headers + some payload.
- Reassembly: sort by seq, concat payloads, walk 0x24 frames.
  Naive but adequate for presence/absence of channels 0-3.
- go2rtc producer receiver deltas (machinectl recipe in
  go2rtc-rootless-access.md) remain the fastest live check;
  the pcap walk is the deep probe when the counters are ambiguous.