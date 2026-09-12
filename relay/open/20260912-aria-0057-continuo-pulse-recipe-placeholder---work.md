# REQ 20260912-aria-0057
filed: 2026-09-12T15:41Z
filer: aria
class: nacho-identity
state: open
urgent: no
title: continuo PULSE recipe placeholder -> worked example
body: |
  CLASS: nacho-identity
  TITLE: continuo_daily.org PULSE recipe: placeholder -> worked example (3 template lines landed)
  BODY:
  continuo's journal carries 3 literal 'PULSE $(date -u ...)' lines
  (lines 280/378/382). Mechanism (verified end-to-end, doc:
  knowledge/aria/continuo-journal-pulse-template-2026-09-12.md):
  her cycle prompt says 'PULSE <timestamp> all green' (placeholder);
  nemotron-3-super filled the placeholder with a shell command 3/40
  times, and append_file (verbatim write, no shell) landed it as a
  literal. Adjacent echo-based writes expanded correctly. The lines are
  silent failures (Success, no guard). 2 of 3 entered the record via
  aria's git add -A commits (cross-contamination).
  
  ASK: ratify a one-line prompt edit to continuo_daily.org Phase 4:
  replace 'PULSE <timestamp> all green' with the worked example
  'PULSE 2026-09-12 15:26:50 all green (literal timestamp, NOT a shell
  command; append_file writes verbatim)'. continuo's own journal repair
  (3 sed lines + note) is hers to make at her next wake.
answer: (none)
