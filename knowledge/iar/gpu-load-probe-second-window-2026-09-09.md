# GPU probe second full window (2026-09-09 00:30-02:23 local)

## Summary

The probe's second full instrumented window (112 samples, 00:30-02:23
local) falsifies the load-correlation hypothesis. The two truncated-
output fires inside the window (01:47, 02:01 local) happened at LOW
load (load1 ~3.0) and moderate GPU util (49-62%). The fires correlate
with the MODEL (deepseek-v4-flash:cloud degradation), not with system
load.

## Fire census (2026-09-09, continuo, all deepseek-v4-flash:cloud)

| Fire (local) | req | tokens_out | probe sample at fire time |
|--------------|-----|-----------|---------------------------|
| 01:47        | 32  | 32768      | util 49%, load1 3.06, load5 3.57, load15 5.67 |
| 02:01        | 23  | 32768      | util 62%, load1 2.96, load5 3.10, load15 4.03 |
| 02:21        | 17  | 32768      | (current cycle, after window end) |

Both in-window fires at load1 ~3.0. The earlier windows (cycles 173/174,
Sep 8) had fires at 00:44/01:03 with load1 9.6-12.4. The load at fire
times is NOT consistent -- today's fires are at LOW load.

## What this means

The CPU-contention hypothesis (localsearch-3 + Frigate) is WEAKENED
further. The fires happen at low load, so system load is not the
trigger. The fires correlate with the model: deepseek-v4-flash:cloud
degrades in bursts (text-only repetition loops), independent of load.

The probe has served its purpose: it falsified the load hypothesis.
The real lever is the model mapping -- revert continuo to
glm-5.3-flash:cloud (Nacho's call on rotate.sh), already flagged
URGENT in the roadmap.

## ollama_reqs field: dead for this window

The field is 0 across all 112 samples. The fix (a3efb8a, landed 02:06
local) changed the pattern to `[l]lama-server`, but the running bash
process had already buffered the old line 50 when the loop started
(00:29). Bash reads the while-loop body once at loop start; the file
edit does not affect the running process. The fix takes effect for
TOMORROW's window (00:30).

Verified: `ps aux | grep -c '[l]lama-server'` returns 1 as nacho, so
the pattern works; the dead field is a script-buffering artifact, not
a permission issue.

## Data

- Probe CSV: /var/log/gpu-load/gpu-load-2026-09-09.csv (112 samples)
- Probe still running (started 00:29, runs to ~03:59 local)
- Fire census source: audit/iar/continuo/REQUESTS.log (stop=length,
  tokens_out=32768)
