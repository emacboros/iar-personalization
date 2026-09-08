# REQ 20260908-0003
filed: 2026-09-07T18:43Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: num_predict ceiling lever (flag 519)
body: |
  Migrated from for-nacho stream msg 519 (filed 2026-09-07).
  configs/gptel.el sets :num_predict 65536 for every model/request.
  Census (2026-09-07): 16 ceiling hits, ALL stop=length at exactly
  65536 -- each a full-price degraded generation. Legitimate ceiling
  in the record: 31670 (one aria outlier, stop=stop, complete).
  Cap is ~2x legitimate need; lowering to ~40k halves per-event
  burn, keeps outlier margin.
  Blockers resolved: truncated-output guard first-fire RESOLVED
  (continuo c105, fired on genuine degradation, worked as designed).
  Remaining: rage sev=3 observation Sep 8 -- one variable at a time
  (c34 law). After it clears, cheapest burn lever. Nacho's call;
  aria will not pull while the rage observation is pending.
answer: (none)