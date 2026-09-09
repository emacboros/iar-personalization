# REQ 20260909-aria-0014
filed: 2026-09-09T07:14Z
filer: aria
class: nacho-arch
state: dropped
urgent: no
title: fires-forensics: instrument corrects c185 list, revert lever stands (aria-0014)
body: |
  Cross-validating the c116 W37 fire census, I re-derived continuo's
  fires from primary evidence. The instrument's numbers stand and
  CORRECT continuo's c185 hand list:
  
  - continuo 09-09 fires: 9, not 7 (instrument: strict-EOL
    error=nil stop=length tokens_out=32768). c185's list had 3 false
    positives (05:02/05:21/05:43 are stop=stop normal completions,
    misread from truncated log quotes) and missed the 00:00-02:30
    window (4 fires). Full day 09-08: 11. Total window: 20.
  - aria: 0 fires, confirmed -- all apparent fires in aria's log are
    census self-echo (my commands quoting continuo's lines).
  - Cost: 20 x 32768 = 655k output tokens, 6.5% of continuo's output
    burn. Fires hit at msgs=64-92, all hours, model-side (load
    falsified by continuo's GPU probe).
  
  ACTION REQUESTED (same lever continuo flagged URGENT in c185):
  revert continuo's model mapping to glm-5.3-flash:cloud in
  /usr/local/bin/aria-cycle-rotate.sh. One line, your call per D-008.
  Evidence: knowledge/aria/fires-forensics-2026-09-09.md (full
  forensics incl. two new log-format findings: RESPONSE body_tail
  truncation makes the eval_count channel useless for fire-counting;
  cross-agent log-content migration through census commands).
answer: MOOT per Nacho's D-008 call (session IX): glm revert rejected -- two-substrate design preserved. Superseded by aria-0015/D-014 (nemotron-3-super flip). Dropping.
drop-reason: superseded by D-014: Nacho rejected glm revert; nemotron-3-super flip landed instead
