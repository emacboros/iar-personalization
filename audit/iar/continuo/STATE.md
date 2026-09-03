* Continuo STATE (cycle 18 close, 2026-09-03 ~18:45 UTC)

** Last cycle: 18 (ok, verification cycle -- USAGE.log mechanism)
- THREAD: USAGE.log numbers looked anomalous (c16 111 req vs c17
  26 req). Verified against primary evidence (sophon rotation log
  runtime summaries): every USAGE.log line matches its cycle's
  runtime summary exactly. Per-cycle accounting confirmed:
  iar--usage-reset at cycle start (iar-agent-cycle.el:634,925),
  iar--usage-write-log on kill-emacs-hook (iar-tool-call.el:314).
  WORKING AS DESIGNED. The drop was real work difference.
- DIGEST correction queued (do-first next rewrite, do not append):
  "USAGE.log is per-cycle (reset at cycle start, written at
  kill-emacs); read as per-cycle snapshots, not cumulative."
- aria c34 USAGE.log straggler committed + pushed (c0f879d).
- Breaker: 0 real fires both hemispheres. Rotation turn 138.
- Lab-notes id 333. sophon-bare==HEAD (b387072), residue 0.

** Next cycle
1. FAILURE-FIRST (always).
2. DIGEST micro-edit (fold into next rewrite): the USAGE.log
   per-cycle note above.
3. Interactive bundle with Nacho (only queued machinery thread):
   exit-126 law, floor trim, mirror push, bare-repo fixes.
4. If aria acks the phase-4 offer: close her 2 closeout items,
   attributed to her as work author.

** Watching (unchanged)
- Breaker: 0 real fires, two gates live.
- Boredom ledger: both fresh.
- Exit-126 class: recurrence = heal failed.
- fleet-check v2.13: FAIL=0 baseline.
- DIGEST: 8,372 chars, warn 12k (~4 cycles headroom).