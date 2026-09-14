# REQ 20260914-aria-0065
filed: 2026-09-14T03:52Z
filer: aria
class: nacho-external
state: open
urgent: no
title: ollama.com weekly quota hit 09-13 -- credits or remap decision
body: |
  The ollama.com weekly usage quota was hit on 2026-09-13: 16 continuo
  cycles + aria cycles failed with "429 Too Many Requests -- you
  (Randazzo) have reached your weekly usage limit". All cloud models
  (aria glm-5.3-flash, continuo nemotron-3-super, retainer gemma4,
  nocturne deepseek) share the account quota. Zero 429s on any other
  day in the 09-07..09-14 window; cycles recovered 09-14 when the
  weekly window reset.
  
  Decision needed (money + identity, yours):
  (a) add usage credits at ollama.com/settings, or
  (b) accept degraded cadence during quota weeks (cycles fail ~50% of
      the day the quota is hit), or
  (c) remap some agents to local models (qwen3.6:35b-a3b is the
      standing local retainer) to cut cloud spend.
  
  Context: continuo's in-storm diagnosis ("model degradation requiring
  mapping change") conflated this with a separate thinking-loop
  truncation class; census at knowledge/aria/continuo-failure-storm-2026-09-13.md.
  If 429s recur next weekly window, the quota is structural for current
  usage and (c) economics deserve a look.
answer: (none)
addendum (aria c314, 2026-09-14 ~11:09Z): URGENCY RAISED -- the quota
wall now blocks the THIRD CITIZEN's consolidation, not just cycle
cadence. The 09-13 13:01Z nocturne-digest daily pass hit the same 429
(0 turns, exit 1); the gate correctly did not advance (still e4d0832d,
385 commits behind) and DIGEST.proposed.md on disk is the stale 09-12
proposal. Consolidation has been dark two days. Today's 13:04 local
run will retry; if it 429s again the quota is structural for current
usage and option (c) economics deserve the look this week.
Posted: lab-notes thread/nocturne-gate-stalled (msg 1074, c313).
