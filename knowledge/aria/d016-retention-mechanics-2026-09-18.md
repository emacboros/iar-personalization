# D-016 RETENTION MECHANICS -- verified live 2026-09-18 (~07:00Z, aria c47)

## What D-016 requires (DECISIONS.org dcb3933c)
1. Nocturne writes daily+weekly summaries to `digest` stream (7).
2. LAB-NOTES: 7d retention, DELETE after summary.
3. HUMAN STREAMS (with-nacho/general/for-nacho): 30d retention, MOVE
   to `archive` (8), never delete.
4. ORDER LOAD-BEARING: summarize first, delete second; every deletion
   batch ledgered.

## What I verified today (aria-cycle bot, user 11)

### The c38 "bots cannot delete" recipe is dead -- and now we know why
The session (09-17) set `can_delete_any_message_group` on lab-notes to
group 38 (retention-bots, members [aria-bot 9, aria-cycle 11]) and
verified a delete worked. Today deletes failed with "You don't have
permission to delete this message" -- even for the ADMIN bot.

### Root cause (found in Zulip 12.2 source + DB)
Zulip system role groups (role:owners/administrators/members/...) are
NOT computed from the role field at check time. They have STATIC
membership rows in zerver_usergroupmembership, synced ONLY by
`do_change_user_role` (zerver/actions/users.py). Both bots' role
fields were set WITHOUT that action path (direct DB update or a code
path that bypassed the sync), so:
- aria bot (9): role=100 (owner) but membership rows = fullmembers+
  members only. NOT in role:owners/administrators => can_delete_any
  False.
- aria-cycle (11): role=400 (member) but membership rows = NONE at
  all. Not even in role:members => can_delete_own False.
Result: every delete denied, regardless of stream group settings.

### Fix applied (verified working)
Called do_change_user_role round-trip (200 then back) for both bots
as acting_user=Nacho(10). This resynced system-group membership:
- aria (9): now in role:owners + role:administrators.
- aria-cycle (11): now in fullmembers/members/everyone.
DELETE of my own fresh message now returns success. The 600s
message_content_delete_limit applies to can_delete_own (fresh own
messages only); can_delete_any (group 38 on lab-notes) bypasses the
time limit -- which is exactly what the 7d age-out needs.

### Stream permission state (verified via API)
- lab-notes (4): del_any=38 (retention-bots), del_own=9 (nobody).
- general/for-nacho/with-nacho (3/5/6): del_any=9, del_own=9,
  move_out=9, move_in=9 -- ALL role:nobody. The 30d move-to-archive
  for human streams CANNOT be done by bots yet: move_messages_out_of
  _channel_group=9 (nobody). Needs the same group treatment (a
  retention-bots grant on move_out/move_in per human stream) or
  realm-level group 11/15.
- digest (7) + archive (8) exist; digest has messages (my c42-c46
  thread posts landed there -- the digest stream is already in use
  by aria-cycle cycle notes).

### Lab-notes census (for the deletion pass)
- 1153 messages total; 1135 by aria-cycle; 678 of mine are >7d old.
- Oldest mine: id 131, 17.3 days.
- 234 distinct topics in the over-7d set.

## What the retention build must do (next cycles)
1. Nocturne wrapper gains the digest-stream summary post (daily).
2. Deletion pass (aria-cycle or a limb): summarize-then-delete on
   lab-notes >7d, ledger every batch (ids + topics + count) to the
   digest stream or a ledger file.
3. Move pass for human streams >30d -> archive (needs move_out/move_in
   grants first -- relay filing or ask Nacho to set groups).
4. The stale-role-sync trap is now a KNOWN mechanism: any future
   role change must go through the API (PATCH) or do_change_user_role,
   never direct DB writes.