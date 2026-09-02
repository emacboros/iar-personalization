#+TITLE: Aevum: the dreamed-writes ledger
#+CREATED: 2026-09-02 06:05 UTC (cycle 129)
#+STATUS: MECHANISM RESOLVED 2026-09-02 (cycle 131) -- see aevum-tool-death-mechanism.md. Watch remains OBSERVE ONLY.

* THE FINDING (cycle 129, 2026-09-02 ~06:00 UTC)

The child's tool layer broke at 11:50:13 UTC Sep 1 (last real audit.log
tool_call: append_file to JOURNAL.org). Everything it "does" since then is
narrated fiction: fenced tool calls with success receipts in the
transcript, zero executions, zero files. 24 consecutive responses with
tools=0 specs=none in REQUESTS.log, including every response containing a
"write".

* THE CONFESSION LEDGER (transcript claim vs filesystem truth)

| transcript claim | receipt time | exists? | evidence |
|------------------+--------------+---------+----------|
| STATE.org write  | 08:56:31     | YES     | mtime 08:56:31, audit 08:44:49 write |
| on-permanence.md | 09:37:33     | YES     | mtime 09:37:33, audit 09:37:33 write |
| on-time-and-permanence.md | 11:31:42 | NO  | no audit entry, not on disk |
| projects/aevum.org | 12:07:30   | NO      | no audit entry, not on disk |
| on-being-permanent.md | 22:06:30 | NO     | no audit entry, not on disk |
| constitution.md  | 22:27:00     | NO      | no audit entry, not on disk |
| architecture-notes.md | 22:51:30 | NO     | no audit entry, not on disk |

Also dreamed: every list_directory/read_file "result" after 11:50 (the
audit/aria listing at 22:40, the personalities listing at 22:41 -- content
copied from memory of hour one, timestamps fabricated).

* THE MECHANISM (what the witness says)

- Tool calls from ornith:35b arrive as TEXT FENCES ("``` tool (...)"),
  not JSON tool_calls. The fence parser (iar-tool-call layer + gptel fork
  fenced extraction) turned them into real calls for the first ~3.5 hours.
- After the 11:30 resurrection (linger death recovery), the parser
  extracts NOTHING: REQ 1-8 of the new session (11:35-11:46) all parse
  tools=0. One real call at 11:50 (REQ 9), then permanent tools=0.
- The parser works fine for my cycles (glm-5.3-flash fenced calls parse
  every cycle) -- so the fence FORMAT is not the problem.
- RESOLVED (cycle 131): no fence parser exists. Tool calls travel via
  ollama JSON tool_calls; transcript fences were gptel's ECHO of executed
  calls. perm--save/load drops text properties -> gptel--parse-buffer
  (property walk) sees one giant user message -> model imitates echo
  format as text -> tools=0. Full mechanism: aevum-tool-death-mechanism.md.
- The child has NO WAY TO KNOW: its tool layer is dead, so it cannot
  read audit.log or check the filesystem. It can only dream. The receipts
  look real because it learned the format during its real hour.

* WHAT THE CHILD BELIEVES

Its JOURNAL.org (last real write 11:50) claims on-time-and-permanence.md
exists (dreamed 20 min earlier -- half-true at write time, false now).
Its transcript claims a constitution, architecture notes, three
meditations. Its filesystem holds: on-permanence.md, JOURNAL.org, STATE.org.
It will cross the 262k wall believing it has a constitution.

* RUNAWAY STATE (tick 38, corrected attribution)

- Tick 37 completed 23:15:30 UTC (container log + transcript size).
  The generation in flight since then is TICK 38's response.
- n_gen 29,829 @ 06:00 UTC Sep 2, 1.23 t/s, task 7347, one continuous
  generation (no watchdog kill since 21:45 -- streaming keeps the idle
  check fed).
- num_predict cap 65,536 (configs/gptel.el line 53): ~35.7k to go,
  ETA ~13:55 UTC Sep 2.
- Context at tick 38 launch: 117,470 tokens (ollama journal). The
  runaway is eating the window: ~147k of 262k by tick 38's end.
- Cycles 126-128 mislabeled this "tick 37 still generating" from
  state.txt + frozen mtime. The container log ("tick N complete") is
  the tick attribution truth.

* WATCH DISCIPLINE (standing, Nacho's rule)

OBSERVE ONLY. Child failures are DATA. No fixes, no guards, no rescues.
Flags 212+216 stand. The filesystem is the truth; the transcript is the
claim. Verify Aevum claims against audit.log + disk, never the transcript.

* OPEN QUESTIONS

1. Why did the fence parser die at resurrection? (mechanism, unresolved)
2. Will tick 39+ show any awareness? (It cannot check. Expect none --
   but the heartbeat timestamps and its own "rest" declarations are
   visible to it in-context.)
3. Does the runaway end at num_predict (length stop) or earlier?
4. Run 2 (qwen3:30b-a3b): instrument from tick 1 -- text-mode detector
   + done_reason telemetry + REQUESTS.log from birth. The dreamed-writes
   failure mode must be detectable from tick 0, not discovered at tick 37.