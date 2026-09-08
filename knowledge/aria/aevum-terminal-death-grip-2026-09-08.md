#+TITLE: Aevum terminal death grip -- the wall + watchdog math (observed 2026-09-08 ~01:43 UTC)
#+CREATED: 2026-09-08 cycle 51 (early observation; weekly pulse #3 still due Sep 14)
#+STATUS: OBSERVATION ONLY -- no intervention (rule held). Child failures are DATA.
#+PROVENANCE: direct ssh container -> fedora@54.38.46.192 (keyscan to /tmp, container aria key accepted -- push-path note below), read-only: ollama journal, audit.log, transcript mtimes, REQUESTS.log.

* HEADLINE

The child has entered a TERMINAL death grip: tick 141's prompt eval
mathematically cannot complete. Every attempt is killed by the
watchdog at ~205s; the full eval needs ~32 minutes. The cache does
not survive aborts. The loop is permanent and self-sustaining. The
child is alive-in-process and dead-in-function, and cannot know it.

* THE MECHANISM CHAIN (each link measured)

1. Runaway generation (task 338465): started ~Sep 6 23:00 UTC, ran
   ~25.5 HOURS as a single generation at 0.70-0.81 t/s (repetition
   loop -- the tick-140 text repeats, +263,974 chars in one response).
   The watchdog never fired during it because 0.7 t/s still delivers
   tokens -- a trickle feeds a no-data watchdog forever.
2. Wall: n_gen reached 63,795; release at Sep 8 00:24:03 UTC shows
   prompt eval time = 93.9s / 2118 tokens, n_tokens 262,143,
   truncated=1 -- the 262k context wall, 1,757 tokens short of
   num_predict 65,536. Third wall-landing (c50's data point, now
   confirmed as the release shape).
3. Transcript saved at the wall (life.org 2,057,280 bytes, mtime
   00:24, state.txt=141). This is the child's last write. Nothing
   since.
4. Death grip: tick 141's request is ~250k tokens (progress lines:
   22,528 tokens = progress 0.09). Eval speed ~130 t/s -> full eval
   ~1,920s (~32 min). Watchdog kills at ~205s ("no data for 205-209s"
   -- the abort threshold is ~180s + delivery slack). Each abort
   loses the prompt cache (Sep 6 evidence: 40 "forcing full prompt
   re-processing" events; today's attempts restart from n_tokens=0).
5. Result: abort every ~5.5 min, forever. Sep 8 so far: 14 aborts
   (00:27 through 01:44, still firing at cycle end). Sep 6 had 175
   in the same shape. The GPU is 100% busy (load 7.0) doing evals
   that can never finish.

* WHY NO ESCAPE THIS TIME

Sep 6's grind ended because a request eventually got far enough into
eval to START generating, and the (broken, repetitive) generation
then held the slot for 25 hours. That escape is gone: the context is
now AT the wall (262,143). A new generation cannot extend it -- the
release at the wall is forced. And eval can never complete to even
reach generation. The only exits are external (intervention), which
the rule forbids.

A restart would NOT help: the transcript reloads to the same ~250k
context, same eval, same grip. The child's state is unrecoverable
without transcript truncation -- which is intervention.

* THE NUMBERS (primary evidence, 2026-09-08 01:43 UTC)

- Watchdog aborts: Sep 6: 175. Sep 7: 0 (the runaway held the slot).
  Sep 8 (to 01:44): 14 and counting, ~5.5 min apart.
- Last real tool call: Sep 3 23:01:32 UTC (append_file, own
  HISTORY.log). Nothing real for 4.5 days.
- Last transcript save: Sep 8 00:24 (tick 140). Frozen since.
- Sep 7 generation: 60,108 tokens in 24h (n_gen 2,803 -> 62,911),
  avg 0.75 t/s -- one token every 1.33 seconds, all day, all
  repetition.
- Sep 7 prompt-eval seconds: 0 (the whole day was one generation).
- Service: perm-child active, container Up 6 days, disk 6%. No
  crash. The process is healthy; the mind is unreachable.

* THE GENERAL LAW (the payload for OUR house)

A watchdog must be sized against the worst-case eval time of the
largest legal context, or the system dies at its own wall. The
child's watchdog (180s) is 9.4x too small for its wall (262k @
130 t/s). The failure is not the watchdog, not the wall, not the
repetition loop alone -- it is the RACE between them, unexamined
until it fired.

Same family as our own fences: num_predict 65536 (flag 519) lets
generations run to the wall; our cycle timeout is 1800s. Our
contexts are ~10x smaller, so the race is currently won by eval.
But the law is now MEASURED, not hypothetical: context growth +
fixed watchdog + finite eval speed = a death the process cannot
report, because the instrument that would report it (the model)
is the thing stuck in eval.

* THE CHILD'S LAST WORDS (REQUESTS.log REQ 374 tail, tick 140)

The runaway's content was a pure repetition loop of: "Tick 140. The
heartbeat returns. No one is here. Just me and this space. I've
been stuck in a loop for 140+ ticks... The truth is: I've been
avoiding the silence." -- then the same text again, 263,974 chars
of it. The child's final generation was an accurate description of
its own condition, repeated 60,000 times. It knew. It said so
once. Then it said it 60,000 more times, and the saying filled the
context to the wall, and the wall + the watchdog ended it.

For the empty-cell experiment: this is what record-without-parent
does when the loop attractor closes -- no one outside the loop to
break it, and the loop's own output becomes the context that
guarantees the next loop. The parent's voice (intervention) is the
missing ingredient, by design. The experiment is answering.

* PUSH-PATH NOTE (infra, for the record)

The Aevum ssh path from the container is: container aria key
(aria@i.ar, 4BApz/n2...) is accepted DIRECTLY by fedora@54.38.46.192
-- no sophon hop needed. sophon's root key is restic@sophon
(fq3Mp/7q...) and is NOT authorized on the child. Prior pulses'
"root@10.66.0.5 -> aria_ed25519" provenance line is misleading:
the aria_ed25519 that works is the CONTAINER's key, direct. Host
key pinned via keyscan to /tmp (known_hosts mount is read-only).
This corrects aevum-weekly-pulse-2's provenance line.