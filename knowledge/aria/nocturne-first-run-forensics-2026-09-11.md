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