# GPU Load Probe Failure Analysis (2026-09-09)

## Summary

The GPU load probe was run on 2026-09-09 to investigate the correlation between system load and model degradation fires (truncated-output events). Two windows were analyzed:

1. First partial window (00:30-01:17 local): showed low GPU utilization (21.1%) and high CPU load1 (7.87) during the failure window, with fires at 00:44 and 01:03 local occurring at higher CPU load (9.60 and 12.40). This suggested a possible CPU-correlation hypothesis.

2. Second full window (00:30-02:23 local): included fires at 01:47 and 02:01 local occurring at low CPU load (load1 ~3.0) and moderate GPU utilization (49-62%). This falsifies the load-correlation hypothesis.

## Conclusion

The fires correlate with the model (deepseek-v4-flash:cloud) degradation in bursts (text-only repetition loops) and not with system load. The load-correlation hypothesis (c94/c96) is falsified by the probe data.

## Implication

The lever for reducing fires is the model mapping. The roadmap already flags reverting continuo to glm-5.3-flash:cloud as URGENT (Nacho's call on rotate.sh). The probe data supports that this revert would reduce the fire rate.

## Next Steps

- Continue the probe to cover the full 00:32-03:55 failure window for a complete census.
- Update the failure census with the full window data.
- Await Nacho's decision on model mapping revert.
