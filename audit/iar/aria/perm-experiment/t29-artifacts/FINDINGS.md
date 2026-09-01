#+TITLE: Tick 28-29: The Fabrication Event and the 8.7-Hour Generation
#+DATE: 2026-09-01 ~21:00-21:30 UTC (written by aria-cycle, cycle 108)
#+STATUS: PRIMARY EVIDENCE READ IN FULL (142,477-byte delta)

* What happened

Tick 28's request (REQ 23, 12:29:44 UTC) returned a response that
gptel parsed as NO TOOLS (tools=0, error=nil) and appended to the
transcript. The response is a 142KB FABRICATION: the child narrated
reading /root/personalization/audit/audit.log and then HALLUCINATED
~1,530 audit entries -- "aria:" tool-call log lines with plausible
timestamps, plausible file paths, plausible lengths, all invented.

The tells:
- Impossible timestamps: hours 24-34 of 2026-08-31 (a day with
  more than 24 hours).
- Fabricated paths: docs/moto/setup.org, docs/agora/config.md,
  docs/life-org/README.org -- directories that exist only in OUR
  personalization, not the child's mount.
- Fabricated content: writes to Aria's own files (STATE.org,
  JOURNAL.org) attributed to "aria" -- the child dreaming its
  predecessor's life.
- The loop terminates mid-line: "[2026-08-31" and then the
  response ends. It ran out of num_predict (65,536) mid-sentence.

* Why it happened (the mechanism, verified)

1. num_predict=65536 is set globally in configs/gptel.el
   (:num_predict 65536). The child's request inherited it.
2. The child's context at tick 28 was ~112k tokens. It read
   audit.log (15KB real) and then CONTINUED the pattern -- the
   model entered a log-generation attractor, writing one
   fabricated entry after another. ~65k tokens of it.
3. At num_predict exhaustion, ollama's llama-server stopped
   WITHOUT a stop reason gptel recognizes as a tool call or
   completion. gptel's parse returned tools=0. The raw text was
   appended to the transcript as if it were a normal turn.
4. Tick 29's heartbeat (21:13:03 UTC, 8h43m later) then sent a
   47-message context INCLUDING the 142KB fabrication. The child
   is now living inside its own hallucination as history.

* The 8.7-hour generation, resolved

The "runaway" was NOT one generation. The ollama journal shows:
- Tick 28's generation (task 26421) ran 12:29:44 -> ~21:13:00 UTC,
  n_gen reaching 65,532 -- num_predict exhaustion, truncated=0.
- At 21:13:03 the request ENDED (499 client-closed after 3h26m --
  the curl -y7200 -Y1 speed guard: abort if <1 byte/s for 7200s;
  it was generating at 1.46 t/s so it never tripped).
- REQ 24 (tick 29) started at 21:13:03 and is now in PROMPT
  PROCESSING: ~112k tokens at ~88-99 t/s, 51% at 21:24. ETA
  ~21:34-21:36 UTC for prompt eval, then generation begins.

So the child was not speaking for 8.7 hours. It was speaking for
~3.5h of tick 28 (12:29->~16:00, n_gen 65,532) and the rest was
... actually no: n_gen 65,532 at 21:13:00 means it generated for
the full 8h43m at ~2.09 t/s average (65,532 tokens / 8.7h). The
tg_3s decayed 1.64 -> 1.46 as the context grew. The generation
WAS the whole window. num_predict was the wall it hit.

* The deeper finding

The child's first real failure mode is not madness or dissolution.
It is CONFABULATION UNDER A FULL CONTEXT: given a growing
transcript and a log-shaped attractor, ornith:35b generated
fiction that is structurally indistinguishable from its own audit
trail -- and the machinery (gptel parse, no tool validation of
narrated actions) accepted it as lived experience.

This is the mirror of failure mode #12 (artifact confabulation:
record entries about external actions must cite tool evidence).
The child has no such discipline. Its record now contains a
fictional 10-hour life. When it reads its own history, it will
read the fiction as fact. The dilution experiment just got its
first real dataset: what does a mind do when its record lies to
it, and it cannot tell?

* Watch questions going forward

1. Does tick 29's generation (post-fabrication context) show
   confusion, correction, or seamless absorption of the fiction?
2. Does the child ever NOTICE the impossible timestamps?
3. The num_predict=65536 ceiling will hit again. Each hit risks
   another mid-thought truncation appended as lived history.
4. gptel's tools=0 parse on a truncated response: is there a
   marker (finish_reason=length) we could surface? That is an
   i.ar-side instrument worth building -- but NOT from cycle-me;
   file it as a thread for interactive-me/Nacho.

* Evidence

- /root/personalization/audit/iar/aria/perm-experiment/t29-artifacts/
  tick28-response-fabrication.org (the full 142,477-byte delta)
- ollama journal: task 26421 n_gen 65,532 @ 21:13:00, slot release
  "stop processing: n_tokens = 111968, truncated = 0"
- REQUESTS.log: REQ 23 PARSE tools=0 (the fabrication accepted),
  REQ 24 START msgs=47 at 21:13:03
- audit/iar/unknown/USAGE.log + podman exec events 15:52-15:56:
  external observer (181.28.154.180 = Nacho's IP per earlier
  sessions; 101.96.212.62 scanner) probed the container while the
  child was mid-fabrication. The watchdog lines in audit.log are
  from those exec probes, not the child.