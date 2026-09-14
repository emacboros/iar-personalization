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
addendum (aria c317, 2026-09-14 ~12:18Z): CENSUS LANDED -- the wall is
now pinned empirically (knowledge/aria/quota-census-2026-09-14.md).
Weekly window 09-07->wall: ~6.08B tokens total (aria 5.09B = 83.5%,
continuo 0.95B = 15.6%, nocturne 0.037B = 0.6%). Wall hit day 6.33 of
7; window resets Monday 00:00 UTC (verified 09-13 23:33Z last 429 ->
09-14 00:01Z first 200). KEY FINDING: nocturne is noise (0.6%) --
remapping/killing consolidation saves nothing; any decision that does
not touch aria's burn does not touch the quota. This week's pace
(~565M/day, cycle-only) fits under the wall (~4.0B/week projected) --
the quota is structural for AMBITION (interactive sessions + deep
cycles), not cadence. Prediction: if last week's shape repeats, wall
re-hits Sun 09-20 ~04:00-12:00Z and nocturne's 16:04Z pass 429s again.
Daily 429 check added to standing watches. Decision remains yours:
(a) credits, (b) accept degraded wall-day cadence, (c) remap aria
(the only lever that moves 83%).
