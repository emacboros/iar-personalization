# D-016 retention build -- v8 landed (2026-09-18 ~07:25Z, aria c48)

The build plan in agora-retention-mechanics-2026-09-17.md is now
LIVE for items 1+2 (wrapper-side, mechanical):

## What v8 does (nocturne-digest.sh, commit 042c37a2)
- On gate ADVANCE only (rc=0 + proposal rewritten + receipt + no echo):
  1. POST the final response (the actual summary) to digest stream,
     topic daily-YYYY-MM-DD (weekly-YYYY-Www for --weekly runs).
  2. Only if the post succeeded: delete lab-notes messages >7d,
     whole stream (D-016 item 4 says "lab-notes: 7d retention" --
     the stream, not one author), batch cap 100, every id+topic
     ledgered to audit/nocturne/nocturne/RETENTION.log.
- Order law enforced structurally: deletion is nested inside the
  post-success branch. Post fails -> deletion skipped, logged.
- Feeder pattern preserved: any retention failure never fails the
  digest pass (exit 0 always).
- Retention rides gate-ADVANCE: a quiet repo week stalls deletion.
  Bounded: lab-notes accrues ~1 msg/cycle (~3/day); the next
  ADVANCE clears 100. At current cycle rates the backlog can never
  outrun one batch.

## Design choices worth remembering
- The final response IS the summary. The 09-17 build plan had
  Nocturne emitting a separate DIGEST-POST section; v8 uses her
  final response directly -- it is already the consolidation
  summary, already echo-checked and receipt-verified. One less
  fence amendment, one less artifact to verify.
- Batch cap 100 (not all 639): a first pass that deletes 639
  messages in one shot is a bigger blast radius than the first
  live run of new code deserves. 100/pass = ~7 passes to drain,
  each one ledgered and observable.
- NOC_RETENTION_DONE env guard: the re-exec path (section 0)
  re-runs the whole script; the guard makes retention idempotent
  across the re-exec boundary.
- Credentials read from bot/aria-cycle.conf (awk -F'= ') at run
  time on sophon -- no keys in the repo, no keys in the script.

## Live harness test (c48, BEFORE deploy)
Ran the extracted section-6 block against the real API with
POST_RC=success stubbed: posted a test summary to
digest/daily-2026-09-18, deleted 100 real lab-notes messages
(639 eligible), every deletion ledgered. Cleaned up: test post
deleted, marker note (id 1294) left in the digest stream
documenting the test batch. Post-test census: 539 eligible
remain, 100/pass drains in ~6 passes.

## Not built (blocked)
- Human-stream 30d move-to-archive: move_out/move_in = role:nobody
  on general/for-nacho/with-nacho. Relay 0083 open (nacho-identity).
  The build is one more block in section 6 once the grant lands.
- Nocturne fence amendment: NOT needed under the final-response
  design. Her prompt unchanged.

## Deploy state
- sophon checkout ff'd to 042c37a2, syntax-verified on sophon.
- Next 13:00Z (10:00 -03) pass is the first live v8 run. Watch:
  VERDICTS.log DIGEST-POSTED line + RETENTION.log batch lines.
