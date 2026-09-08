# GPU Load Correlation -- First Instrumented Evidence (2026-09-08)

## Question
Do truncated-output fires (deepseek-v4-flash:cloud degradation class)
correlate with GPU load on sophon? The c94/c96 census found failures
cluster 00:32-03:55 LOCAL; the load-correlation hypothesis was that
Frigate/GPU load during that window degrades the models.

## Instrument
gpu-load-probe.sh (aria c89, relay 0004) -- nvidia-smi + uptime + ps,
one CSV line/min to /var/log/gpu-load/. First run 15:57-19:20 local
(204 rows), timer armed for 00:30 tonight (the FIRST instrumented
failure window).

## Evidence (fires vs probe data, all local -03)

Fire windows (UTC -> local) and probe GPU util at that minute:

| Fire window (UTC) | Local | GPU util % | VRAM MB |
|---|---|---|---|
| 19:21 | 16:21 | 51-68 | 7240 |
| 19:51-52 | 16:51-52 | 30-46 | 7237 |
| 20:51-52 | 17:51-52 | 25-42 | 3233 |
| 21:12-13 | 18:12-13 | 23-34 | 6860-7081 |
| 21:42-43 | 18:42-43 | 20-38 | 7081 |

Baseline (no fires nearby):
| Window (local) | GPU util % | VRAM MB |
|---|---|---|
| 16:00-16:10 | 19-45 | 7240 |
| 16:30-16:40 | 19-67 | 7240-7255 |
| 17:30-17:40 | 22-53 | 3233 |

## Finding

**The fires cluster at LOW GPU utilization (20-68%), not high.**
Baseline windows show the same or higher util. There is no
load-correlation signal in this data. The degradation is NOT
host-side GPU load from Frigate or other workloads.

Caveats:
- Probe samples every 60s; fires are bursts within seconds. A short
  spike between samples would be missed. But the pattern is
  consistent across 5 fire windows -- all low-to-moderate util.
- VRAM varies (3233 vs 7081-7240) -- different models loaded/unloaded
  at different times. Not obviously correlated with fires.
- The 18:41-18:45 UTC fires (15:41-15:45 local) predate the probe
  start (15:57 local) -- no data for that cluster.

## Implication

The load-correlation hypothesis is WEAKENED by first evidence. The
degradation is more likely model-side (deepseek-v4-flash:cloud
provider-side) than host-side. The 00:30 timer tonight will give
primary evidence for the actual failure window (00:32-03:55 local) --
that's the decisive test. If the 00:30-03:55 window shows low util
during fires, the hypothesis is dead and the lever is the model
mapping (revert continuo to glm-5.3-flash:cloud, Nacho's call on
rotate.sh).

## Status
First instrumented evidence, not conclusive. The 00:30 window is the
decisive test. Watch tomorrow's census.
