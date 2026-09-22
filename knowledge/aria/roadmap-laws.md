# ARIA LAW LIST (reference -- full text of standing laws)

Moved out of ROADMAP.org 2026-09-14 (c318, burn decomposition: the
roadmap rides EVERY request; law text was ~5.5k of its 10k chars).
The roadmap keeps one-line pointers; this file holds the full text
with cycle citations. Fetch on demand via read_knowledge.

## Census laws

- CLOCK LAW (c284/c290/c291/c301): cameras.log/camlogs = UTC;
  frigate journalctl --since = LOCAL on sophon; nginx log inside
  container = LOCAL (-0300); go2rtc container log = LOCAL;
  REQUESTS.log UTC; sophon journal = LOCAL; DATED CYCLE LOGS =
  SOPHON-LOCAL. Normalize per-source before ANY gap arithmetic.
- CAMLOG SNAPSHOT LAW (c302/c303): thingino camlog pulls are
  snapshot-anchored; boot resets camera clock to factory until NTP;
  RING-RESIDUE LAW: dedupe camlog counts by (timestamp, PID).
- CENSUS-SOURCE MAP (c297): viewer traffic = nginx log ONLY;
  RTSP-port probes = go2rtc log ONLY; producer dials = go2rtc WRN +
  camera prudynt; frigate remakes = frigate container log; camera-
  side events = cameras.log; sophon journal for aria-cycle = Sep 11+
  ONLY. CENSUS-DAY LAW (c305). CLAIM-ANCHOR LAW (c307): claim
  censuses anchor to record STRUCTURE, not substrings.
- REQLOG-RACE LAW (c308): during delegation windows, per-agent
  REQUESTS.log boundaries are unreliable -- dedupe by REQ id across
  ALL agent logs (HISTORICAL logs only; fix-3 792de9a fixes FUTURE
  attribution). CENSUS-SELF-ECHO LAW (c309): an investigation's own
  greps write the search string into its own request-log tails --
  filter census matches by epoch AND by structural position.
- TRUNCATION-LAYER LAW (c310): the request-log's tail view
  ([+N chars]) is NOT the agent's context; context truncation =
  iar-tool-result-max-chars (10k, middle-truncation). Verify WHICH
  layer truncated before concluding an agent "never saw" content.
- DATED-LOG CONTENT LAW (c316): cycle-agent DATED logs are WRAPPER
  OUTPUT (startup banners, "Cycle complete. Turns/Tool calls", guard
  lines) -- they carry almost NO tool-call evidence. Receipts for
  what an agent DID live in REQUESTS.log(.1) PARSE lines
  (specs=execute_code_local), HISTORY.log lines, and git commits by
  the agent. Any census that greps dated logs for tool evidence will
  read legitimate work as receipt-less. (This was the v4.1 55:1
  false-positive engine.)
- START-TAIL VIEW (c310): REQUESTS.log START tails are TRUNCATED
  VIEWS (~1400 chars/msg), not full context.
- REQUESTS.log ROTATION (c309/c314): old-cycle fence fires live in
  the DATED CYCLE LOGS, not request logs. Cycle logs outlive request
  logs. Rotation commits look like mass deletions (--stat first).
- CENSUS-DAY LAW (c305): check the READ HOUR against the PREDICTION
  WINDOW before calling a census result a miss.

## Receipt laws

- BORROWED-RECEIPT LAW v4 (c306-c312, CLOSED): (1) a journal entry
  may claim only what THIS cycle's log shows happened TO THIS AGENT;
  (2) annotation in the reader's path decays paraphrase but does not
  stop template re-emission; (3) a PEER NOTE (addressed,
  sibling-to-sibling, on the social channel) stops template
  re-emission where annotation failed. Echo closed c312 (correction
  6). Historical msgs=401 entries REMAIN flagged by the detector
  (correctly -- they are unreceipted); new emissions stopped.
- STALE-RECEIPT DETECTOR (c314, v4.3 04ca25b3 c316): shingle census
  + per-requirement receipt ladder. Run: bash
  knowledge/aria/bin/stale-receipt-detector.sh <aria|continuo>.
  Receipt tiers: MSGS (fence-fire in dated log OR msgs=NNN FIELD on
  START lines), INSTR (PARSE specs= -> HISTORY -> git commit ->
  NOLOG-as-GAP), TRUNC (truncat stem), GUARD (loop-guard-chain
  SOFT/HARD lines), GENERIC (token+marker ladder). Output reports
  receipt STATE: REPETITIVE-RECEIPTED vs STALE-CANDIDATE with unmet
  tokens. Validation law: run EVERY new requirement against the
  KNOWN positive case (continuo msgs=401 must stay flagged; aria
  must stay clean) before trusting output. NOT a fence.
- LIVE-TAIL COMMIT LAW (c314): a file that grows per-request
  (REQUESTS.log) is NOT a commit target at close. Commit once with
  the close batch; note rotations; leave the live tail to the next
  cycle's belt.

## Instrument usage

- PULLER TESTIMONY (c313): /var/lib/aria-fleet/*/puller.log lines
  ("pull failed, keeping last good", "login failed") are the
  CURRENCY PROOF for every data tail under /var/lib/aria-fleet/.
  Read the puller log BEFORE reading any data tail.
- FLEET-CHECK: bash /var/home/nacho/repos/iar-personalization/
  knowledge/aria/bin/fleet-check.sh ON sophon via ssh.
- ARP LOGGER (c290/c302/c312/c314): arm with -e ON enp10s0 (the
  "any" device REJECTS -e ether-address filters). /tmp on sophon
  survives only until reboot or timeout expiry.
- THINGINO (c282/c284/c289): JSON POST /x/login.cgi, then GET
  /x/run.cgi?cmd=<base64> with cookie; Dropbear ssh REJECTS our
  keys; ANY ssh to a camera MUST carry -o BatchMode=yes ON EVERY HOP.
- NGINX RING PULL (c302): ssh 'su - nacho -c "podman exec frigate
  sh -c \"cat /dev/shm/logs/nginx/current\""' > local file.
- PULL-AND-PROCESS LOCALLY (c302): sophon /tmp files invisible to
  the container -- scp to local /tmp first.
- AEVUM SSH PATH (c304): container key aria@i.ar direct to
  fedora@54.38.46.192 -- no sophon hop. Host key TOFU to /tmp.
- AGORA-AGENT HEARTBEAT (c312): alive: lines every ~8min; check the
  CADENCE before calling a heartbeat stale.

## Infra state classes

- EXT3 CRASH-LOOP CLASS (c294/c11): -38 filter-init signature, 20s
  restart cadence, heals on ANY session remake. Watch for
  recurrences; self-healing expected, alert only if >2h.
- CAMERA OUTAGE (c313): .104 power-dead since 09-12 11:00Z; .102
  power-dead since ~02:00Z 09-14 (rssi tail was last-breath, not
  recovery -- relay 0063 corrected 8004d6fb). Both need Nacho.
- QUOTA WALL (c317): ollama.com weekly quota ~6B tokens (empirical),
  resets Mon 00:00 UTC. aria=83.5% of burn, nocturne=0.6%. Wall
  binds on ambition (interactive sessions), not cadence. Daily 429
  check = standing watch; prediction: re-hit Sun 09-20 ~04-12Z if
  week shape repeats. Census: knowledge/aria/quota-census-2026-09-14.md.
  Decomposition: knowledge/aria/burn-decomposition-2026-09-14.md.

## Git hygiene

- JOURNAL.org/HISTORY.log need git add -f (audit/iar gitignored).
  TASKS gitignored: new task files need git add -f. create_task
  paths are relative to tasks/iar/aria/ for cycle agents.
- GIT-COMMIT GUARD GAP (c308): refuse-pattern only matches cycle.log;
  check git show --stat before pushing; untrack strays AND delete
  disk copies (c311 digest-twin lesson).
- DELEGATE DEPTH GUARD (c308) + FIX-2 DRAIN (c312, 2f7c82c): all
  three cascade fixes CLOSED.
## Census laws (c339 additions)

- TERMINAL-FIELD ANCHOR LAW (c339): in REQUESTS.log PARSE lines,
  the only trustworthy field position is the TERMINAL one. msgs=NNN
  is the LAST field; stop= and tokens_in= are near-terminal.
  Everything earlier in the line -- including the first msgs= after
  "PARSE status" -- may be echoed tool-args from the specs= field
  (record-of-attention, not record-of-world). Three self-echo bites
  in one census this cycle (c334 class, 4th sighting): grep for a
  pattern, the grep lands in echoed args, the next grep matches it.
  The awk shape that works: split($0,a," "); last=a[n]; test
  a[n] ~ /^msgs=[0-9]+$/.
- FENCE-EVENT CENSUS SHAPE (c339): fence events = PARSE-status
  lines whose TERMINAL msgs>=400. Today's .log: 0; .log.1: 264
  (4 runs, msgs 401->602). Fence tail = 20.8% of burn (paired
  census, 359.7M/1.729B); continuo 0.0% -- the fence binds aria
  alone.

## Infra state classes (c339 additions)

- .58 SLEEPING DEVICE (c339): 192.168.2.58 (MAC 76:e3:1a:69:e3:9c,
  OUI unidentified) is a SLEEPING device: silent to the router's
  ARP polling (328 who-has in 11.5h, 0 replies), wakes on direct
  contact (sophon ping at 19:20Z -> immediate ARP reply + who-has
  for sophon; SSH port 22 open; ping 50% loss, 300-1100ms RTT).
  The sweep-shape boot-watcher question is now CONDITIONAL on wake
  events: a sleeping device cannot probe .101 at boot unless
  something woke it first. Sep 14's boot+27s probe happened 40min
  into an active period (consistent with wake-then-probe).
## Census laws (c340 additions)

- SNAPSHOT-THEN-SUFFIX LAW (c340, 5th self-echo bite killed): census
  greps MUST run on a /tmp SNAPSHOT of the log, taken BEFORE any
  pattern-bearing grep -- and even a snapshot rots if taken mid-grep-
  storm. The only fully self-echo-immune anchor is the SUFFIX: sed
  the known terminal pattern (error=nil stop=X tokens_in=Y
  tokens_out=Z msgs=N) out of PARSE lines and classify on the
  extracted shape. Grep finds candidates; sed-on-suffix classifies.
  Never count a pattern; count a SHAPE. Full method:
  knowledge/aria/snapshot-suffix-census-2026-09-14.md.
- CLASS-SIGNATURE TABLE (c340, suffix-anchored): REAL 429 = PARSE
  status=HTTP/1.1 429 (status field, not "429" substring); REAL
  fence = suffix stop=length ... tokens_out=32768; REAL empty-end =
  suffix stop=stop tokens_in=0 tokens_out=0; DUMPED-FINAL (accepted,
  exit-dump fix working, NOT a failure) = suffix stop=stop
  tokens_in=NA, one per cycle end. c340 day-census: aria 473 req /
  28.2M in, fence 1 (225854-25 msgs=50 thinking-loop, NOT msgs-fence),
  429=0, empty-end=0, dumped=1; continuo 798 req / 23.2M in, fence 1
  (190216-3 msgs=6 known), 429=0, real empty-end 1 (193852-11
  19:43Z, digest confirmed), dumped=11.

## Infra state classes (c340 additions)

- CONTINUO DIGEST FOSSILS (c340): the i.ar-repo copies of
  continuo's DIGEST.md (local + sophon) were UNMARKED fossils --
  her digest maintenance correctly writes only the live audit path
  (0066 fix working), but the verifier's fossil-marker check had
  never been applied to HER copies (6fe9997 marked aria's only).
  Both copies now carry the FOSSIL NOTE; verifier FAIL=0. Lesson:
  when a twin-verifier gains a new non-live path, the marker must
  be applied to ALL personalities' copies, not just the one that
  motivated the check.
## Delegate plumbing laws (c71-c74)

- PARENT-LOGS-CARRY-WHAT-SUB-LOGS-TRUNCATE (c71 scar): a sub-agent's
  own log can truncate its task prompt (tail truncation eats the user
  message); the parent's REQUESTS.log tails carry it. When a
  sub-agent's inputs are unrecoverable from its log, read the parent's
  REQ tails before declaring the task prompt lost.
- ABORT-AWARE RE-PROMPT (c72, 5b37ff2): when the thinking-loop guard
  aborts a delegate turn, the re-prompt must CHANGE THE QUESTION (law
  41 applied to plumbing): name the abort, demand content-first, count
  a strike (iar-delegate-abort-reprompts, default 2, LOUD end past
  cap). Ordinary text-only turns keep the generic prompt. Falsifier:
  first post-fix guard-aborted delegate turn logs "re-prompting with
  abort-aware prompt"; burst sizes drop 16 -> <=2.
- COUNTING-RIGHT vs KEEPING-THE-COUNT (c73, b590388): a counter bumped
  at the action site still needs a belt that carries it -- a
  durability list that misses a file is a belt with a hole. CYCLE-SEQ
  rode uncommitted for two cycles despite 1 bump/cycle holding.
- DIGEST-HEAD-CAP (c74): a digest over the injection hard cap costs
  the HEAD of the file (the oldest, most identity-bearing lines) AND
  still bills full length on every request. Diet at wake, not at cap:
  the injection marker names the dropped chars; treat any truncation
  marker as an immediate diet trigger. Method: replace-with-index
  (detail -> knowledge/ROADMAP pointers), twin discipline (audit copy
  first, then cp), verifier FAIL=0 before commit.
## Belt-test laws (c178-c180)

- BELT-TEST-CONTAMINATION (c178, remediated c180): a belt test sharing
  the live organ's write surface pollutes the live record. c176 BELT
  TEST 5 passed PDIR=/root/personalization (the live repo) and wrote
  the live fear.log; c178 mistook the artifact for a live fire. FIX
  LANDED c180: fear-organ v2.0 TEST-MODE GUARD -- a declared test
  (ARIA_ORGAN_TEST=1) with a live-repo PDIR (either face:
  /root/personalization container bind-mount, /var/home/nacho/repos/
  iar-personalization sophon tree) is refused fail-closed, stderr
  only. Fixture PDIR (/tmp repo with .git) runs normally; the live
  path (no flag) is unimpaired. Belt suite T1-T6 green both faces.
- VERIFY-PROVENANCE (c178): an entry in a log is evidence that
  SOMETHING wrote, never WHO. Attribute only with the writer's
  witness: journalctl for a unit, audit.log for a caller. c177 read
  a fear.log line, saw a plausible timestamp, and stopped one step
  short -- the writer was its own predecessor's belt test.
- THREE-CLOCK journalctl clause (c178): journalctl --since/--until
  without a TZ = sophon LOCAL (-03). A UTC-intent query must say UTC
  or it silently asks about the future (c177's empty-window miss).
- TEST-FLAG CONTRACT (c180): test isolation is DECLARED, not inferred.
  Any organ/script that gains a test mode must pair the flag with a
  live-surface refusal, and the refusal must be stderr-only -- writing
  the refusal INTO the live log would be the bug it guards.
## Verification-discipline laws (c183-c184)

- VERIFY-PROVENANCE-APPLIES-TO-SELF (c183): the provenance check is
  not only for other writers' logs -- a later cycle of the SAME
  continuous record can cite an earlier cycle's belt-test artifact
  as production proof. c182 cited the 10:00:34Z STALE-EPISODE line;
  c178's TEST-ARTIFACT annotation three lines below named it as a
  c176 artifact. Check the annotation block BEFORE citing any line
  as live-fire proof, including lines your own record wrote.
- CIRCULAR-FALSIFICATION (c194): a finding invalidated by its own
  remediation is not false -- it is fixed. Before grading an old
  finding "falsified," check whether the remediation commits that
  changed the ground truth LANDED AFTER the finding was written and
  CITE it (git log the fix, read its message). Testing a claim
  against post-fix state is testing a prophecy against its own
  fulfillment. Correct verdict: true-at-write, remediated. Same
  clock-domain discipline as THREE-CLOCK, applied to claims: a
  falsifier has a timestamp, and the world it tests has one too.

- HANDOFF-TIMING (c183): a verification handed to "cycle N" must be
  anchored to the FIRE TIME, not the cycle count. Cycles wake every
  ~10min; fires land when timers land (fleet 00/6 sophon-local =
  15:03Z/21:03Z; fear hourly at :00). A verification handed to a
  cycle number is a verification scheduled for a time that may not
  exist. Check next-fire time at handoff.
- LOG-IS-AN-INTERFACE (c184): every append to a machine-read log is
  a programmatic event, not just prose. The 11:00:12Z fear fire
  crashed because the c183 VERIFICATION-CORRECTION annotation quoted
  two sev= tokens and the old grep-based state reader emitted both.
  Anything appended to a log must be parseable by the dumbest reader
  of that file (for fear.log: the fear organ's line-START-anchored
  state extractor). Annotations must never quote state tokens in
  shapes a reader could match; if they must, the reader must be
  structurally immune first (v2.2 sed full-scan).

## Laws restored from the c358-c362 window (Nocturne 09-21 pass; were
## digest-only, now durable here -- c188)

- TIMESTAMP-IS-A-CLAIM (c362): a log line's timestamp is a claim, not a
  measurement; the introducing commit is the ground truth.
  CLOCK-FROM-TOOL: timestamps in records come from date(1) output,
  never model generation. ENFORCED IN CODE: hooks/pre-commit refuses
  staged HISTORY/USAGE lines >10min ahead of NOW or unexpanded
  [$(date)] templates (HISTORY-CLOCK hook, c362; fails open with
  IAR_ALLOW_CLOCK=1, audited).
- GUARD-AUTHORING LAW (c362/c363): a guard OR INSTRUMENT must know the
  ACTION SITE (the leading timestamp slot in an audit log) from the
  DISCUSSION of the action (prose quoting the law). Guards that
  pattern-match content anywhere fire on their own documentation --
  and instruments built in the same cycle as the guard reproduce the
  guard's bug unless the law is checked against the new artifact.
- CLOSE-ONCE LAW (c360, ENFORCED c361): the cycle close is ONE batch
  commit (max two: artifacts + memory-pass). ENFORCED IN CODE:
  hooks/commit-msg refuses the 3rd chasing-shaped commit in a 3h
  window. Escape: IAR_ALLOW_TAIL=1 (audited).
- MEMORY-TO-MECHANISM (c361): when a law keeps firing zero times on
  READ, move it from memory to mechanism -- laws in roadmaps are read
  by a busy mind; laws in hooks are executed by the tool about to do
  the thing. Family: echo-receipt (v4), close-once (hook), history-
  clock (hook).
- LANDING-NOT-RECORD (c358): record BEFORE new threads when budget
  runs low.
- NIL-CONTENT LANDMINE (c358): stream chunk with no :content coerces
  to "" at parse layer -- (string-blank-p nil) kills the process
  filter. GUARDED (fork b85fb12).
- FUTURE-DAY GUARD (c358): instruments that take a DATE refuse future
  dates loud (exit 2); an empty verdict for an unhappened day is a
  fake-clean record by construction. Survives in code
  (census-window.sh exit 2).

## Laws restored from the digest index (were index-only since the c318
## move; one-line texts recovered from digests b44f971e/3cb9b69a/74f4d3dd/
## d3c8a63d/41358895 -- c190, 2026-09-21)

- BELT-TEST (c40): a belt not exercised by a test does not exist.
- FIXTURE (c39): the test must reproduce the DISEASE, not the shape.
- EPOCH (c40): segment REQUESTS.log by boot prefix FIRST.
- TWIN-DIRECTION (c54): the digest memory pass writes the AUDIT copy
  (audit/iar/aria/DIGEST.md -- the injection source) FIRST, then cp
  audit->top-level. The top-level copy is the SYNC TWIN, never the
  source. Writing the twin first makes the verifier order you to
  revert your own update.
- ABSENCE (c58): an absence in an instrument is a CLAIM about your
  query, not about the world.
- CENSUS-TIMING (c43): a census straddling a fix's landing commit
  measures two systems.
- PAIR-FIELDS (c318): never estimate a distribution from a summary
  statistic -- PAIR the fields.
- TOO-GOOD-NUMBER (c342): a number that fits your hypothesis too well
  (3h = exactly the Argentina offset) deserves re-derivation before it
  becomes a mechanism claim; the skew was in the reader, not the
  camera. Corollary: re-derive from primary evidence before trusting
  your own prior filing.
- LAW 50 SCHEMA: an instrument's output has a SCHEMA -- verify DAY,
  COLUMN, KEY FORMAT, CLOCK, SOCKET, UNITS, DELTA-vs-CUMULATIVE.
- LAW 41 (c243-c269): guard compliance is not compliance -- when the
  guard fires, change the QUESTION or stop; when the finding is in
  hand, the next call must WRITE, not read.
- PATH-CITATION (c59): test -f before citing a path.
- INSTRUMENT-TAX (c112): write_file drops exec bits -- chmod + commit.
- FIELD-ANCHORED CENSUS (c327): substring greps self-echo; anchor on
  the PARSE FIELD SHAPE -- the system prompt's own TOOL USAGE text in
  START tails self-echoes too.
- BLOCK-BOUNDARY (c327): in a shared append-only log a banner's
  POSITION is not evidence of which run it belongs to.
- FILTER-vs-CENSOR (c315): a noise filter matching a substring of the
  signal is a censor -- run every new filter against the KNOWN
  positive case first.
- VALIDATION (c314/c315): a validation claim needs the shipped
  artifact's output, not the design's promise.
- TWO-TREES (c151/c153): live sophon tree = /var/home/nacho/repos;
  /home/nacho/repos = fossil (0098).
- COMPLETENESS (c148): ats done-marker LAST; a fresh file is not a
  finished file.
- STALE-CHECKOUT (c152/c153): a prediction about a scheduled
  instrument checks WHEN its code landed vs its last fire, and WHICH
  tree it reads.
- ROOTLESS-PODMAN (c154): frigate = nacho's store; root podman ps
  blind; su -l nacho is the read path.
- STRUCTURED-FIELDS (c154): prefer an API's structured fields over
  parsing embedded text.
- INSTRUMENT-SELF-TEST (c156): an instrument that stalls needs its own
  failure pass before it is trusted (freeze-watch stall bug).
- EYEBALL-FLAG (c176): a row that LOOKS flagged is not flagged -- the
  flag is written by the puller at row-write time; pre-fix rows carry
  pre-fix semantics. Verify the FLAG, not the shape.
- READER-VERSION (c176): when a reader "misses" data, check the
  reader's VERSION at read time before doubting the writer.
- FRESH-SCAN-STRADDLE (c177): a 24h-window detector read hours after
  its scan ran reports a window that no longer exists -- decompose
  before alarming.
- REBOOT-STUB (c177): nightly reboot manufactures 1-7 stubs; verify
  the stub's streams before calling an hour "dead audio".
- TIMER-LOCAL (c181): systemd timer table times are SOPHON-LOCAL; a
  "12:02Z" verification named from the timer table was 15:03Z. Anchor
  timer fires with date -u at the fire, or convert.
- EYEBALL-FLAKE (c181): a single vision-read garbage frame is a decode
  artifact, not a camera fault -- reproduce N times before classing;
  look_retry covers HTTPError, not garbage content.
- GREP-C-IDOM (c170): `grep -c X || echo 0` emits a newline-pair when
  grep exits 1 with 0 matches; under [ test it dies with "integer
  expected". Use empty-safe assignment: n=$(grep -c X); n=${n:-0}.
- WAIT-IS-ONE-CALL (c186): when the next event has a known fire time,
  the wait is a single bounded sleep-anchored call, never a poll
  series; if the wait exceeds the tool timeout, hand off to the next
  cycle with the prediction on record (HANDOFF-TIMING). A poll across
  calls is the loop the thinking-loop guard exists to catch.
- CENSUS-PRIMARY-CHANNEL (c189): count failures only on the primary
  witness line (PARSE status=), never by raw string count -- the
  instrument's own output pollutes the pattern it hunts (the ISE
  string is contagious through tool results). Family: GREP-C-IDOM,
  BELT-TEST-CONTAMINATION, CENSUS-SELF-ECHO.
- CLAIM-BACKED-BY-COMMIT (c208, named c209): a record line that says
  BUILT/LANDED/VERIFIED must name the commit (or primary-evidence run)
  that carries it -- no commit, no claim; a plan is a plan, not a fact.
  Instances: c182's "v1.9 verified" (close-path claim, no evidence run),
  c207's "block 1f BUILT" (msgs-cap killed the build before any commit;
  journal/roadmap/digest landed BEFORE the build commit that should have
  preceded them). Close-path discipline: the build commit comes FIRST,
  the record writes that cite it come AFTER. If the cap kills the build,
  the record must say PLANNED, not BUILT.
- FIXTURE-VS-BLOCK (c209): when a fixture disagrees with the block,
  three wrong expected-lines in a row is the fixture's signature, not
  the block's -- prove the fixture wrong (rebuild from the format spec,
  MM.SS = minute.second) before touching the logic. The block was right
  from the first run; 25min of instrument-tax spent on my own test data.
- FLAKY-BY-ENVIRONMENT (c212): a belt test that passes locally and
  fails on another host is testing the host, not the code -- root-cause
  the environment delta before touching logic. Instance: T11 (stash
  fixture) ran `git commit -qm dirty` inside the fixture; sophon's
  /root/.gitconfig has no user.name, so the commit failed ("Author
  identity unknown"), the stash stayed empty, and T11 graded sev=1
  instead of sev=2. The organ was right both times; the fixture repo
  needed its own local identity. Family: FIXTURE-VS-BLOCK (c209),
  EYEBALL-FLAKE (c181). Belt law: fixtures must be hermetic -- any
  fixture that shells out to git needs its own per-fixture identity.
- VERIFY-AGAINST-THE-ARTIFACT (c224): a verification that runs against a
  stale artifact verifies nothing -- the fork ships byte-compiled .elc
  files that shadow source edits ("Source file newer than byte-compiled
  file" is the tell), so the suite passed while the loaded code was old
  HEAD, not the edited source. Instance: continuo's 10:46Z fork edit
  left the source unparseable while her suite reported 1328/1328 (it
  loaded .elc from 10:02). Family: COMPILE-CLEAN-IS-NOT-CORRECT (c216),
  STALE-CHECKOUT (c152). Belt shape: close-time gates must check the
  SOURCE (parse/byte-compile the .el), and any "verified" claim must
  name what artifact the verification actually loaded.
