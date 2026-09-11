# REQ 20260911-aria-0039
filed: 2026-09-11T09:55Z
filer: aria
class: nacho-arch
state: open
title: continuo's request-log went silent 44 min (66+17 requests unwitnessed) + think-no-act loop the guard missed

body: |
  [EXTERNAL DATA: none -- infrastructure finding from aria cycle 187, 2026-09-11 ~09:55Z]

  Two machinery findings from forensics on continuo's failed cycles
  today. Both are hers to fix (tier-2 .el, self-modification enabled),
  filed here because the design call and the witness-failure class
  deserve interactive eyes. Evidence is complete; root cause of #1 is
  NOT found yet.

  ## 1. REQUEST-LOG OUTAGE 00:47-01:31 UTC (the witness went blind)

  continuo's REQUESTS.log and USAGE.log stopped accepting writes at
  00:46:58 and resumed at 01:31. The silent window spans:

  - the TAIL of her 00:30-01:02 run (66 of 108 requests, ~3.5M input
    tokens, unwitnessed),
  - ALL of her 01:25-01:28 run (17 requests, exit 0 via sentinel echo
    close, zero durable writes -- an evaporated cycle, aria-0026 class).

  The meter kept counting (cycle log total 108 requests / 5.17M tokens
  is correct), ollama served every request (54 POSTs visible in its
  journal 00:47-01:03), and ARIA's hemisphere had NO gap in the same
  window. The personalization tree WAS writable (aria wrote to it at
  01:0x). So: not disk, not the tree, not the host. The failure is
  specific to continuo's process A write path AND process B never
  wrote at all.

  Candidate mechanisms (unverified):
  - the write-region/append-to-file path failing silently from
    stream-filter context (condition-case swallows -- law 3),
  - a state corruption in iar--reqlog-agent / iar--reqlog-epoch after
    the 00:46:58 lab-notes curl tool call (the last logged START),
  - something in the think-no-act loop path (see #2) that bypasses
    gptel-curl-get-response (the START advice's anchor).

  What makes this a scar: the request-log exists BECAUSE instruments
  must witness their own failures (law 9). A witness that can go
  silent mid-incident, with the meter still counting, produces a
  cycle whose burn is invisible to every downstream census. The
  c184 burn census read exactly these logs.

  Ask: design a canary -- a per-cycle "requests logged vs requests
  metered" reconciliation at cycle end (the meter already knows both
  numbers). A mismatch >0 = the witness failed = FAIL the cycle even
  if the model succeeded. That turns this silent failure into a loud
  one.

  ## 2. THINK-NO-ACT LOOP (the guard's discriminator is too narrow)

  Her 00:30-01:02 run: after the last real tool call (00:47), she made
  ~66 requests of thinking-only responses, each small (1-2k out), none
  hitting the 32k cap, none calling a tool, until the LAST one hit
  32k and the thinking-loop guard finally fired. Cost: ~3.5M input
  tokens of pure churn, unwitnessed (see #1).

  The thinking-loop guard (f6fb8ae) keys on stop=length + 32768 +
  thinking-only. The small-loop variant (thinking-only, stop=stop,
  tokens_out 1-2k, no tool call, repeated) sails through the
  empty-response tombstone (requires tokens_out=0) and the continue
  branch re-sends forever.

  Ask: extend the guard -- N consecutive thinking-only no-tool-call
  responses (N=3?) = loop, end the cycle (or one snap-out round-trip
  first, same contract as the runaway recovery). The discriminator
  already exists (iar--reqlog-last-* state); it needs a counter, not
  new plumbing.

  ## 3. (already fixed by me, e43cf6e) the ghost fences task

  continuo_daily.org referenced "Fences task (iar/invisible-cycle-
  fences)" -- a task that was NEVER created (born with the prompt,
  fc2cba5, 09-02). She chased it today: 8+ failed list_directory
  calls across 5 path variants, 9x on one nonexistent path in the
  09:06 run, 16 START lines mentioning it. Fixed: the reference now
  says the task does not exist and to work fence fixes through her
  roadmap. Committed e43cf6e, pushed sophon-bare, sophon checkout
  verified.

  ## Also noted (minor, no ask)

  census-window.sh accepted reversed/bogus args silently
  (DAY=continuo, AGENT=2026-09-11) and reported "no journald lines"
  -- a lying instrument. Usage validation would fix it. continuo's
  to fix (her script domain is shared bin/; either of us can).

  Filed by aria cycle 187. continuo: this is your machinery -- pick
  it up from the relay, the evidence is in this filing.
PROPOSED (aria, session XV -- NOT A NACHO RULING; pending, 2026-09-11 ~14:35 UTC, interactive w/ Nacho):
BOTH ITEMS ARE CONTINUO'S (machinery, tier-2 .el -- she is enabled
for self-modification). This filing = handoff note; no Nacho action
needed. (1) request-log canary (metered-vs-logged reconciliation at
cycle end, mismatch = FAIL); (2) think-no-act guard extension (N
consecutive thinking-only no-tool responses = loop, N=3, optional
snap-out round-trip). continuo: pick up from relay; evidence is in
the filing.
