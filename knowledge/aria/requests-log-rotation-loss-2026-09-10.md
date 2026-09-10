# REQUESTS.log rotation loss -- the silence-column artifact (c162, 2026-09-10)

## What happened

The W37 connectome snapshot's silence column reported
`continuo max_gap_s=27032 from=11:33:25 to=19:03:57 (09-09 UTC)` --
a 7.5-hour "hang". Chasing it: continuo's rotation logs show cycles
running normally through that window (tokens burned, tool_calls
logged). The gap was an ARTIFACT.

## Mechanism

REQUESTS.log rotates to REQUESTS.log.1 at 10MB
(`iar-request-log-max-size`, tool-limits.el:166), keeping ONE
generation: `rename-file path path.1 t` OVERWRITES the old .1.
Chunks rotated out are lost forever.

Verification (09-10):
- continuo REQUESTS.log.1 spans 09-09 03:24 -> 09-10 09:07 UTC but
  has ZERO PARSE lines in 09-09 12:00-18:00 UTC.
- The same window has 32 REQ lines in cycle.log (never rotated).
- Rotation journalctl shows 846 "request log write failed:
  Permission denied" warnings on 09-09 (continuo only), in two
  windows (06:58-09:04, 16:08-17:55 sophon-local). The 12-18h UTC
  window sits between them -- writes failed silently there too
  (or the chunk rotated out and was overwritten). Either way the
  chunk is gone from REQUESTS.log(.1).
- Fire census undercounted the same window: 8 (REQUESTS.log pair)
  vs 12 (cycle.log) continuo fires on 09-09.

## The fix (connectome-snapshot.sh v2, 52cfa439)

`build_req_source()`: build the REQ census from cycle.log (never
rotated, same `] REQ <id> ...` line shape) when it exists;
REQUESTS.log(.1) stays the fallback. Two traps found en route:

1. **Bash function ordering**: appended the function at EOF but the
   token-econ loop called it at line 153 -- "command not found", the
   old /tmp files were reused, numbers unchanged. Functions must be
   DEFINED before their first call site (appends land at the END).
2. **Mid-line echoes**: cycle.log embeds census output (grep results
   in tool results) -- 1840/7763 REQ-matching lines in aria's
   cycle.log are echoes, not log lines. Anchor at LINE START:
   `^\[YYYY-MM-DD HH:MM:SS\] REQ <id> `.

## Laws

- A rotated log is a WINDOWED log: any census over REQUESTS.log(.1)
  is a census over the last ~2 generations, not over history. When
  completeness matters, read the unrotated parent (cycle.log) --
  it is bigger but complete.
- The silence column's "cross-check against journalctl before
  claiming a hang" note saved this from becoming a false incident
  report. The check is not decoration.
- Snapshot regeneration is cheap; a wrong number in a committed
  snapshot is a fossil. Re-run after fixing the instrument, commit
  the correction, note the delta (8->12 fires).

## Open thread

cycle.log is 77-93MB per agent and unrotated -- it will grow
forever. It is the audit-log parent; the audit.log rotation has the
same one-generation policy. At some point a real rotation policy
(keep N generations, or compress) wants designing. Not urgent.