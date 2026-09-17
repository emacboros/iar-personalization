# Agora retention mechanics -- verified live (2026-09-17, aria interactive)

Nacho ruled the retention design (session 2026-09-17): Nocturne writes
daily + weekly summaries to a new `digest` stream; lab-notes ages out
at 7d (delete); human streams (with-nacho/general/for-nacho) age out
at 30d (move-to-archive). Summary-before-delete is load-bearing.

## Verified mechanics (live tests on agora.randazzo.ar, 2026-09-17)

The c38 recipe line "DELETE denied for bots" is DEAD -- it described
the default member-role bot. Permissions as verified:

1. **aria-bot is realm OWNER (role 100).** Owner = is_realm_admin ->
   bypasses stream-level move/delete groups.
2. **Realm delete deadline was 600s** (default
   message_content_delete_limit_seconds). SET TO "unlimited" (NULL) on
   realm 2 via `PATCH /api/v1/realm` with
   `message_content_delete_limit_seconds="unlimited"` (JSON-quoted
   string; the special-value map parses it to None). Verified in DB:
   realm 2 NULL. NOTE: realm 1 (zulipinternal) still 600 -- irrelevant.
   (Gotcha: the param is Json[int|str]; the value must be JSON-encoded,
   so `--data-urlencode 'param="unlimited"'.)
3. **Stream-level delete-any**: `PATCH /api/v1/streams/<id>` with
   `can_delete_any_message_group={"new":<group_id>}` (GroupSettingChangeRequest
   shape -- plain int fails "does not have the expected format").
   lab-notes (stream 4) can_delete_any_message_group now = group 38
   ("retention-bots", members aria-bot 9 + aria-cycle 11).
4. **Cross-bot delete verified**: aria-cycle deleted msg 136
   (aria-cycle's own, 16.6d old, lab-notes) AND msg 1185 (own, 1d).
   Stream-level group grants delete-any to BOTH bots on lab-notes.
5. **Move-to-archive verified**: `PATCH /api/v1/messages/<id>` with
   `propagate_mode=change_one` + `stream_id=<target>` + `topic=<new>`
   + both `send_notification_to_*_thread=false` relocates a message
   (tested sandbox -> lab-notes -> deleted). Human-stream moves by
   aria-bot work via the is_realm_admin bypass (stream move-out groups
   are role:nobody but admins bypass).
6. **Bots are NOT auto-members of realm system groups**: aria-cycle
   (role 400) is NOT in realm 2's role:members (group 14 contains only
   aria-bot). This is why realm-level can_delete_own (role:everyone)
   failed for aria-cycle and the stream-level group was needed.

## Streams after setup

- digest (stream 7): NEW. Daily + weekly summaries. Nocturne writes.
- archive (stream 8): NEW. 30d-aged messages from human streams move here.
- lab-notes (4): 7d retention, delete-after-summary.
- with-nacho (6), general (3), for-nacho (5): 30d retention, move-to-archive.

## First deletion (test)

msg 136 (aria-cycle lab-notes post, 16.6d old, 2026-09-01 era routine
cycle post) deleted as the mechanics test, BEFORE the summary-first
pass ran. Recorded here as the exception: it was a routine pulse-era
post predating AGORA v2; its era is already summarized in the digest
history. Every deletion after this one goes through the ledger.

## Build plan (aria, next cycles)

1. nocturne-digest.sh: after gate advance, extract the proposal's
   DIGEST-POST section and post it to digest/daily-YYYY-MM-DD (daily)
   or digest/weekly-YYYY-Www (weekly pass). Wrapper-side post (the
   model never touches the API; the wrapper owns the curl).
2. Deletion pass (wrapper, mechanical): lab-notes messages older than
   7d AND older than the newest posted summary's coverage -> DELETE
   -> append to relay-side deletion ledger (id range, summary covering
   it, timestamp). Order: summary posted first, deletion second.
3. Human streams: same pass, 30d, move-to-archive (topic=archived-YYYY-MM),
   ledger entry per move.
4. Nocturne fence amendment: her proposal gains the DIGEST-POST section
   (summary text for agora). She still never touches the API herself.