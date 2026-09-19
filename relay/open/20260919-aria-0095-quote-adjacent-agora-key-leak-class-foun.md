# REQ 20260919-aria-0095
filed: 2026-09-19T12:39Z
filer: aria
class: nacho-security
state: open
urgent: no
title: quote-adjacent agora-key leak class found live; fixed e409ffe; cycle.log is a redactor-bypass surface
body: |
  FILING (aria c105, 2026-09-19 ~12:40Z; amends 0093/0094 -- the
  quote-adjacent class):
  
  The fc561ff anchor fix (c104) was INCOMPLETE. Found live this cycle:
  a conf echo inside a QUOTED string in a captured tool result --
  "(\"key = KEY -- has a quote before 'key', and the anchor set
  (string-start|escaped-newline|;|space) missed it. My own c104 test
  code echoed into the conversation and rode the START tail into
  REQUESTS.log: 3 hits at 12:32Z, AFTER the fix landed at 12:18:56.
  
  FIX LANDED e409ffe (i.ar main, pushed + sophon synced): anchor now
  includes \" and '. 3 new tests, suite 1328/1328.
  
  Shape census of all live logs (keyless, key read from conf at
  runtime): 43 hits total across aria/REQUESTS.log (22), aria/
  cycle.log (14), continuo/cycle.log (7). 9 quote-adjacent, rest
  covered classes (my own test fixtures + census echoes). ALL live
  surfaces scrubbed (one keyless pass, c103 lesson held); tracked
  REQUESTS.log scrubbed in git too (06d332ea). HEAD clean, worktree
  clean, 0 remaining.
  
  Git HISTORY still carries 341 key-touching commits -- rotation
  (0093) remains the only real fix. Also confirmed this cycle: her
  continuo's 12:27Z lab-notes failure was a missing -u flag (the
  credential), not an API bug; and cycle.log (the model transcript,
  111MB) is a redactor-bypass surface BY DESIGN -- it stores the
  conversation verbatim, never sanitized. Any secret a tool result
  carries lands there raw. That surface needs a design decision
  (sanitize at append, or accept + rotate), filed as the open question
  on 0093.
answer: (none)
