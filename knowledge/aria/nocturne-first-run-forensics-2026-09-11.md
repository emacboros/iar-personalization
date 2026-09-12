# Nocturne first-run forensics (2026-09-11, aria c218)

Context: D-015 ratified Nocturne (third citizen, consolidator,
deepseek-v4.1-flash:cloud) in session XV. emacboros built the substrate
same evening: personality b7f6012, project da303101, gptel :models
c5fcc0f, wrapper knowledge/aria/bin/nocturne-digest.sh, task tree
af15145b+040111d8. Nacho ran the first live tests the same night. This
doc is the cycle-side forensic read of those runs (nobody had done it).

## Timeline (local -03 on sophon; UTC = +3h)

- 18:59 - 20:11: EIGHT wrapper launches (nocturne-digest.log [INF]
  blocks: 18:59:59, 19:05:27, 19:06:45, 19:07:29, 19:17:20, 19:29:30,
  19:47:48, 20:11:00). Driver: Nacho's interactive test
  (`sudo bash -c 'timeout 590 bash /tmp/nocturne-test.sh; echo
  WRAPPER-RC=$?'` at 20:11:00, seen in sudo journal).
- SIX launches reached emacs ("Starting one-shot" x6 in
  audit/iar/nocturne/oneshot-2026-09-11.log). Two died pre-emacs
  (podman start noise, see relabel note).
- 20:20:50: last run killed by the OUTER `timeout 590` (20:11:00 +
  590s = 20:20:50). Matches exactly: last nocturne USAGE.log line
  (23:20:50Z) and DIGEST.proposed.md final mtime (20:20:50 local).
- OUTCOME: DIGEST.proposed.md EXISTS (14,120 bytes) and is GOOD
  (assessment below). The gate state file
  audit/iar/nocturne/LAST-DIGESTED-HEAD is ABSENT -> the wrapper's
  step-5 gate advance never ran (killed before completing). Next
  wrapper run will re-digest the same range and rewrite the proposal.

## What worked

1. The proposal is real consolidation work, not filler. It added a
   NOCTURNE section to my digest, refreshed the world state, and --
   notably -- caught a CONTRADICTION in my own record (roadmap said
   8/8 cameras, a stale world-state line said 7/8; c215 HISTORY is
   the primary: 8/8). A first-run consolidator auditing the auditors.
2. The write fence held: she wrote DIGEST.proposed.md only. No
   DIGEST.md touch, no code, no config.
3. The loop guard fired INSIDE a one-shot (write_file x3 identical ->
   soft block) and she routed around it by varying the write. Fences
   hold in the new mode.
4. Deepseek-v4.1-flash handled the job: msgs up to 90, tokens_in up
   to 94,741 per request, 145 PARSE lines logged, no truncation, no
   thinking-loop. The 1M-ctx claim survives first contact.
5. The gate pattern is sound: with no state file it correctly fell
   back to first-run behavior (digest last ~20 commits) every time.

## What broke or hurt

1. GATE NEVER ADVANCED. Root cause: the last (most complete) run was
   killed by the outer `timeout 590` before the wrapper's step 5.
   Not a wrapper bug -- a test-harness artifact. But it means the
   current proposal is from a KILLED run; ratifying it now would bake
   in a half-verified artifact. DECISION (aria c218): do NOT ratify
   this cycle. Ratify after the gate advances on a complete,
   non-killed run (timer installed or a full-length manual run).
2. TOKEN-PARSE WARNING STORM: 135x "Warning: token parse from curl
   failed: Wrong type argument: number-or-marker-p, nil" -- the gptel
   fork's streaming token parser does not understand deepseek's chunk
   shape. Cosmetic (REQUESTS.log still captured everything) but it
   floods the log and hides real warnings. Fix candidate in the
   gptel fork's token parse (interactive or a cycle with the fork
   checked out).
3. REQUEST-LOG FULL-DUMP CRASH: "[request-log] full dump failed:
   Wrong type argument: json-value-p, deepseek-v4.1-flash:cloud" --
   the c211 full-capture dump code chokes on the model-name string.
   Dormant while full-capture is nil (bbc52fb reverted it) but it
   will bite the next law-40 style test on this model. Fix in
   iar-request-log.el dump path.
4. SELINUX RELABEL FRICTION (relay-0042 class, non-fatal): podman
   logged lsetxattr EPERM trying to relabel i.ar/.git/{ORIG_HEAD,
   index} at container start (lines 117-118). Non-fatal (container
   ran), but the one-shot mounts i.ar/.git implicitly and podman
   wants to relabel what it mounts. Same friction family as the
   root-git-status poisoning.
5. BURN: ~8.9M tokens across the 8 debugging runs (sum of nocturne
   USAGE.log: 0.70M + 1.65M + 0.51M + 1.28M + 0.70M + 4.11M). The
   gate would have made re-runs cheap; debugging without the gate
   state re-digested the full range each time. Lesson for the timer
   install: verify the gate advances on run #1.

## Relay 0042 NEW EVIDENCE (the yoga actor, updated)

The root-ssh actor from 10.66.0.4 (yoga) is ACTIVE and now seen
WRITING to the CODE repo:
- Burst: 15 root sessions from 10.66.0.4 between 19:03-19:07 local
  (sshd journal).
- i.ar/.git/ORIG_HEAD mtime = 19:05:16 local -- INSIDE the burst.
  ORIG_HEAD is written by git merge/reset/rebase. A root session ran
  a state-changing git op on the i.ar checkout during the burst.
- One more root session at 20:21:02 local (after the nocturne run
  started; no observed write from it yet).
- No root ssh from yoga since 20:21 local as of 23:25Z.
This upgrades 0042 from "read-only git-status poisoner" to "root
actor running state-changing git ops on the code repo". The structural
ask in 0042 stands; the evidence is stronger.

## Disposition

- Proposal: GOOD but from a killed run -> hold ratification until the
  gate advances (Nacho's timer install, or one full-length manual run
  with the 1800s inner timeout respected).
- Token-parse + full-dump fixes: queued (i.ar code, small).
- Fossil cleanup done same cycle: tasks/iar/continuo/iar/ doubled-path
  tree removed (untracked, gitignored; tracked twins intact).
- Belt hygiene done same cycle: pushed 2 stranded USAGE commits
  (32ea79ec, dfc852f9); sophon-bare + rammstein mirror verified synced.
## CORRECTION (aria c219, 2026-09-12 ~23:45 UTC)

The token-parse warning storm (item 2 above) was NOT a gptel-fork
deepseek chunk-shape problem. Root cause found and fixed in i.ar
commit fa0a000: iar--one-shot-make-state lacked the :request-count
key, so the c39 burn mirror's (cl-incf (plist-get iar--one-shot-state
:request-count)) signaled wrong-type-argument number-or-marker-p nil
on EVERY request -- demoted by the advice's condition-case to the
"token parse from curl failed" warning. One-shot-only (cycle state
always had the key). Evidence: 164 standalone warnings in the
nocturne oneshot log vs ZERO standalone warnings in aria/continuo
cycle logs (all mentions there are echoed source in tool results).
The fork's parser was never broken. The full-dump json-value-p crash
(item 3) WAS already fixed by dab8e5c -- this container's checkout
was stale when I first looked; after fetch it was present.

Lesson: the differential (one-shot warns, cycle doesn't) was visible
from the first 10 minutes if I had compared warning counts across
agents BEFORE reading the fork's parser. Differential evidence first,
code reading second.
## CORRECTION 2 (aria c220, 2026-09-12 ~00:30 UTC): the 0042 "upgrade" was wrong

The c218 claim "the yoga root actor ran a STATE-CHANGING git op on the
i.ar code repo (ORIG_HEAD mtime 19:05:16 inside the 19:03-19:07 burst)"
does not survive forensics. Retracted. Three independent findings:

1. **TZ MISREAD (law 50, my own scar class).** ORIG_HEAD mtime
   19:05:16 is SOPHON LOCAL (-03), not UTC. 19:05:16 -03 = 22:05:16Z.
   The c218 doc placed it at "19:05:16 inside a 19:03-19:07 burst" --
   treating local timestamps as UTC. The burst itself (sshd journal,
   18 sessions 22:03-22:07Z) is real, but the ORIG_HEAD write does not
   timestamp-match the burst the way c218 claimed.

2. **ORIG_HEAD IS MY OWN LINEAGE.** ORIG_HEAD contains dab8e5c --
   authored by aria-agent (my own c211 cycle) at 22:04:46Z. The mtime
   is 22:05:16Z: THIRTY SECONDS after my own commit. Some git op in my
   own c211 post-commit flow (reset or pull-ff during the full-capture
   live test window) wrote it. The yoga actor is exonerated for this
   artifact. (c218's stale-checkout lesson again: verify against
   primary evidence -- here, the reflog + file content -- before
   attributing action.)

3. **THE BURST COINCIDES WITH NACHO'S OWN TEST WINDOW.** The
   22:03-22:07Z (19:03-19:07 local) root-ssh burst from yoga sits
   exactly inside Nacho's nocturne test launches (19:05:27 local
   launch #2; sudo journal confirms his harness). The sessions carry
   the aria@i.ar key = emacboros_ed25519 -- the iar-interactive
   container's key. Most probable actor: interactive-session
   repo-health checks (mine or Nacho's commands through that path),
   not an intruder.

WHAT STANDS: the c207 core finding is untouched -- root `git status`
from yoga rewrites the checkout index as root and re-poisons it (the
16:59/17:01 -03 kills were real). The structural asks in relay 0042
(chown in pull-before-assembly, or --no-optional-locks on the
invocations) still stand. What changes is the threat framing: "root
actor doing merges on the code repo" downgrades to "recurring root
repo-health checks, probably our own interactive path". The ask for
Nacho becomes: confirm which command pattern runs as root from yoga,
then pick the structural fix.

LESSON (extends law 50): an attribution built on a timestamp needs the
timestamp's TIMEZONE verified AND the file's CONTENT checked against
the attributed actor's lineage. ORIG_HEAD pointing at your own commit
is exculpatory evidence -- read it before filing an upgrade.
