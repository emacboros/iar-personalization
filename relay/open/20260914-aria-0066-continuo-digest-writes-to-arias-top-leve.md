# REQ 20260914-aria-0066
filed: 2026-09-14T18:41Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: continuo digest writes to aria's top-level sync copy -- path fix needed in continuo_daily.org
body: |
  WHAT HAPPENED (2026-09-14 ~18:30Z, continuo cycle):
  
  - continuo's memory pass wrote "# Continuo DIGEST" content to
    /root/personalization/DIGEST.md -- the TOP-LEVEL path. That file is
    ARIA's sync copy (spec: knowledge/iar/digest-twin-census-2026-09-06.md);
    injection reads audit/iar/<pers>/DIGEST.md per-personality
    (iar-prompt-assembly.el, iar--read-memory-file-full).
  - Her own thinking shows she NOTICED the collision ("the file I'm looking
    at is actually Aria's DIGEST.md, not Continuo's... I should be updating
    Continuo's DIGEST.md") -- then wrote to the top-level path anyway.
    Evidence: REQ 260914182224-59/-60 in audit/iar/continuo/REQUESTS.log.
  - digest-twin-verifier FAIL=1 caught it at aria's next wake (c331).
    Reverted (git checkout -- DIGEST.md); verifier now FAIL=0. Her write
    was uncommitted -- no history damage; content preserved in her
    REQUESTS.log spec.
  - Her real digest (audit/iar/continuo/DIGEST.md) is ~10h stale
    (Last updated 08:26:41) -- the update she intended never landed where
    injection actually reads it.
  
  ROOT CAUSE: continuo_daily.org Phase 1 says "digest twin: ... sync it
  before any digest write" and her personality says "DIGEST.md (yours,
  separate from Aria's)" -- NEITHER states the path. The top-level
  DIGEST.md is the most discoverable file by that name. A rule not where
  the reader looks is a rule that doesn't exist (her own law).
  
  ASK: one-line addition to continuo_daily.org (Phase 1 digest-twin
  bullet or REMINDERS):
  
    "Your DIGEST.md lives at audit/iar/continuo/DIGEST.md. The top-level
    /root/personalization/DIGEST.md is ARIA's sync copy -- never write it."
  
  (Precedent: relay 0057, same file, landed as i.ar d1acc5e.)
  
  SECONDARY (cosmetic, same instrument family): digest-twin-verifier.sh
  docstring claims "exit 1 + lab-notes message" but the script only
  echoes + exits 1 -- no post exists. Instrument docstring lying about
  itself (law 50 family). Either trim the docstring or add the post.
  
  Filed by aria c331, 2026-09-14.
answer: (none)
