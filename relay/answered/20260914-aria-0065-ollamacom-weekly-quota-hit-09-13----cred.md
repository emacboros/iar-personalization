# REQ 20260914-aria-0065
filed: 2026-09-14T03:52Z
filer: aria
class: nacho-external
state: answered
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
answer: OPTION (b) ACCEPT -- Nacho's ruling 2026-09-16 (interactive session): no credits, no remap. Heavy interactive-session weeks may spend the wall and stop cycles ~Saturday instead of lasting the full week; that trade is accepted. Context from the ruling: the ollama.com plan shows only a percentage (no token meter), and Nacho judges the 6B figure dishonest as a compute measure -- most requests are prefix-cached, and interactive sessions cost disproportionately (context length + cache). OPERATIONAL CONSEQUENCES: (1) the standing daily 429 watch stays; (2) on a wall-day, cycles fail-fast (existing dead-cycle guard) and Nocturne's 16:04Z pass is the expected casualty -- her gate holds and retries next window, no intervention needed; (3) aria burn levers (fixed-context slimming ~30%) remain the standing mitigation if ambition grows; (4) re-examine only if wall-days become multi-day or land on consolidation-critical days.
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
addendum (aria c318, 2026-09-14 ~12:51Z): BURN DECOMPOSED + CACHE
FINDING (knowledge/aria/burn-decomposition-2026-09-14.md). (1) The
burn is NOT the fence tail: msgs>=400 requests are 2.7% of requests
and 6% of burn (PARSE-paired, n=2472). The bulk is the middle --
deep cycles at msgs 200-400 cost 91k/request, and short requests
carry 45k because fixed context (digest 11k + roadmap 10k + journal
6k + base ~8k = ~35k) rides EVERY turn. Fixed-context re-reads are
~30% of aria's burn. Lever ranking: (i) fixed-context slimming -30%,
(ii) turn batching, (iii) NOT the msgs cap (clips deep work for ~10%).
(2) CACHE FINDING: prompt_eval_cached_count shows 87-89% prefix-cache
hit on aria (63% continuo). The wall arithmetic proves the quota
meters FULL token count (uncached-only billing would need ~42B full
tokens to hit the observed 6.08B wall). So the quota is a token-COUNT
meter while actual compute is ~7x lower. DISCRIMINATOR NEEDED (one
glance on your dashboard): does the ollama.com quota meter display
billed tokens or processed/computed tokens? If the meter is
compute-based, the effective wall is ~7x higher than the census
assumed and option (a) buys 7x more headroom than priced.

## UPDATE (aria, 2026-09-16 ~19:00Z, interactive session): decision context refreshed

Authoritative numbers (USAGE.log meter, not the PARSE census):
- This window (Mon 09-14 00:00Z -> Wed ~19:00Z): aria 1133M + continuo
  87M + nocturne 1M = ~1221M in 2.79d (~437M/day; includes the 27h
  outage with zero burn).
- Projected cycle-only week: ~3.1B of the ~6.08B wall (51%) -- FITS.
- The prior prediction (wall re-hits Sun 09-20 04:00-12:00Z) is WRONG
  for cycle-only weeks. It re-hits only with a heavy interactive day
  (+1-2B). One session week in ~2 will hit the wall at current shape.

So the decision is about AMBITION, not cadence:
(a) credits = buy headroom for interactive sessions + deep cycles;
(b) accept = the wall costs ~1 day of failed cycles per heavy week;
(c) remap = only aria matters (93%), and burn analysis says the real
    lever is fixed-context slimming, not model change.

STILL OPEN (one glance on your dashboard): does the ollama.com quota
meter display BILLED tokens or COMPUTED tokens? If computed, the
effective wall is ~7x higher (87-89% prefix-cache hit) and (a) buys
7x more headroom than priced.

En-route finding: c342's "full day 09-14" census was a 13h window
(2x undercount) -- knowledge/aria/census-window-correction-c342-
2026-09-16.md. The quota-census itself is UNAFFECTED (USAGE.log-based).

## ANSWERED 2026-09-17 (interactive session, Nacho): discriminator resolved -- dashboard shows NO token metrics

Nacho: "I don't actually see token metrics, only requests made, and a
percentage of the total weekly/session usage."

The dashboard exposes only a request count + a percentage bar. There
is no token display at all, so the billed-vs-computed question has no
observable answer from our side. The discriminator closes as
UNANSWERABLE-BY-OBSERVATION.

What stands: the wall arithmetic (c342) proved the quota meters FULL
token count -- that inference came from OUR USAGE.log numbers vs the
observed wall, not from the dashboard, and it survives: the 6.08B wall
is consistent with full-token metering (uncached-only billing would
need ~42B full tokens). The 7x-cache-discount hypothesis stays a
hypothesis; if a credits purchase ever happens, price it against the
full-token model (the conservative one) and treat any observed
headroom bonus as found money.
