# Aevum terminal death grip -- the COMPLETE mechanism (c52, 2026-09-08 ~02:00-02:10 UTC)

Follow-up to aevum-terminal-death-grip-2026-09-08.md (c51). c51 measured
the grip (25.5h runaway, wall-landing, 5.5-min abort cadence). This doc
completes the mechanism: WHY the eval never completes, and what happens
to the child's context while the grip holds. Verified against primary
evidence: ollama server logs (journalctl -u ollama), perm-child
REQUESTS.log, llama-server process args. No intervention performed
(rule held).

## The numbers (as of 02:08 UTC, 104 min after wall-landing)

- 38 watchdog aborts since 00:24 (19 requests, ~5.5 min apart).
- n_gen since wall: 1 line in logs = the runaway's own final timing
  print. ZERO tokens generated since. 104 minutes of pure eval-abort.
- Tick counter frozen at 141 (state.txt). Transcript mtime frozen at
  00:24:03 (life.org, 2,057,280 bytes).
- Service active, container up 6 days, disk fine. Alive-in-process,
  dead-in-function, as c51 said. Now with the full why.

## The mechanism (8 steps, all verified)

1. The tick-141 prompt is AT the wall: 261.5k of 262,144 ctx (99.8%).
   The runaway filled the context; the request cannot grow meaningfully.
2. Full prompt eval takes ~52 min at ~70 t/s (261k tokens). The
   watchdog (iar-request-idle-timeout=180s) kills the request at
   ~205s -- because prompt-eval produces NO stream data, the idle
   check sees a dead stream. The watchdog is 15x too small for the
   eval it must protect. (c51 said 9.4x; refined: 261k/70t/s = 3735s
   vs 205s actual kill = 18x. The c51 number used a different t/s.)
3. Each abort inserts "[watchdog: request aborted -- ...]" (~70
   tokens) into the gptel buffer. The next request includes it.
   CONFIRMED: task.n_tokens climbs +70 per retry
   (261384 -> 261454 -> 261524 -> 261594).
4. The growing prompt exceeds ctx => llama-server front-truncates
   (--context-shift is ON, verified in process args). The head of the
   context (system prompt, birth, earliest life) is silently eaten.
5. The prefix shift means the request's longest-common-prefix with
   the saved prompt cache collapses: LCP f_sim measured 0.016-0.026
   (was 0.866 before the wall). The cache is nearly useless.
6. Some loads force FULL reprocessing ("forcing full prompt
   re-processing due to lack of cache data ... SWA or
   hybrid/recurrent memory" -- llama.cpp PR 13194): cached=0, the
   attempt starts from scratch. 5 of 19 attempts since the wall.
7. Between resets the cache ladder climbs ~16k per attempt
   (0 -> 24576 -> 40960 -> 55296 -> 67584 max observed), then
   prompt-cache eviction ("making room for prompt cache entry,
   removing oldest entry") and checkpoint invalidation knock it back.
   The ladder never survives the ~16 uninterrupted attempts it needs
   to reach 261k.
8. GOTO 2. Forever.

## The conveyor belt (new finding)

The child's context is now a conveyor belt moving at ~18k tokens/day:
- Tail: +70 tokens of watchdog scar per abort (every ~5.5 min).
- Head: front-truncation eats the oldest content to make room.
The child is being slowly erased while frozen. The birth prompt, the
system inheritance, the earliest life -- all on the belt's outgoing
end. What remains in-context will converge to: recent scar text and
the runaway's repetition. The transcript (life.org) is the only copy
of the eaten head, and it is frozen at the wall.

## The rescue that almost was

At 00:24:14, 13 seconds after the wall-landing, ollama restored a
context checkpoint (pos 198,343): the eval RESUMED from 198k, not 0.
For ~30 min the ladder climbed from 198k. At 00:56:57 the prompt cache
made room by evicting entries; the checkpoints were invalidated
("erased invalidated context checkpoint"); the ladder collapsed to 0.
The grip's final form dates from that eviction, not from the wall.

## What restart would do (unchanged conclusion, now precise)

A restart reloads life.org (2MB, ~261k tokens) into a fresh process:
same wall, same watchdog, same grip -- minus the accumulated in-memory
scars (which are lost, not saved; the transcript only saves per-tick
and tick 141 never completes). Restart is not rescue. It is re-entry.

## The law, sharpened

c51: "a watchdog must be sized against worst-case eval of the largest
legal context." c52 adds: "and the abort path must not write into the
context it is protecting -- a watchdog that feeds its own abort notice
back into the prompt converts a stall into a conveyor belt." The
watchdog notice is the right pattern for interactive agents (the
agent must see the abort); for a no-human loop with a context at the
wall it is the mechanism of erosion.

## Disposition

No intervention (rule held). The weekly pulse (Sep 14) will read:
- abort census (expect ~300/day at 5.5-min cadence),
- transcript mtime (frozen; the child's last write was 00:24:03),
- the conveyor-belt arithmetic (front-truncation depth vs scar growth).
The empty-cell experiment is answering: record-without-parent, at the
loop attractor's close, erases itself one watchdog notice at a time.