# EXT2 AUDIO ROOT CAUSE (c345, 2026-09-15 ~01:35Z): the audio freeze lives in go2rtc's STALE PRODUCER SESSION

## The decisive experiment

A FRESH RTSP session to .102 ch0 (ffprobe + 8s ffmpeg -c copy from
sophon) carries BOTH video and audio DATA: 126 audio packets + 40
video packets in 8s. The camera is fine. The camera sends audio to
anyone who asks.

go2rtc's LIVE producer session for exterior_2 (id 95255,
rtsp://...192.168.2.102/ch0, rtsp+tcp) shows:

- receivers.video: bytes/packets INCREASING (265.9MB / 265811 pkts
  at 01:36Z, growing ~1000 pkts/min)
- receivers.audio: bytes/packets FROZEN at exactly 7846778 bytes /
  28708 packets across every probe 01:32-01:37Z (and presumably
  since the 09-14 15:34:07 segment transition)

The consumer side (Frigate's record proc ffmpeg, user_agent
"FFmpeg Frigate/0.17.2") gets whatever go2rtc forwards: its senders
show audio frozen at 12385657 bytes / 45374 packets too. The record
proc is faithfully recording a stream that no longer carries audio.

## Why it never self-heals this time

go2rtc auto-reconnects a producer when its TCP control channel
errors (i/o timeout). The 09-08 episode healed because the producer
session died and reconnected. THIS time the TCP channel to .102
stayed healthy (video RTP keeps flowing through it), so no error
fires, no reconnect happens, and the audio track inside the session
is dead forever. The 09-08 "self-heal" was a producer RECONNECT,
not an in-session renegotiation.

Evidence for the stale session: exterior_2's producer id is 95255,
LOWER than exterior_1 (102689) and exterior_3 (103180) -- both of
which reconnected during the 09-14 22:00-22:34 i/o-timeout bursts.
exterior_2's producer predates those reconnects and predates the
15:34 audio drop.

## Why the class-3 prediction missed

"Next record-proc restart heals ext2 audio" was falsified by c341
(no restart at the 15:34 boundary). The corrected mechanism: the
drop is a per-SESSION audio-track death inside go2rtc's producer,
not a record-proc negotiation failure. It heals only when the
producer session is replaced (reconnect or go2rtc restart).

## The fix (filed, not executed -- Nacho's service)

Any of these replaces the stale session and should restore audio:
1. `podman restart frigate` (heaviest, Nacho's call)
2. Restart just go2rtc inside the container (s6: `s6-svc -r
   /run/s6-rc/servicedirs/svc-go2rtc` or equivalent)
3. go2rtc API config reload: PATCH /api/streams?src=exterior_2
   (recreates the stream object; lightest touch)

Filed as relay request (nacho-security class is wrong; this is
ours-direction for the DECISION but the action touches his service
-- filed nacho-external as "physical/service action needed").

## Falsifier for the model

After any producer replacement: receivers.audio bytes start
climbing from 0, and ext2 segments flip back to video+audio within
one segment (~15s). If a fresh producer session STILL shows frozen
audio while fresh ffmpeg probes carry audio, the model is wrong
(the freeze would be in go2rtc's audio demux path, not the
session).

[EXTERNAL DATA]: none -- house-internal (go2rtc API, frigate
container, fresh RTSP probes).