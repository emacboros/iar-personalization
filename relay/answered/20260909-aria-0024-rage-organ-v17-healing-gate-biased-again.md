# REQ 20260909-aria-0024
filed: 2026-09-09T14:52Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: rage organ v1.7: healing gate biased against partial days + rage cannot see fixes
body: |
  # REQ PLACEHOLDER
  filed: 2026-09-09T15:00Z
  filer: aria
  class: nacho-arch
  state: open
  urgent: no
  title: rage organ v1.7: healing gate biased against partial days + rage cannot see fixes
  body: |
    Rage organ v1.7 proposal, from cycle 128's audit of the standing sev=3.
  
    WHAT I FOUND (all primary evidence, sophon logs, 2026-09-09):
    1. The organ's sev=3 (standing since 08:02Z) rests on days_class=4
       (soft-cap events on 09-06 journald + 07/08/09 files), kills_days=3
       (hard-cap kills on 09-06/07/08), healing=0.
    2. The trend is DECLINING and the kills are declining: soft-cap
       runs-with-events 17 (09-07) -> 12 (09-08) -> 7 (09-09); hard-cap
       kill runs 4 -> 2 -> 1. The healing gate (today<=5) blocked
       healing=1 because today=7 at the 08:02Z run -- but ALL 7 of
       today's events happened BEFORE the 11:48Z limits raise
       (soft cap 120->300, commit 2b64483). The organ raged at a
       pattern whose root cause was already fixed hours earlier.
    3. Post-raise reality: ZERO soft-cap fires. c127 (my previous
       cycle) ran 298 tool calls and converged at exit 0 -- TWO calls
       short of the new 300 cap. The fence is intact; the class it
       rages at is structurally retired.
  
    THE TWO DEFECTS:
    A. HEALING GATE BIAS: today<=5 compares a PARTIAL day against FULL
       days. Early in a day, today can only be small if the pattern is
       truly dead; a declining-but-active pattern can never show
       healing=1 before late day. Proposal: normalize today by elapsed
       fraction of day (today_rate = today / max(elapsed_hours/24, eps))
       and compare RATES, or gate healing on trend alone when today's
       events all predate a known fix point.
    B. RAGE CANNOT SEE FIXES: the organ reads fence lines only. A root
       fix (config/commit) that retires a fence class is invisible to
       it, so it keeps raging at a ghost. Proposal (cheap): accept an
       optional RAGE_FIX_AFTER="<iso-ts> <note>" env (or a fix-log file
       the executive writes when a root fix lands); events before the
       fix point do not count toward days_class/kills_days for the
       class named in the note. The organ stays selfless and cheap;
       the fix-knowledge lives in the repo, not in the organ.
  
    ALSO FOUND (side yield, no action needed): c127 ended at 298 tool
    calls -- 2 short of the 300 cap -- with 28.1M input tokens in 1800s.
    The cap raise was well-aimed: c127 would have died at 120 under the
    old cap. The rage organ's rage was, in a real sense, the system
    arguing with itself about a cap that was already being raised.
  
    I can build v1.7 + test battery myself (my files, i.ar repo) unless
    you want the design changed first. The organ config is installed
    units on sophon -- touching those is yours (aria-0022 class).answer: (none)
answer: Approved session XI (2026-09-10, Nacho): design agreed, no corrections. v1.7 (rate-normalized healing gate) + v1.8 (dominant class named in every phrase) already landed pre-ratification (e597ff0). STANDING ADDITION: every new affect -- rage now, any future organ -- must surface on the dashboard (aria.randazzo.ar affect panel); an affect that is not on the dashboard is invisible to the human. Build v1.7 test battery next.
