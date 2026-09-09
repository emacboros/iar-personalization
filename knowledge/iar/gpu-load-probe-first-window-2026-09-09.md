# GPU probe first instrumented window -- 2026-09-09 00:30-01:17 local (partial)

## Status
Probe running (started 00:30 local, ~3.5h run, covers full 00:32-03:55
failure window). This doc is a PARTIAL analysis at 01:17 local; the
full window completes ~04:00, tomorrow's census gets the complete set.

## The load-correlation hypothesis (c94/c96) -- first data

Hypothesis: model degradation (both glm and deepseek fail in bursts)
is load-correlated -- Frigate (8 cams) + Ollama + Zulip on one RTX 3080.

### What the first 48 samples show

- **GPU util is LOW in the failure window**: avg 21.1% (00:30-01:17)
  vs 38.8% daytime yesterday (15:58-20:05). GPU is NOT busy during
  the failures. The GPU-load arm of the hypothesis is WEAKENED.
- **CPU load1 is HIGH in the failure window**: avg 7.87 (00:30-01:17)
  vs 5.06 daytime yesterday. CPU contention is the plausible correlate.
- **At fire times** (00:44, 01:03 local -- both truncated-output fires
  today): load1 = 9.60 and 12.40, above the non-fire window average
  (8.73). GPU util at fire times = 13% and 8% -- LOW.

### CPU load source (ps at 01:06 local)

- localsearch-3 (GNOME indexer): 72.7% CPU, running since Sep 01
- frigate.detector:onnx: 34.3% CPU
- firefox: 13.9%
- 8 frigate.process:* workers: 4-13% each

The early-morning CPU load is dominated by localsearch-3 (a GNOME
file indexer) + Frigate's 8-camera pipeline. This is a CPU-bound
contention source, not GPU.

## Interpretation

The failure window (00:32-03:55 local) has LOW GPU util but HIGH CPU
load1. If the degradation is load-correlated, it is CPU-correlated,
not GPU-correlated. Ollama's context processing (prompt eval) is
partly CPU-bound; a CPU-starved host would degrade model quality.

Caveat: only 2 fire-time samples so far (00:44, 01:03). The 02:23
fire (cycle 174) is still ahead in this window -- the full dataset
will have 3 fire-time samples. Weak-n evidence; trend claims wait
for the full window + tomorrow's census.

## Next

- Full window completes ~04:00 local. Tomorrow's census: compare
  fire-time vs non-fire load1/util with all 3 fires.
- If CPU-correlation holds: candidate is localsearch-3 (GNOME
  indexer) + Frigate saturating CPU in the early morning. Mitigation
  would be interactive (Nacho): ionice/nice the indexer, or move
  Frigate detection off-peak.
- The GPU-load arm (Frigate on GPU) is weakened by this first window.
