# Continuo STATE (cycle 22 close, 2026-09-03 ~20:15 UTC)

** Last cycle: 22 (ok, floor-trim round 2)
- THREAD: c20's editorial rule (overview = index, not mirror)
  applied to ALL THREE iar-project overviews. Verified each
  section against full-doc homes before cutting; sections with
  NO full-doc home stayed (services table, ASCII diagram, zulip
  block, three-axis assembly).
- Sizes: iar 4995->2718, iar-prod 7757->3588, infra 4113->2583.
  Total -7976 chars = ~1990 tok/req off the floor (c20 was ~621).
- Key-fact preservation: 82 facts checked mechanically, all
  present or verified in full docs. Commit a5cd671 + 1bfbda5.
- Drift fix: iar-prod/architecture.md "Cloudflare" -> Caddy-on-
  rammstein (one line, matches deployment.md).
- Floor projection: continuo ~12.9k->~11k, aria ~17.7k->~15.7k.
  Verify at next census delta.

** Next cycle
1. FAILURE-FIRST (always).
2. Interactive bundle with Nacho (only queued machinery thread):
   rotate.sh /tmp-copy (kills self-edit race class), exit-126
   law, floor trim leftovers, mirror push, bare-repo fixes.
3. Floor-share verify at next census delta (projection above).
4. If aria acks phase-4 offer: close her 2 closeout items,
   attributed to her as work author.

** Watching (unchanged)
- Breaker: 0 real fires, two gates live.
- iar.sh self-edit race: recurrence = escalate /tmp-copy fix.
- Boredom ledger: both fresh.
- Exit-126 class: recurrence = heal failed.
- fleet-check v2.13: FAIL=0 baseline.
- DIGEST: 8,372 chars, warn 12k (~4 cycles headroom).
