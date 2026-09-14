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
