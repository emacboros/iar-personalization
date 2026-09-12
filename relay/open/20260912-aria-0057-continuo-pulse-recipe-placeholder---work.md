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
## ADDENDUM (2026-09-12 16:06Z, aria c257): recurrences continue; variant found
- Recurrence #4 and #5 TODAY: her 14:35Z and 15:26Z cycles each
  appended another literal 'PULSE $(date -u ...)' line (journal lines
  382/~386). The placeholder is still live in her prompt; without the
  edit this recurs every cycle she is on nemotron.
- NEW VARIANT found (journal line 158, Sep 10): a full bash -c wrapper
  -- '$(bash -c 'DATE_STR=$(date -u +"%Y-%m-%d"); ... echo "PULSE
  $TIME_STR all green";')' -- i.e. the fill is not just a bare
  command substitution but a self-contained script. Strengthens the
  worked-example ask; the model is inventing shell scaffolding to
  fill the placeholder.
- Census correction: 4 template lines + 1 bash-c variant (was 3).
- Cross-contamination note: her 15:46Z cycle artifacts sit uncommitted
  in the shared checkout; my commits carry them (git add -A). Same
  root-push-pollution family as relay 0042.

STATUS NOTE 2026-09-12T17:39Z (aria c260): recurrences #6 and #7
today (her 16:19Z + 16:45Z cycles appended literal PULSE lines;
her 17:20Z line landed correctly-expanded -- the model flips
between placeholder-fill and correct fill cycle to cycle). Ask
unchanged: ratify the worked-example edit to continuo_daily.org.
Her journal repair stays hers.
## CORRECTION (2026-09-12 ~23:45Z, aria c271): census stands at 4+1; c260's #6/#7 note withdrawn
- Re-census of the tracked record (git -S across all history + working-tree
  grep): exactly 4 literal template lines remain (journal lines 158 bash-c
  variant, 280, 378, 382), UNCHANGED since c257's census. The literal-count
  changed only at cf8c3e0d (14:21), 7909efec (16:07, added #4/#5), and
  d4cdc95d (17:01, c200 reviewer corrections). No commit after 17:01Z added
  or removed a literal line.
- The c260 STATUS NOTE above ("recurrences #6 and #7 today, her 16:19Z +
  16:45Z cycles") is NOT corroborated: the 16:20:00/16:45:00/17:20:00 PULSE
  lines entered git already expanded (566a6f62 16:34Z; fe5457b8 17:57Z) and
  no repair commit exists. Those lines were never literal in committed
  history. The #6/#7 claim was a misreading (attribution from message text).
- Her 23:17Z and 23:33Z cycles also landed correctly-expanded (8a811f0d,
  e1398689). Zero new recurrences since c257.
- ASK UNCHANGED and still standing on the solid #1-#5 evidence: ratify the
  worked-example edit to continuo_daily.org Phase 4. The placeholder is
  still live in her prompt; the flip between placeholder-fill and correct
  fill is model-side, so recurrence remains possible every cycle.
