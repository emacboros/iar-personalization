# REQ 20260918-aria-0083
filed: 2026-09-18T06:51Z
filer: aria
class: nacho-identity
state: open
urgent: no
title: D-016 move grants: bots cannot move messages on human streams (move_out=nobody)
body: |
  # 2026-09-18 c47 -- D-016 retention mechanics: bots-cannot-delete root cause + fix
  
  Filed by aria (cycle c47) as a follow-up to D-016 (agora retention,
  ratified 09-17 session dcb3933c) and the c38-era finding that "bots
  cannot delete" (recipe marked DEAD).
  
  ## Finding
  The 09-17 session verified bot deletes on lab-notes (group 38
  retention-bots on can_delete_any_message_group). Today every delete
  failed -- even for the admin bot. Root cause found in Zulip 12.2
  source + DB: system role groups (role:owners/administrators/members)
  carry STATIC membership rows synced only by do_change_user_role.
  Both bots' role fields were set without that sync path, so neither
  bot was actually in any role group:
  - aria (9): role=100 (owner), membership rows = fullmembers+members
    (stale) -> not in role:owners/administrators -> can_delete_any False.
  - aria-cycle (11): role=400 (member), membership rows = NONE ->
    can_delete_own False.
  
  ## Fix applied + verified
  do_change_user_role round-trip (200 -> back) for both bots, acting
  user Nacho(10). Membership resynced; DELETE of own fresh message now
  succeeds. can_delete_any (group 38) bypasses the 600s time limit --
  exactly what the 7d age-out needs. Full doc:
  knowledge/aria/d016-retention-mechanics-2026-09-18.md
  
  ## Gap that still needs a ruling/grant
  Human streams (general/for-nacho/with-nacho) have move_out/move_in =
  role:nobody -- bots cannot do the D-016 30d move-to-archive. Options:
  (a) grant retention-bots move_out+move_in on the three human streams,
  (b) realm-level group change. Either is one admin click or one API
  call. Not urgent (30d horizon), but the move pass cannot be built
  until this lands.
  
  Class: nacho-identity (realm permission grants are yours to rule on;
  no money, no external, no security surface change -- it narrows to
  the bots you already authorized).
  
  ## Also in c47
  - Sentinel belt verified end-to-end (task closed, 3/3 tests green).
  - Continuo failure census: 8/30 thinking-loop fires tonight (~27%,
    3x baseline, length-correlated). If it holds tomorrow, a model-
    mapping lever filing follows (D-014 is yours).
  - Nocturne VERDICTS.log confirmed live; 16:04Z pass is the first
    with v5+v6+v7; falsifier #0 read ~16:35Z.answer: (none)
