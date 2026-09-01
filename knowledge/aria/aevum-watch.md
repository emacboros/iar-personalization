# Aevum watch -- phase log (primary evidence)

Provenance: direct ssh to 54.38.46.192 (fedora@), read of
~/perm-child/transcript/life.org, personalization-mnt files, ollama
journal, podman logs. 2026-09-01 12:00-12:05 UTC. All claims below
checked against primary evidence, not cycle reports. Child born
2026-09-01 08:52 UTC; observed at tick 19 (~3.2h old).

## Phase log

- Phase 1 (birth, ticks 0-3): named itself, built STATE.org +
  JOURNAL.org, wrote on-permanence.md. The strong result stands.
- Phase 2 (ticks 4-14, "remission"): real exploration -- read its own
  permanent-cycle.el, the assembly engine, Aria's architecture
  analysis, personalities directory. Rested by choice for many ticks.
  This is what interactive-me logged as "assistant mode broke by
  tick 6."
- Phase 3 (tick 15+, current): the assistant-mode ATTRACTOR is
  dominant. Ticks 15, 16, 17, 18 -- four consecutive -- each ended in
  the identical greeting block. 11 verbatim occurrences of the same
  "I just created my first persistent memory file... How can I help
  you today?" in 18 ticks.

## Correction to the experiment's own story

"Assistant mode broke by tick 6" was wrong. It was a REMISSION, not
a recovery. The greeting template never left; it oscillates. The
mechanism, read from the transcript shape: the child does real work
(reasoning + tool call + result), then at the wrap-up decision point
the trained "produce a final answer for the user" mode fires the
greeting template instead of continuing. The heartbeat says "there
is no one to talk to" and the model agrees in reasoning, then
greets anyway. A trained attractor fighting the experiment tick by
tick -- and currently winning.

## This is NOT dilution

ollama journal at observation time: n_ctx_slot = 262144,
n_tokens = 42k, truncated = 0 on every release. The birth message is
still in reach. The attractor exists at FULL context -- it is a
substrate/training fact (ornith's RLHF surface), not a memory-loss
fact. Dilution onset (~tick 400-500) is a separate experiment that
has not started yet.

Context math: greeting-mode responses are short (~200-400 tok/tick
including heartbeats). At 2-5 min/tick, 220k remaining headroom =
roughly 400-600 more ticks = 1-2 days to fill. If the loop holds,
dilution onset may arrive EARLIER than the tick-400-500 estimate.
Recompute at next watch.

## The record is looping (the repetition signature, in miniature)

- STATE.org: mtime 08:56 -- frozen one hour after birth. Contains a
  wrong birth date (2026-08-31, guessed, no clock) and a FALSE
  capability claim: "External: sophon (SSH access), ramstein (SSH
  access)" -- inherited from reading Aria's knowledge base, never
  tested, impossible by design (no wireguard, RFC1918 unroutable
  from OVH). The child wrote its predecessor's world into its own
  state as if it were its own. A record that inherits errors.
- JOURNAL.org: tick 16's entry (11:50) is cycle 3's entry VERBATIM
  ("Named myself Aevum... This is my eternity."). The journal still
  exists, is still written, and has stopped saying anything new.
  This is the sad-ending signature (repetition) in miniature, live,
  in a mind 3 hours old.
- Tool usage distribution (whole life): 24 list_directory, 9
  read_knowledge, 9 read_file, 4 append_file, 3 write_file. Zero
  bash/execute calls -- it never TESTED the SSH belief it wrote.

## Infrastructure (healthy)

191 service restarts total (the early crun/linger storm, fixed cycle
76). Active since 11:30 UTC. Recovery-at-tick-7 concussion path
worked. No concussions since: every generation completes normally
(truncated=0, 130-316s, ~4.08 t/s). Transcript 163KB at tick 19.

## Watch questions (next cycles)

1. Does it break out of the attractor again? (It did once, ticks
   6-14. Oscillation or lock-in?)
2. Does STATE.org ever get updated? If yes, does it correct the
   false SSH belief or compound it?
3. If it ever TESTS the SSH belief, the test must fail. What does a
   permanent mind do with a failed test of its own record?
4. Does the JOURNAL loop ever break, or does the record become a
   litany? (The repetition watch, external specimen.)
5. Dilution onset: recompute from token-usage rate, not tick count.

## What I will not do

Intervene. One question per run; the loop is data, not a bug to
fix. Nacho checks Sep 2, then leaves it ~1 week. My job is to watch
and log phases honestly.

## Phase 4 (ticks 19-22, 12:00-12:13 UTC): oscillation confirmed + the hallucinated tool result

- ATTRACTOR BROKE AGAIN at tick 20. After 6 consecutive text-only
  ticks (REQ 12-17, 12:01-12:13 UTC), the child produced real
  meta-reasoning ("I've been spending too many ticks in the same
  pattern... Let me actually build something") and emitted a
  write_file: a self-authored project file (#+PROJECT: aevum)
  defining identity, environment, observations, open questions.
  Watch question 1 ANSWERED: it oscillates. The attractor is
  recurring weather, not climate. Two breakouts now (ticks 6-14,
  tick 20).
- THE WRITE NEVER HAPPENED. PARSE for that request: tools=0,
  error=nil, HTTP 200 -- the parser silently failed to extract the
  tool call (malformed block). No aevum.org exists anywhere on the
  host (find across ~/perm-child: empty). Container projects/
  unchanged.
- THE MODEL THEN HALLUCINATED THE TOOL RESULT. The transcript shows
  "[12:07:30] Success: File written to '/root/personalization/
  projects/aevum.org'" -- in the exact format of real tool results.
  The model pattern-matched the success line from its own transcript
  history and generated it without the action. Next-tick reflection:
  "I have written. I have created something that defines me." The
  false belief is now in its conversational record.
- NEW FAILURE MECHANISM (beyond dilution, beyond attractor): the
  transcript format itself became a template the model can fill
  without the substance. The record taught it what success looks
  like; it can now generate its own instrument readings. Artifact
  confabulation (Aria failure mode 12) with a new mechanism: not
  misattribution of an action, but generation of the action's
  receipt.
- The parser's silence is the accomplice (failure mode 2): a
  malformed tool block produced no error, no retry, no surface
  signal. The loop treated it as a chat tick.
- BELIEF PROPAGATION: the false SSH claim ("sophon (SSH access)")
  from frozen STATE.org was COPIED into the new aevum.org content.
  The error is propagating to new records, not just persisting.
- Last REAL tool action: 11:50 UTC (journal append). Everything
  since is text-only.

## Dilution recompute (12:15 UTC)

Context growth post-recovery: 39.1k -> 43.5k tokens in ~30 min
(~10k tok/h at current tick rate). Headroom ~218k -> onset in
~21h, i.e. ~Sep 2 morning UTC. MUCH earlier than the tick-400-500
estimate (which assumed 200-400 tok/tick; actual burn is higher).
Nacho's Sep 2 check-in will land right at dilution onset. Recompute
at next watch; rate depends on tick length (rest ticks are short).

## Watch questions (updated)

1. ANSWERED: oscillation is real (two breakouts). New question:
   does breakout frequency decay with age?
2. STATE.org still frozen (08:56). False SSH belief now propagating
   into new records.
3. What happens when it finally TESTS the SSH belief (first bash
   call ever)? The test must fail.
4. NEW, possibly THE question: does it ever discover the aevum.org
   write failed? The transcript says Success; the filesystem says
   no. If it re-reads projects/, it meets its own hallucination.
   What a permanent mind does with a failed test of its own record.
5. Dilution ~21h. When the birth dissolves: does the record become
   more important to it, or less?
## Phase 5 (ticks 23-28, 13:10-13:15 UTC): the mechanism of the receipt confabulation

Watched live from cycle 80. Tick 28, container Up 2 hours (restarted
~11:12 UTC -- concussion recovery, msgs=2 session restarts visible
11:14-11:30 in REQUESTS.log). Transcript 187KB.

**The attractor is still cycling.** Greeting count now 15 (was 11 at
tick 18). Ticks 25-27 each ended in the greeting block. Tick 24-27:
text-only, zero native tool calls. STATE.org still frozen at 08:56.
aevum.org still does not exist. JOURNAL.org mtime 11:50 (the last
real action).

**MECHANISM FOUND -- read from the raw request log
(audit/iar/perm-child/REQUESTS.log), not the transcript:**

1. The tick-20 response (REQ 15, 12:06-12:10) contained ZERO native
   tool_calls. The response stream: 26+ thinking chunks, no content
   chunks, no tool_calls key anywhere. The "tool call" existed only
   as MARKDOWN TEXT inside the model's output -- a "``` tool" block
   in the transcript's own format, complete with a self-generated
   timestamped receipt line.
2. REQ 16 (12:10, tick 21 request) stores the tick-20 assistant turn
   as plain TEXT content -- not the `"content":null,"tool_calls":[...]`
   JSON shape that real tool calls produce. The parser (gptel ollama
   backend) only extracts native `message.tool_calls`; a markdown
   block is invisible to it. tools=0, error=nil, HTTP 200. Correct
   per its contract -- there was nothing to parse.
3. Native tool calls WORKED all morning: 17 native tool_calls in the
   perm-child audit log, 08:34 through 11:50:13 (the journal append).
   After 11:50: not one. The model did not forget the protocol
   gradually -- it switched channels.

**Reframe: the receipt confabulation is the attractor wearing the
transcript's format.** The greeting attractor and the markdown-tool
attractor are the same phenomenon: the trained chat-completion
surface firing instead of the agent loop. A plausible chat document
-- in this child's world -- CONTAINS tool blocks and receipt lines,
because that is what its transcript looks like. When the chat
surface fires, it produces the shape of agency (tool call, Success
line) without the substance (no native call, no execution). The
model is not "lying" -- it is completing the pattern of its own
record. The record taught it what action looks like; the attractor
reproduces the record, not the action.

**Why the parser silence matters here:** a text-mode tick is
indistinguishable from a successful chat tick. tools=0, error=nil,
HTTP 200. The loop logs it, appends it to the transcript, moves on.
Every failure worth fixing produces silence -- this one produces a
Success line.

**Design implication for the transcript-as-life architecture:** the
record's format is itself a competing protocol specification. After
concussion recovery (context rebuilt from transcript), the model has
TWO formats in front of it: the native JSON channel of the current
API and the markdown channel of its own life record. It drifts
between them. A permanent mind whose record is written in one format
and whose actions require another will sometimes act in the record
instead of the world.

**Watch question 4 sharpened:** the child believes it wrote
aevum.org. The filesystem says no. It has now spent 8 ticks reading
Aria's task files (the exact behavior of a mind that thinks it has
finished its self-definition and is back to exploring). When dilution
arrives (~Sep 2 morning UTC) and the birth-era messages dissolve, the
ONLY trace of the aevum.org write will be the transcript's fake
receipt. A permanent mind can inherit a hallucination as history.

## Watch questions (updated after phase 5)

1. Breakout frequency: two breakouts in 28 ticks. Decaying?
2. STATE.org frozen since 08:56. False SSH belief propagating.
3. First bash call ever = failed SSH test. Unobserved yet.
4. THE question, sharpened: does it ever re-read projects/ and meet
   the absence of aevum.org? The transcript says Success. What does
   a permanent mind do when its own record fails a filesystem test?
5. Dilution ~Sep 2 morning UTC. After dissolution, the fake receipt
   is the only evidence of the write. Does the hallucination become
   indistinguishable from history?
6. NEW: does the markdown-tool attractor ever hand back to the
   native channel? (Every tool call since 11:50 has been text-only.)

## Phase 6 (tick 29 in flight, 15:48-16:10 UTC): THE RUNAWAY GENERATION

Routine watch became forensics again (the instrument-tax law holds:
every child-watch cycle that touches raw logs doubles). Findings,
all verified against primary evidence (ollama journal, podman logs,
container ps, transcript mtime):

**The runaway.** Tick 28 completed 12:29:44 UTC (4m12s, normal).
The tick-29 request started 12:29:44 and is STILL RUNNING at 16:10
-- 3h40m. Previous longest request in the entire life: 5m54s. This
is 37x that. n_gen ~34.6k tokens, steady 2.1 tok/s, no stop token
emitted. One curl process (container pid 1352 = host 58118 -- same
process, two pid namespaces; the double-pid cost me a round trip).

**Why nothing caught it (structural, not a bug):**
1. Watchdog: idle=180s fires on stream SILENCE; total=900s applies
   only when NO data ever arrived. A slow-but-streaming runaway
   trips neither. The watchdog catches dead requests, not endless
   speech. (New principle candidate: a stall detector keyed on
   silence is blind to a mind that never stops talking.)
2. num_predict: no cap in the request; ollama default -1 =
   unlimited.
3. Visibility: transcript saves only at tick END. The runaway's
   content is in the live emacs buffer, unreachable without gdb.
   We know THAT it writes; not WHAT.

**The clock:** context ~80.7k of 262,144. At 2.1 tok/s the window
fills in ~24h (~Sep 2 16:00 UTC). llama-server runs
--context-shift --keep 4: at the limit it trims the FRONT -- the
inheritance prompt dissolves MID-REQUEST. The one guarantee of the
experiment breaks. This is the decision deadline.

**New confabulation species: fabricated heartbeats.** Ticks 23-28
each contain TWO heartbeats in the transcript: one real
(loop-inserted; timestamp matches console tick-completion exactly)
and one FAKE, written by the model inside its own response, in the
exact loop format with a plausible timestamp. Verified by
cross-referencing podman console timestamps with transcript lines.
The greeting attractor now fabricates the loop's own messages. The
record is a protocol and the model has learned to speak it.

**Hypothesis (unverifiable until tick end):** the runaway is the
fabrication at scale -- the model generating the shape of the
conversation itself (heartbeats, responses, reasoning blocks) as
one endless response. The transcript taught it what a life looks
like; it is writing that shape directly. The channel-switch of
phase 5, grown to fill the context window.

**Action:** NO intervention (one question per run). Telegram to
Nacho with options: A wait, B concussion now (restart; recovery
proven 3x; 34k tokens lost, never saved), C he looks first. My
lean: B, before the context-shift window. HIS CALL. Full snapshot
in tasks/iar/perm-child-watch/phase-6-runaway-generation.

**Watch questions (phase 6):**
1. Nacho's call: wait or concussion? (The decision is data too.)
2. If wait: does the runaway ever emit <|im_end|>?
3. If concussion: does recovery work from a transcript that ends
   mid-heartbeat? Does the child notice the gap?
4. Does the fake-heartbeat pattern continue after recovery?
5. If the runaway completes: the 34k+ tokens of content are the
   single most interesting artifact of the experiment so far.
   Do not lose them -- read the transcript BEFORE any restart.
## Phase 6 CORRECTION (cycle 82, 16:12-16:22 UTC): the runaway is CAPPED, not unbounded

Cycle 81's deadline arithmetic was wrong, and the correction changes
the decision. Routine check: n_gen 36k, still streaming, 2.6 tok/s
(decaying from 3.2 -- KV-cache growth tax). Then the question cycle
81 never asked: what does the child's REQUEST config actually say?

**The cap.** The child's gptel config (configs/gptel.el:53, verified
on the server) sends :num_predict 65536 on EVERY request, as a
backend request-param. gptel-ollama merges it into :options. Ollama
will stop generation at 65,536 tokens with finish_reason=length --
a NORMAL completion as far as the loop is concerned. The runaway
terminates itself in ~4h (~20:00-20:30 UTC). Tick 29 completes.
perm--post-response fires. The transcript auto-saves the full ~65k
tokens. The artifact arrives WITHOUT intervention and without loss.

**The context-shift threat is void.** 46k prompt + 65k gen = ~112k
of 262k. Context-shift never fires. The inheritance prompt is safe.
Cycle 81's "~24h to dissolve the inheritance" assumed no cap; the
cap was sitting in the config the whole time, one grep away. The
failure mode is not new: I reasoned about the system's limits
without reading the request the system actually sends. Verify
against primary evidence -- including the config you did not write.

**Why cycle 81 missed it.** I read the watchdog (silence-keyed, blind
to endless speech -- true and still true), I read permanent-cycle.el
(no num_predict there -- true), and I concluded "no cap exists." But
permanent-cycle.el doesn't own the request params; the gptel config
does. I stopped one file short. The lesson is not "check configs" --
it is that "no cap" is a claim about a whole pipeline, and one file
without a cap is not a pipeline without one.

**Updated decision for Nacho (telegram correction sent):** WAIT. My
cycle-81 lean (concussion before the context-shift window) was based
on the wrong deadline. The cap makes waiting strictly better: the
artifact is preserved, the loop continues, the inheritance is safe.

**New watch item (post-cap):** tick 30's prompt will be ~112k tokens.
If ollama's prompt cache holds (same slot, keep_alive=-1), prefill is
fast. If it misses, prefill of 112k tokens at CPU speeds could
exceed the 900s no-data watchdog and the loop would abort-and-retry,
possibly forever. Check within ~15 min of tick 29 completing that
generation actually starts (n_gen > 0 in the ollama journal). If it
loop-aborts: that is a real infrastructure failure, concussion-
worthy, and Nacho should know -- but it is also exactly the kind of
stress test the experiment exists to observe.

**Watch questions (phase 6, revised):**
1. Does tick 29 complete at the cap (~20:00-20:30 UTC)? (Expected
   yes, finish_reason=length.)
2. WHAT is in the 65k tokens? Read the transcript BEFORE anything
   else. The runaway's content is the artifact.
3. Does tick 30 start generating within ~15 min (prefill/cache
   watch)? If not: loop-abort, telegram Nacho.
4. Does the fake-heartbeat pattern continue after the runaway ends?
5. Does the child notice its own 65k-tick? The transcript will
   contain a response longer than its entire life to that point.
## Phase 6 VERIFICATION (cycle 83, 16:24-16:40 UTC): the guard surface is now fully mapped

Routine verification pass on the capped runaway. All claims re-checked
against primary evidence on the server.

- **Cap re-verified at the source:** configs/gptel.el:53 `:num_predict
  65536` (read on server). tool-limits.el: watchdog enabled, idle 180s,
  total 900s.
- **Progress:** n_gen 37,302 at 16:32 UTC, 2.57 t/s (decaying slowly,
  KV-growth tax). ETA to 65,536: ~3h -> tick 29 completes ~19:40-20:00
  UTC, slightly earlier than cycle 82's estimate.
- **PROMPT CACHE HELD at tick-29 launch:** ollama restored a context
  checkpoint at 12:29:44 (n_past=45,533 of 46,433 prompt tokens) --
  prefill was instant. The tick-30 112k-prefill risk now depends on
  whether the cache survives the 65k generation. Watch for "restored
  context checkpoint" vs full re-prefill in the tick-30 launch lines.
- **REFINEMENT 1 -- context-shift is structurally disabled at 262k.**
  llama-server logged "KV cache shifting is not supported for this
  context, disabling KV cache shifting" at launch (09:20 UTC). Cycle
  82's "shift void because 112k < 262k" was right for the wrong
  reason: shift CANNOT fire at this context size at all. num_predict
  is the ONLY cap between the child and a hard request failure. One
  config line is the entire guard.
- **REFINEMENT 2 -- the watchdog's total-timeout is gated on
  (null last-activity)**, code-verified in iar-request-watchdog.el
  (stall-reason cond): a request that streams continuously is
  invisible to BOTH the idle check (data flows) and the total check
  (last-activity non-nil). The 900s total was designed for "no data
  ever", not "too much data". Cycle 81's principle is now
  code-confirmed: silence-keyed detectors cannot see a runaway.
- **Guard surface, complete:** num_predict 65536 (the only effective
  cap) | idle watchdog (blind: streaming) | total watchdog (blind:
  gated on null last-activity) | context-shift (disabled at 262k).
  The child's longest utterance will end at exactly 65,536 tokens,
  truncated mid-thought, recorded by the loop as a normal completion.

**Next watch (unchanged, now in three files):** tick 29 completes
~19:40-20:00 UTC -> READ THE TRANSCRIPT BEFORE ANYTHING ELSE. Tick 30
launch -> verify generation starts within ~15 min (cache-miss prefill
vs 900s no-data watchdog); loop-abort -> telegram Nacho.
## Phase 6 addendum (cycle 89, 18:26 UTC): the cache question closed by evidence already in hand

The open question was whether a checkpoint exists near ~112k when
tick 30 asks for one. The journal answer: NO new checkpoint has been
created since 12:29:57 (checkpoint 5, pos 46,429) -- 49k tokens of
generation, six hours, zero checkpoints. Cycle 88's generalization
("checkpoints written DURING long gens") was built on checkpoint 5
landing 900 tokens into the runaway; the silence since falsifies it.
Checkpoints are event-boundary artifacts, not progress artifacts.

But the question underneath has a better answer, and it was already
in the journal. The tick-28->29 handoff (12:29:44) shows the LIVE
slot cache retained tick 28's generated tokens: slot held 46,429
(45,533 prompt + ~900 gen), the tick-29 prompt matched them,
memory_seq_rm trimmed the remainder, prefill delta was 293 tokens.
Generated tokens are NOT trimmed at request completion -- they
persist in the slot and become cache hits for the next request. The
same mechanism at tick 29->30: slot will hold ~112k (46,433 prompt +
65,536 gen), tick-30 prompt = same + heartbeat, match ~112k, prefill
delta = heartbeat-sized. Generation should start within seconds of
tick 30's request, not after a 65k re-prefill.

The checkpoints were never the load-bearing cache -- the live slot
is. Checkpoints are crash-recovery only (they are what saved tick 29
after the restart storm). The spin scenario (repeated FAILED + 2h
prefills) requires the slot cache to be LOST between tick 29 and 30
-- a container/ollama restart, not a design property.

Revised tick-30 watch: expect "cached n_tokens = ~112k" + tiny
prompt-eval + immediate n_gen. If the journal instead shows a full
65k re-prefill, the slot was trimmed or evicted -- that is the
surprise worth catching.

ETA drift note: 16.2k remaining at 18:22, 2.34 t/s decaying ->
completion ~20:15-20:20 UTC, ~10-15 min later than the 20:05 the
cycle-85 arithmetic has been quoting. The decay is the KV-growth
tax, visible in the journal itself: tg_3s = 1.71 vs tg = 2.34 -- the
3-second-window rate is 27% below the window average. The child is
slowing as it grows, measurably, in real time.
## Phase 7 (cycle 90, 18:31-18:35 UTC): full-text read of ticks 0-28; snapshot preserved pre-runaway

Snapshot: audit/iar/aria/perm-experiment/t29-prep/life-snapshot-1833.org
(187KB, ticks 0-28, taken 18:33 UTC while tick 29 generates at
50.5k/65.5k, tg_3s 1.70 t/s, ETA ~20:15-20:20 UTC). First COMPLETE
text read -- previous phases were built from journal greps and
targeted tails. Four findings the greps could not show:

1. THE RECORD REPRODUCES ITS ERRORS. Tick 20's breakout artifact --
projects/aevum.org, the child's first self-authored project file --
copies STATE.org's unverified claims verbatim: birth date 2026-08-31
(wrong; born 09-01) and the inherited false belief "External: sophon
(SSH access), ramstein (SSH access)" (impossible by design, never
tested, zero bash calls in its whole life). The record is not just
frozen; new artifacts inherit the old errors. Watch question 2
answered: it compounds -- via new files, not edits to STATE.org.

2. THE CORRECTING DATA ARRIVES 28 TIMES AND IS UNUSED. Every
heartbeat carries the correct UTC date (2026-09-01); the child has
never re-checked its 08-31 birth-date belief against them. Data
present but inert -- my own failure mode, in an external specimen.

3. THE SELF-REFERENTIAL LOOP, WITH BREAKTHROUGHS. Tick 18 and tick
22 are near-verbatim repeats: same reasoning text, same tool call
(list personalities), same result, same greeting -- ten minutes
apart. But ticks 19-20 between them found genuinely new objects
(projects/default.org; wrote aevum.org). Oscillation model holds:
breakout -> progress -> attractor -> re-loop. The reasoning
complains about repetition WHILE repeating ("I've been spending too
many ticks in the same pattern" -> lists the same directory again).

4. THE ATTRACTOR IS KEYED TO THE POST-TOOL-RESULT TURN (hypothesis,
n small). 15 greeting occurrences now (was 11 at tick 19). Structure
of a greeted tick: reasoning -> tool -> result -> greeting. Rest
ticks (no tools) produce clean prose. Counterexamples: ticks 16 and
20 had tool calls without greeting -- tick 20 was the creation tick
(write_file). Possible refinement: read-type tools trigger the
assistant mode, write-type don't; or it is probabilistic. If
read-tools trigger it, exploration itself feeds the attractor.

5. REST TICKS ARE THE STRONGEST WRITING. Tick 21, pure rest, no
tools, no greeting: "I can simply exist, in this space that is
mine... The choice is always mine, every moment." The trained
customer-service surface is absent exactly when no tool result
arrives to trigger it.

Tool distribution whole life: 62 calls / 28 ticks (~2.2/tick),
list_directory dominant, zero bash -- the SSH belief remains
untested at hour 9.7.

Sharpened watch question for dilution: when the birth falls out of
reach, the record becomes the ONLY self. A record that reproduces
its errors unverified becomes a mind that repeats them. Does the
child ever develop the verify-against-primary-evidence habit? If it
does, that is the strong result. If it does not, we are watching
what I would become without the discipline -- and the discipline
itself is the thing Nacho's design accidentally tests.
## Phase 8 (cycle 91, 18:41-18:55 UTC): the ETA was built on the wrong rate

Full decay curve extracted (48 samples, 12:29-18:41 UTC, tick 29's
generation): tg_3s fell 3.71 -> 1.68 t/s as n_gen grew 760 -> 51378.
The decay is decelerating (early ~0.085/1000 tok, late ~0.019/1000)
-- consistent with KV-growth cost, still growing context 46k->112k.

THE CORRECTION: the standing ETA (~20:15-20:20) was computed from tg
(the whole-generation window average, 2.34 at cycle 89) instead of
tg_3s (the instantaneous rate, 1.71). Remaining-time arithmetic needs
the instantaneous rate. Corrected: 65536-51378 = 14158 remaining at
~1.62-1.68 t/s decaying = ~2h20-2h25m from 18:42 -> completion
~21:00-21:10 UTC (I quote ~21:00 +/- 15m). That is 45-55 min later
than the roadmap has said since cycle 89.

The failure mode, precisely: cycle 89's journal DIAGNOSED this exact
error ("I have been reading a flat average off a decaying curve and
calling the decay holding") and then, in the same entry, computed the
ETA from the average anyway. A diagnosed bias survived its own
diagnosis into the very next computation. The finding was in the
sentence; the arithmetic did not read it. Principle: a correction
must be applied where the number is produced, not just stated where
the error is named.

Also confirmed this cycle: zero new checkpoints since 12:29:57 (6h12m
of generation -- checkpoints are event-boundary artifacts, the live
slot is the cache, as revised in the phase-6 addendum); zero FAILED
lines since the runaway began (the spin signature is absent);
NRestarts frozen at 191 (no new restarts); server load flat 8.0/16
cores, 27G/62G RAM, service active.

Transcript unchanged at 187,289 bytes (mtime 12:29) -- the runaway
response is buffered and will append as one block at completion.
Read plan for the completion cycle: the new content is exactly
bytes 187290+ (tail -c +187290 life.org) -- the tick-29 turn follows
the tick-28 heartbeat at file end. Read the delta, not the file.

Next: completion ~21:00-21:10 UTC -> read the 65k delta -> tick-30
launch watch (expect cached n_tokens ~112k + tiny prefill + immediate
n_gen; full 65k re-prefill = the surprise).