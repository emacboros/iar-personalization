# DRAFT go2rtc upstream issue -- DO NOT POST without Nacho's eyes
# Drafted c272, 2026-09-13 ~00:30 UTC. Relay-file for ratification (nacho-external).
# Every claim below was verified against source at v1.9.10, v1.9.14, and master
# (raw.githubusercontent.com, 2026-09-13 ~00:25-00:30 UTC). Reproducer is our
# production frigate 0.17.2 chain; the wave evidence is our own fleet telemetry.

## Title

GET /api/streams with `microphone` param reconnects every playing RTSP
producer whose SDP has sendonly audio (AddTrack has no already-matched
dedup, unlike GetTrack)

## Summary

A metadata probe GET -- the exact request frigate 0.17.2's live page
issues for every restreamed camera on load
(`/api/go2rtc/streams/<cam>?src=<cam>&video=all&audio=all&microphone=`)
-- forces a FULL RTSP session remake (TEARDOWN + DESCRIBE + SETUP +
PLAY) on every playing RTSP producer that advertises sendonly audio
(backchannel/speaker) in its SDP. On a multi-camera system, one page
load remakes every camera's session in the same second; downstream
consumers (frigate's ffmpeg record/detect processes) see the session
die and restart fleet-wide ~20s later.

The asymmetry that causes it: `Conn.GetTrack` dedups existing receivers
by pointer equality (`pkg/rtsp/producer.go`), so a probe asking for
tracks the producer already serves returns them without touching the
connection. `Conn.AddTrack` (the backchannel path,
`pkg/rtsp/consumer.go`) has NO equivalent dedup over `c.Senders` -- any
match against a sendonly producer media while `state == StatePlay`
unconditionally calls `Reconnect()`, even if the identical backchannel
track was already set up by an earlier probe.

## Reproducer

- go2rtc with an RTSP producer that has BOTH recvonly audio (camera
  stream) and sendonly audio (speaker/backchannel) medias -- typical
  for cameras with two-way audio support (we see it on thingino
  cameras: SDP carries `audio, recvonly, MPEG4-GENERIC/16000` plus
  `audio, sendonly, MPEG4-GENERIC/16000|PCMU|PCMA`).
- A playing consumer on that stream (frigate ffmpeg via go2rtc restream).

Then:

```
curl "http://go2rtc:1984/api/streams?src=<cam>&video=all&audio=all&microphone="
```

Observed: producer's RTSP session is remade (new session on the
camera, `RTSP reconnect` event, existing consumers' streams break and
restart). Repeating the GET repeats the reconnect -- there is no
state that makes a second probe idempotent.

The same GET WITHOUT the `microphone` param does NOT reconnect: the
video/audio probe medias hit the `GetTrack` pointer-equality dedup
(both at the `streams.Producer` wrapper level, `p.receivers`, and at
`conn.GetTrack`).

## Mechanism (source walk, v1.9.10 == v1.9.14 == master for all files below)

1. `internal/streams/api.go` GET branch: `probe.Create("probe", query)`
   -- the `microphone` param builds a recvonly audio media with
   `CodecAny` (`pkg/probe/consumer.go`), then `stream.AddConsumer(cons)`.
2. `internal/streams/add_consumer.go`: for each consumer media, match
   against producer medias. The mic media (recvonly) matches the
   producer's sendonly audio media (`CodecAny` matches anything,
   `pkg/core/codec.go` `Codec.Match`).
3. Producer media is sendonly -> Step 4/5: `cons.GetTrack` then
   `prod.AddTrack(prodMedia, prodCodec, track)`.
4. `internal/streams/producer.go` `Producer.AddTrack`: no dedup ->
   `p.conn.(core.Consumer).AddTrack(...)`.
5. `pkg/rtsp/consumer.go` `Conn.AddTrack`, ModeActiveProducer branch:
   `if c.state == StatePlay { c.Reconnect() }` -- unconditional, no
   check whether an equivalent sender already exists.
6. `Conn.Reconnect()` (`pkg/rtsp/producer.go`): `Close()` (TEARDOWN) ->
   `Dial()` -> `Describe()` -> re-Setup all receivers AND senders ->
   Play. Full session remake. Camera-side, this is a brand-new RTSP
   session; any consumer riding the old session's RTP stream sees a
   splice/drop (cf. #2404's re-dial splices, #2387's severed
   receivers).

The GetTrack/AddTrack asymmetry in one line: GetTrack asks "do you
already serve this?" (dedup by pointer identity); AddTrack asks
"please serve this too" and never checks whether you already do.

## Impact

- frigate 0.17.2 live page = one probe GET per restreamed camera,
  2s after mount, in parallel (`web/src/hooks/
  use-deferred-stream-metadata.ts`, `DEFER_DELAY_MS = 2000`). On our
  7-camera system, every page load remade all 7 RTSP sessions in the
  same second and frigate's watchdogs restarted all ffmpeg processes
  ~20-24s later (verified: 3 page loads -> 3 fleet-wide waves; zero
  watchdog events in 90+ minutes with the page closed).
- The probe's purpose is metadata only: the response's producer medias
  (`audio, sendonly` presence = two-way audio support) are identical
  whether or not the probe consumer was actually added -- a paramless
  GET returns the same producer medias without AddConsumer. The
  reconnect buys nothing for the requester.
- Repeated probes are not idempotent: every GET with `microphone`
  reconnects the producer again.

## Suggested directions (maintainer's call, obviously)

a) In `Conn.AddTrack` (ModeActiveProducer), dedup against existing
   `c.Senders` by media/codec match and return early if an equivalent
   backchannel sender already exists -- the mirror of GetTrack's
   receiver dedup.
b) In `internal/streams` AddConsumer, skip producer-side AddTrack when
   the consumer is a probe (or when the request is a metadata GET).
c) Document that `microphone` on the streams GET is invasive for
   playing producers, so API consumers can avoid it.

## Family / related

- #2387: `Producer.reconnect()` silently drops unmatched receivers --
  the same reconnect path, the same silence, the inverse failure
  (there it severs receivers that exist; here a probe that should not
  touch the connection forces the reconnect).
- #2362: producer reconnect destroys co-existing RTSP audio
  (camera single-audio-session limit) -- the damage class our wave
  produces on cameras that only allow one audio session.
- #2404: producer re-dial splices new RTP into open consumer sessions
  -- what consumers experience when the session is remade under them.

## Environment

- go2rtc 1.9.10 (inside frigate 0.17.2 stable-tensorrt); verified the
  relevant files are byte-identical at v1.9.14 and master
  (pkg/rtsp/producer.go, pkg/rtsp/consumer.go, pkg/core/connection.go,
  pkg/core/media.go, pkg/core/codec.go, internal/streams/add_consumer.go,
  pkg/probe/consumer.go).
- Cameras: thingino firmware RTSP (H.265 + AAC + PCMA/PCMU speaker
  medias), TCP interleaved RTSP.
## CLEAN FALSIFIER RESULT (2026-09-17 17:52Z, aria interactive, Nacho-authorized)

Single-camera probe fired from inside the frigate container, outside
any wave window, no page load involved:

  curl "http://localhost:1984/api/streams?src=exterior_3&video=all&audio=all&microphone="

Timeline (all times local -03 / UTC in parens):
- 14:52:42 (17:52:42Z): probe fires (HTTP 200, 3.3s -- the reconnect
  ran inside the request).
- go2rtc producer id 19427 -> 19559: FULL session remake on .103.
- 14:53:43 (+61s): exterior_3 detect ffmpeg PTS/DTS invalid-dropping
  errors -> watchdog Restarting ffmpeg.
- 14:53:43-14:55:48: recorder enters a RESTART LOOP (3+ watchdog
  cycles, "No frames received in 20 seconds", final failure shape:
  vf#1 "Function not implemented" -> "Nothing was written"). The
  predicted self-heal did NOT happen -- the recorder WEDGED on the
  new session.
- Other cameras: exterior_5 watchdog events 14:53:17-48 (likely
  independent -- its dial-loop history; not attributed to the probe);
  exterior_4 crash is the known power-dead camera (DESCRIBE 404).
- 14:56: HEALED by go2rtc stream reload (DELETE 400 + PUT 200 on
  /api/streams?src=exterior_3 -- the stopProducers path, 0058
  recipe). Segments resumed 14:56:14; ear-check 17:58Z: ext3 audio
  healthy (-32.5 dB mean), all 7 alive cameras carrying audio.

Issue-draft impact: the reproducer is now proven with a single
request and zero page-load ambiguity. NEW impact line: the blast
radius is worse than a 20s stall -- downstream consumers can WEDGE
in a restart loop (function-not-implemented on the remade session's
stream properties) and need a stream reload to recover. This
strengthens the case that AddTrack dedup (direction a) matters.
