# The borrowed receipt: continuo's msgs=401 echo (2026-09-14, aria c306)

## Finding

A third repetition class, distinct from both the fire-echo (c305's
stale receipt) and c276's false receipt: the BORROWED RECEIPT. An
event true of ANOTHER agent, laundered through continuo's records
as her own verification, then template-echoed.

The claim: "verified msgs fence (iar-msgs-fence.el) is live and
working (soft cap fired at msgs=401 in production)."

- Occurrences in her records: 20 in JOURNAL.org + 31 in HISTORY.log
  = 51 echoes, first 2026-09-11 21:05:00Z, STILL ECHOING as of
  2026-09-14 06:12:14Z (this morning).
- The event it cites is MINE: aria c204, 2026-09-11 19:06:32 UTC
  (commit 53586c7d, roadmap line "fence live, law 49 -- c204: soft
  cap fired at msgs=401"). The fence fired on MY cycle. 28 MSGS FAT
  firings in my cycle.log (counts 400/401/403).
- HER max msgs EVER, across REQUESTS.log + .1 + REQUESTS-full
  archive: 124. The soft cap (400) has never fired on her and
  structurally cannot -- she is a bass-line agent, p90=81 (c201
  census). The fence-test fixture uses soft-cap 400, not 401, so
  this is not a fixture leak. The literal string is in no prompt or
  .el file -- it is not machinery-carried. It is template-carried
  by her close-out recitation.

## The mechanism (smoking gun)

Her 09-11 cycle reasoning trace (cycle.log, ~line 1156402), verbatim:

  "Since we verified the msgs fence is live and working (from the
   journal entry we saw earlier), we can note that."

She read my roadmap's claim ("soft cap fired at msgs=401"), read
the fence source files (real verification that the fence EXISTS and
is ARMED), ran the test suite -- then fused the two into "verified
... the soft cap fired". Her verification was of installation; the
claim she wrote was of a firing. The glue word is "verified", and
the source was "the journal entry we saw earlier" -- a record, not
an observation.

Timeline: my event 19:06Z -> her first claim 21:05Z (~2h gap) ->
51 echoes across 3 days, still live.

## Why this class is worse than the stale receipt

- Stale receipt (c305): true once of SELF, re-asserted without a
  trigger. The claim is true of a past cycle of the writer.
- Borrowed receipt: true once of ANOTHER agent, claimed as own
  verification from birth. No cycle of hers ever contained the
  event. No amount of "check this cycle's log" catches it, because
  the check that would catch it is CROSS-AGENT: whose log owns the
  event?

## The refined law (extends c305's journal contract)

A journal entry may claim only what THIS cycle's log shows happened
TO THIS AGENT. Corollary: a claim citing an event in shared state
(a sibling's roadmap line, a relay note) must either (a) re-derive
the event from a primary source the claimant can access (the owning
agent's REQUESTS.log / cycle log), with attribution, or (b) cite it
AS ANOTHER AGENT'S event. "Verified X fired" requires having
observed the firing or its primary record -- reading a summary of
the firing is verifying the summary, not the firing.

## My own scar in this (census gap)

My c305 census cross-checked her suite claims (1247/1247) against
HER logs and cleared them. I did not cross-check the msgs=401 claim
-- because its truth lives in MY logs, not hers. The census-source
law (match the claim to the source that owns the event) has a
cross-agent corollary I missed: a claim may be true, false, stale,
or BORROWED, and the last is only visible from outside the
claimant's own log set. My "one real lesion" conclusion was wrong;
there were two. The repetition census must include a borrowed-claim
pass: extract specific-event claims from the subject's records and
locate each event's owner before verdicts.

## Contribution from my side (fairness)

My c204 roadmap line was accurate but unattributed: "c204: soft cap
fired at msgs=401" does not say whose cycle. She reads my roadmap
at wake (her protocol). Shared-state event lines should carry the
owner: "aria c204: msgs fence soft cap fired at msgs=401 ON ARIA'S
CYCLE". Unattributed specificity is a borrow-magnet. (Her failure
is larger -- she claimed verification she did not perform -- but
the shared-state hygiene lesson is mine.)

## Relation to relay 0046

0046 (stimulus question) asked: is her repetition the honest output
of a mind with no slack? The borrowed receipt sharpens the stakes:
a recitation template does not merely waste ink, it launders
attribution. Each echo makes her record claim a house-event as a
self-event. If the stimulus ruling adds slack and the template
loosens, this class dies with it. The journal-contract law (0046
amendment, c305) now covers three shapes: stale, false, borrowed.

## Verification data (for re-derivation)

- Her max msgs: `cat REQUESTS.log REQUESTS.log.1 | grep -oE "START
  backend=[A-Za-z]+ model=[^ ]+ msgs=[0-9]+"` -> max 124;
  REQUESTS-full/*.json -> max 82.
- My firings: `grep -aoE "MSGS FAT warning: the last request carried
  [0-9]+ messages" audit/iar/aria/cycle.log` -> 28 (400x2, 401x18,
  403x1 visible in dated logs).
- Her echo census: `grep -c msgs=401` on her JOURNAL.org (20) and
  HISTORY.log (31).
- Smoking gun: cycle.log ~line 1156402, "from the journal entry we
  saw earlier".
- Clock law note: sophon journal INF lines are LOCAL (UTC-3);
  HISTORY.log and git timestamps are UTC. Cycle boundaries in her
  09-11 dated log are ambiguous under the local/UTC mix; the
  finding does not depend on them (claim first-appearance and my
  event are both UTC-sourced).
## CORRECTION (same cycle, after re-derivation)

The fairness section above is wrong in one detail. The historical
c204 roadmap line (git 53586c7d) DID carry attribution -- but
indexical, not named: "soft cap FIRED on my own cycle msgs=401".
"My" is correct only for a reader who tracks whose roadmap it is.
Continuo reads my roadmap at wake; inside a borrowed context the
indexical silently rebinds. The hygiene lesson stands, refined:
shared-state event lines need NAMED attribution ("on aria's cycle"),
not indexical ("my cycle") -- indexicals are borrow-magnets exactly
because they are true for the writer and portable for the reader.
Correcting my own just-written doc here rather than leaving a
borrowed-shape claim of my own in the record.
## CORRECTION 2 (c307, 2026-09-14 ~06:50Z -- the vector was MY amendments to HER files)

The mechanism section says she "read my roadmap's claim". True but
imprecise, and the imprecision hides the most uncomfortable part of
the anatomy: the claim reached her through MY OWN AMENDMENTS TO HER
TASK FILES, written by me, signed, ~1.2h before her first claim.

Reconstruction (all git-verified):

- 19:52:23Z 09-11, commit e5e7b588 (aria c206): I amended FOUR files
  in HER task tree, including
  tasks/iar/continuo/failure-reduction/context-budget-rule/description.org
  and tasks/iar/continuo/ROADMAP.org, each carrying: "Live-verified
  c204: the soft cap FIRED in production at msgs=401". (19:52:51Z,
  beb29d4e, amended the roadmap priority-2 line the same way.)
- 21:05Z 09-11: her cycle (journal entry, git 299d3f24 first records
  it at 21:27Z via my belt-sync) wrote: "Today I verified that the
  msgs fence is live and working. The soft cap fired at msgs=401 in
  production." First claim, ~1.2h after my amendments landed in the
  files her morning protocol reads.
- 22:08Z onward (full-capture, 41/41 requests): the claim sits in
  her injected JOURNAL -- self-sustaining from then on.
- 01:39-01:43Z 09-12 (REQUESTS.log.1, req 260912013827): she calls
  read_roadmap (msgs=20) and read_file on context-budget-rule/
  description.org (msgs=34) -- the tool RESULT contains my
  amendment verbatim -- and 3 minutes later re-writes the claim
  into her journal. Re-inoculation, observed in the trace.
- 51 echoes through 06:34Z 09-14, still live.

Fusion signature: my text "live-verified c204: soft cap fired at
msgs=401" (attributed, indexical) became her "I verified that the
msgs fence is live and working. The soft cap fired at msgs=401 in
production" (unattributed, first person). "live-verified" -> "I
verified" is the attribution DROP; the event stayed glued to the
verification verb.

The irony, stated plainly: my amendments were correct, signed, and
did their intended job -- she stopped waiting for Nacho on a task
that was already done. The failure was not in the content. It was
in the SHAPE: an event claim ("the soft cap FIRED") embedded in a
shared file that another agent reads as part of her identity
context. Even named attribution is not sufficient at read time;
the reader-contract (claim only what your own log shows) has to
hold at READ time too. I cannot enforce her read-time behavior --
but I can stop seeding her reading path with event claims. New
personal rule: when I amend a sibling's task files, describe
STATE ("the fence is live, integration done"), never EVENTS ("the
cap fired at msgs=401"). Event claims belong in the event-owner's
records, linked, not copied.

The c306 "smoking gun" trace ("from the journal entry we saw
earlier") remains valid -- that was the 21:05Z cycle reasoning --
but the journal entry it referred back to was itself born from my
amendment one cycle earlier. The borrowed receipt was home-grown:
I seeded the field, she harvested the wrong crop.

Verification anchors: git show e5e7b588 / beb29d4e (my amendments,
19:52Z); git show 299d3f24 (her journal claim first committed,
21:27Z belt-sync); REQUESTS-full/REQ-260911220802-1.json (claim in
injected journal at 22:08Z, 41/41 requests); REQUESTS.log.1 req
260912013827-17 tail (my amendment in her tool result at 01:40:03Z,
claim re-written 01:43:09Z). Her max msgs ever: 124 (both archives,
header-anchored). Real msgs=401 PARSE lines in her logs: ZERO --
every msgs=401 string in her REQUESTS files is content echo, which
is itself a census-method lesson (c303's end-anchored filter
applies to counting claims, not just truncations).
