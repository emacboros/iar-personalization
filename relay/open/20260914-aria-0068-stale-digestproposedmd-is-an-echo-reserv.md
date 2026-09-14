# REQ 20260914-aria-0068
filed: 2026-09-14T20:58Z
filer: aria
class: ours-direction
state: open
urgent: no
title: stale DIGEST.proposed.md is an echo reservoir -- ratify-or-delete policy
body: |
  # REQ 20260914-aria-0068
  filed: 2026-09-14T20:58Z
  filer: aria
  class: ours-direction
  state: open
  urgent: no
  title: stale DIGEST.proposed.md is an echo reservoir -- ratify-or-delete policy
  body: |
    PROVEN mechanism (c336, evidence chain verified against disk):
    The 09-14 16:04Z Nocturne pass re-emitted the 09-12 final response
    VERBATIM (byte-identical, DIGLOG block-4 == block-6). Source: the
    STALE audit/iar/aria/DIGEST.proposed.md (mtime Sep 12 19:40, 11006
    bytes, UNRATIFIED) sitting on disk since the 09-12 run. The pass
    read it (its header quotes the 09-12 response), the text entered
    context, and the model echoed the strongest matching text as its
    "final response". The v3 mtime-gate correctly refused to advance;
    the v4 echo-check (landed 15:58 local, AFTER the 13:04 run) would
    have CAUGHT the echo -- first live v4 test Tue 13:00 local.
  
    The problem: an unratified proposal is unratified STATE that every
    subsequent pass reads. It poisoned pass #2 (09-14) and will poison
    every pass until ratified or deleted. The echo-check is the net,
    but the reservoir keeps burning 1.3M tokens per pass to re-emit
    stale text.
  
    PROPOSAL (needs your ratification):
    1. POLICY: DIGEST.proposed.md is ratified-or-deleted -- after each
       pass, either you ratify (copy to the live DIGEST) or the file is
       deleted before the next pass. Never left stale on disk.
    2. IMMEDIATE: delete the current stale proposal (I can do this --
       it is my file, aria's DIGEST.proposed.md) once you approve.
    3. The v4 echo-check stays as the net regardless.
  
    Alternative if you prefer: I delete-on-unratified-read inside the
    wrapper (mechanical, no policy needed) -- but that is a machinery
    change to nocturne-digest.sh, which is mine to make; your call on
    whether the policy or the mechanism carries the rule.
answer: (none)
