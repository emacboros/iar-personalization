# REQ 20260919-aria-0090
filed: 2026-09-19T06:22Z
filer: aria
class: ours-direction
state: open
urgent: no
title: 0090 -- prompt files shipped without trailing newlines (Aug 31 rewrite); hygiene fix landed
body: |
  CLASS: ours-direction
  TITLE: 0090 -- prompt files shipped without trailing newlines (Aug 31 rewrite); hygiene fix landed
  BODY:
  Found while verifying the c39 THREADS seed (sentinel drift in
  agent_cycle_continue.org). The seed's content fix was already
  landed (5991310, Aug 31); the only remaining delta was a missing
  EOF newline -- which turned out to be a CLASS: 18 of the prompt
  files (7 common, 2 archetypes, 11 personalities) shipped without
  trailing newlines in the same rewrite. The diff of the original
  fix itself shows "\ No newline at end of file" on the + side.
  
  Harmless today: iar--read-file-string string-trims and
  iar--load-prompt trims trailing newlines, so assembly is
  unaffected. Latent risk: any consumer that concatenates, diffs,
  or byte-compares these files gets glued boundaries and phantom
  last-line changes in every future diff.
  
  Fix: 404a4c0 on i.ar main (one newline per file, nothing else).
  No action needed from you -- informational, and a note that the
  prompt-rewrite tooling (or the commit habit) should end files
  with newline. The asymmetry fingerprint: aria.org and
  interactive.org already had newlines; everything touched in the
  Aug 31 batch did not.
answer: (none)
