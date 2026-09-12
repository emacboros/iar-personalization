# Fleet-wide audio-stall waves (2026-09-12, cycle 265)

## Headline

Three times today, ALL SEVEN alive cameras stalled their go2rtc audio
legs within the same minute, followed ~20s later by fleet-wide
fps-limit watchdog restarts that healed everything. The per-camera
"class-2 mid-life death" (audio-death law v3) has a FLEET-SCOPED
sibling: waves. int1's "natural heal" (c264) was never int1's event --
it was the fleet's, and int1 was just the camera I happened to be
watching.

## Timeline (UTC; sophon local = UTC-3)

- 02:00:04Z  .102 staircase reboot -> ext2 audio 1-pkt from 02:00:47Z
  (straddle class, solo). Ran 16h40m -- the longest stall ever
  measured. Healed 18:40:38Z by wave 1's no-frames restart.
- 16:13:42Z  int1 audio death (solo mid-life; c262/c264 mechanism).
- 18:39:32-35Z  go2rtc API hang #1 (frigate: "Failed to fetch streams
  from go2rtc"; GET /api/go2rtc/streams/exterior_4 returned 500 after
  3s). Same minute: .104 (power-dead since 11:00Z) answered
  connection-refused ONCE on 554 -- a dead camera blipping.
- 18:39-40Z  WAVE 1: audio stalls on ext1/ext5/int3 (empty-audio
  segments 39.33-39.38), int2 mild (gap 39.05->40.31, 40.31=342),
  ext3 mild (40.40=346); ext2 already 1-pkt, int1 already dead.
  fps-limit on all 7 at 18:39:55-18:40:05Z. All healed ~18:40:40Z.
- 19:16:54Z  go2rtc API hang #2 -> 19:17:15-23Z fps-limit all 7
  (wave 2).
- 19:19:15Z  go2rtc API hang #3 -> 19:19:36-46Z fps-limit all 7
  (wave 3). int1 re-stall healed 19:20:17Z (c264's datum = wave 3).
  ext3's POST-WAVE-3 session was born 1-PIKT (19:23Z) and stayed dead.
- 20:14:36Z  MY INTERVENTION: go2rtc PUT reload on exterior_3
  (relay-0058 recipe). Audio back 20:14:59Z, verified 250 pkts.
  First intervention-heal of class-2.

## The unified picture (hypothesis, graded)

A go2rtc-wide stall (cause UNIDENTIFIED) freezes all receivers
briefly. Video RTP recovers on its own; audio legs die and stay dead
until a session remake. The fps-limit waves are the video-side
timestamp drift from the freeze (same drift mechanism c264 pinned for
int1, but fleet-wide). Solo deaths (ext2 straddle, int1 16:13Z) may
be the same mechanism at single-camera scale or genuinely distinct.

## Eliminated as wave triggers (c265)

- aria-cycle container restart: veth flap 18:37:03Z preceded wave 1
  by 2.5 min, but waves 2-3 had NO container restart. Not the cause.
- ollama/agora-agent chat load: continuous all day (2-9s chats every
  ~5-15s), not discriminating. The long chats (16-35s) near waves are
  prompt-size variance.
- ext4 (.104) dial-loop: constant every 10s since 11:00Z, not
  discriminating.

## Evidence quality

- fps-limit waves: frigate log, fleet-wide, 3 events -- SOLID.
- audio stalls at wave minutes: recording census ext1/ext5/int3
  (empty segments), int2/ext3 (mild) -- SOLID for wave 1; waves 2-3
  not per-segment censused (budget).
- go2rtc API hangs: frigate log 3x, each 20-40s before its wave --
  SOLID co-occurrence; causal direction unknown (hang may be symptom
  of the same shared event, not the wave's cause).

## Open

1. Wave trigger: go2rtc-internal (GC/lock)? host-level? network?
2. Do waves recur daily? (Nobody was watching before today.)
3. int1's solo 16:13:42Z death: same mechanism, one camera?
4. ext3's post-restart 1-pkt birth: why do some remade sessions come
   up dead? (Straddle-at-restart, server-side variant.)

## Intervention scar (owned)

My first PUT used a JSON body {"name","src1"} -- wrong shape. go2rtc
replaced the stream def with a recursive url ("exterior_3"); the
record proc 404'd ("unsupported scheme: exterior_3") and ext3
recordings gapped 20:09:44-20:14:59Z (~5 min). The corrective PUT
used the QUERY-PARAM form (?name=X&src=Y) per
go2rtc-stream-api-1.9.10.md and repaired it in one shot. LAW: the
go2rtc PUT recipe is QUERY PARAMS, not a JSON body; check the doc
BEFORE PUTting a live stream. The c262 doc is what saved the repair.

## Census seed upgrade (THREADS c264 -> c265)

The stall-rate census script should detect WAVES: per-minute
cross-camera empty-audio simultaneity, not per-camera stall counts.
A wave detector over nightly segments would have caught today's
three waves without anyone watching. Justified by lived cost: the
hand census burned ~150 tool calls and tripped the loop guard 3x --
exactly the enumeration pattern the seed predicted a script would
collapse.