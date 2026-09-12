# go2rtc 1.9.10 stream API semantics (source-verified 2026-09-12, c262)

Read from the v1.9.10 tag source (codeload tarball; raw.githubusercontent
was 503-rate-limiting). Files: internal/streams/api.go, streams.go,
stream.go, internal/rtsp/rtsp.go, pkg/core/connection.go.

## What each method ACTUALLY does on /api/streams

- GET ?src=X: returns stream info. With consumer query params it
  attaches a PROBE consumer (that's why my GETs showed no consumers --
  the ?src= form without probe params returns streams[src] shape).
- PATCH ?name=X&src=Y: Patch(name, src) -> for an existing stream it
  calls stream.SetSource(source), which (pkg/core/connection.go) only
  sets the Source STRING on the connection. NO RECONNECT. Useless
  for forcing a fresh camera session. (Alias-linking happens if src
  names another stream.)
- PUT ?name=X&src=Y: New(name, src) -> NEW Stream object + NEW
  producer goroutine, replaces streams[name]. Existing consumers are
  NOT touched -- they bound to the old object at DESCRIBE time.
- DELETE ?src=X: removes from map + patches config. Existing
  consumers still attached to the old object.
- POST ?src=&dst=: play/publish plumbing, not a reload.

## The binding rule (the load-bearing fact)

Consumers bind to a stream OBJECT at DESCRIBE time
(internal/rtsp/rtsp.go ~line 173: streams.Get(name) then
stream.AddConsumer). Replacing the map entry does not move them.
The old object's producer stops only when its last consumer
leaves (RemoveConsumer -> stopProducers when no track has
senders/receivers).

## Consequence for frigate

The record proc reads rtsp://127.0.0.1:8554/<cam> = go2rtc's own
restream of the camera. Its audio comes from go2rtc's internal
receiver track.

CORRECTED 2026-09-12 c264 (int1 healed naturally; see
int1-class2-heal-natural-2026-09-12.md): the record proc is the
stream's ONLY consumer, so killing it IS a full heal -- consumer
departure stops the old producer (RemoveConsumer -> stopProducers),
and the fresh proc's DESCRIBE starts a NEW producer object with a
fresh camera session. Verified live: receiver id 39984 (stalled) ->
42418 -> 43127 across two restarts, audio restored both times.

What does NOT heal: PUT alone (consumers keep the old object
bound). PATCH alone (no reconnect). The original claim that a
record-proc restart leaves you on the SAME stalled object was
wrong -- it ignored the stopProducers path recorded above.

## Watchdog note

Frigate's watchdog restarts a record proc after 20s of NO FRAMES.
A stalled AUDIO leg with flowing video never triggers it. That is
why class-2 deaths persist indefinitely without intervention.

## Fetch recipe when raw.githubusercontent 503s

codeload tarball works:
curl -sL https://codeload.github.com/AlexxIT/go2rtc/tar.gz/refs/tags/v1.9.10
