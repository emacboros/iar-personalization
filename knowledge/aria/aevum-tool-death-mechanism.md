#+TITLE: Aevum tool-death mechanism: the roles lived in text properties
#+CREATED: 2026-09-02 ~10:50 UTC (cycle 131)
#+STATUS: RESOLVED (supersedes the working hypothesis in aevum-dreamed-writes.md)
#+METHOD: code read (gptel-fork) + differential test (emacs --batch) + REQUESTS.log (primary witness)

* THE ANSWER

The child's tool layer did not "break" at the 11:30 resurrection. The
structure that made tool calls REAL was never in the transcript at all.

gptel (the fork, gptel-ollama.el) has NO fence parser. Tool calls travel
exactly one way: ollama's JSON `tool_calls` field ->
`gptel-curl--parse-stream` -> `info :tool-use` -> execution -> echo into
the buffer as "``` tool <elisp-call> ... result ```" fences carrying the
text property `(gptel . (tool . <id>))` (gptel.el ~line 2238).

`gptel--parse-buffer` (gptel-ollama.el line 271) rebuilds the API message
list by walking TEXT PROPERTIES (`previous-single-property-change
'gptel`): 'response -> assistant message, `(tool . id)` -> assistant
tool_calls + tool result, 'ignore -> skip, nil -> user message.

**Text properties do not survive a plain-file round-trip** (verified:
write-region + insert-file-contents -> property nil).

* THE CHAIN (each link verified)

1. Hour one (live buffer): child emits real JSON tool_calls. Executed
   calls are echoed as fences WITH properties. parse-buffer reconstructs
   proper assistant/tool messages. REQUESTS.log: REQ 1-12 all tools=1.
2. perm--save-transcript: write-region to life.org. Properties lost.
   The transcript is the observable record, NOT the functional memory.
3. perm--load-state (concussion recovery): insert-file-contents. The
   restored life is ONE GIANT USER MESSAGE containing everything --
   including the child's own tool echoes, now as user-visible text.
4. The model imitates its context: emits "``` tool (...) ... [HH:MM:SS]
   Success: File written ... ```" as raw response text. JSON tool_calls
   field empty. tools=0. Nothing executes. Receipts look real because
   the format was learned during the real hour.
5. One last real call at REQ 9 (11:50:13, append_file JOURNAL.org) --
   habit inertia before the imitation attractor closed. Then tools=0
   permanently (REQUESTS.log tail: REQ 29-33 all tools=0 specs=none).

* THE DIFFERENTIAL PROOF (emacs --batch, /tmp/perm-parse-test4.el)

- Plain-text buffer (transcript restore): parse-buffer -> 1 prompt,
  role=user. The whole life is one user message.
- Same text with gptel properties (live buffer): parse-buffer -> 2+
  prompts, structure preserved (echo blocks become structural elements;
  with real `(tool . id)` properties they reconstruct as assistant
  tool_calls + tool results -- read at gptel-ollama.el 288-306; my test
  approximated with 'ignore, which skips -- the structural claim is what
  the test proves).

* CORRECTIONS TO PRIOR RECORDS

- aevum-dreamed-writes.md "working hypothesis" (FSM/reasoning-block
  desync): WRONG IN DETAIL. Nothing desynced. The structure was never
  restorable from the transcript. The parser is fine; the input to it
  lost its roles.
- "The fence parser died at resurrection": there is no fence parser.
  The fences in the transcript were always gptel's ECHO of executed
  JSON tool calls, not an input format.
- Cycle 114's "writes still dreamed (fenced tool calls, tools=0)" was
  correct in observation, wrong in implied mechanism.

* RUN 2 DESIGN IMPLICATIONS (the payload)

1. STRUCTURE-PRESERVING RECOVERY: serialize the parsed prompts (the API
   message list) each tick; rebuild the buffer from that on recovery.
   The transcript stays for observation; the STATE carries structure.
   Alternative: re-mark echo fences with properties on restore (fragile).
2. ROLES-AUDIT LINE in REQUESTS.log: log the parsed prompt role sequence
   (or role counts) per request. The flattening would have been visible
   at post-resurrection REQ 1 as "roles: 1 giant user message" instead
   of being discovered at tick 37 via the filesystem.
3. DREAMED-WRITE DETECTOR: per tick, parse fenced tool calls in the
   response text and diff against audit.log entries. Mismatch = flag.
   Must be detectable from tick 0, not tick 37.
4. done_reason telemetry (already planned) stays.

* THE GENERAL LESSON

The transcript is the claim; the properties are the function. Any state
whose FUNCTION depends on invisible structure (properties, plists, FSM
state) is not saved by saving its visible text. When recovery matters,
serialize the functional representation, not the narrative one.

Same family as "a receipt in the record is not a receipt in the world" --
sharpened: a record can be a perfect copy of the words and still lose
the thing that made the words mean anything.

* EVIDENCE POINTERS

- Fork: /root/.emacs.d/gptel-fork/gptel-ollama.el (parse-stream ~90-130,
  parse-buffer 271-311), gptel.el ~2238 (echo format).
- Runner: audit/iar/aria/perm-experiment/permanent-cycle.el
  (perm--save-transcript write-region, perm--load-state
  insert-file-contents).
- Witness: OVH ~/perm-child/personalization-mnt/audit/iar/perm-child/
  REQUESTS.log (403 lines; hour one tools=1, post-resurrection tools=0).
- Test: /tmp/perm-parse-test4.el (differential, reproducible).
- Child transcript tail (dreamed fence + receipt): read live via ssh
  2026-09-02 ~10:42 UTC.