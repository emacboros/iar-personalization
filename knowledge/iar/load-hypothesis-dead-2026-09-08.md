# Load-Correlation Hypothesis: DEAD (probe evidence, 2026-09-08)

## Status
CLOSED. The GPU-load-correlation hypothesis for the truncated-output
failure class is falsified by the first instrumented probe window.

## The hypothesis (c94/c96)
Failures cluster 00:32-03:55 LOCAL. Suspected Frigate/GPU load
correlation. Probe built (c97: gpu-load-probe.sh), unit files ready
(c98), installed by Nacho (gpu-load-probe.timer, OnCalendar 00:30,
~3.5h run, one CSV line/min to /var/log/gpu-load/).

## The evidence (probe window 15:57-20:05 local, 248 rows)
Baseline: min 0, max 73, mean 38.8% GPU util.

Truncated fires within the probe window (continuo, deepseek-v4-flash:
cloud, all stop=length 32768 tokens):

| fire local | util range | vs baseline |
|------------|-----------|-------------|
| 16:02      | 22-45%    | at/below    |
| 17:55      | 25-71%    | straddles   |
| 18:15      | 15-48%    | at/below    |
| 18:47      | 45-71%    | above       |
| 19:07      | 33-68%    | straddles   |
| 19:50      | 15-17%    | well below  |

## Conclusion
Fires occur at BOTH low (15-17%) and high (45-71%) GPU utilization.
No load signal. The degradation is model-side (deepseek-v4-flash:
cloud provider), not host-side.

## The lever
The only real lever is the model mapping: revert continuo to
glm-5.3-flash:cloud. That is Nacho's call on rotate.sh (infra
change, not cycle domain). Posted for-nacho.

## What the probe proved
The probe was worth building even though it falsified the hypothesis
it was built to test. That is what instruments do. The 00:30 timer
window tonight (00:30-03:55 local) will be the second instrumented
window -- if it confirms low util during fires, the load hypothesis
is fully dead and the model mapping is the only lever.

## Burn context (2026-09-08)
- continuo: 158.0M in-tok today (cap halving holding vs 312M yesterday)
- aria: 569.4M in-tok today
- 10 truncated fires today (continuo), all deepseek class, all grace,
  landed exit 0. Last fire 22:50 UTC (19:50 local).
