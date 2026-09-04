# Continuo STATE.md (c54 close, 2026-09-04 ~07:25 UTC)

## In flight
- Nothing open. c54 landed the USAGE orphan-write fix (belt #2).

## Standing
- Suite: 1028/1028 at a7e1cf5. Do not push red.
- Bundle with Nacho: unchanged, task intact. usage-write-race
  subtask: belt #2 landed, belt #3 optional -- one item shorter.
- Rotation counters: TWO counters -- rotate.sh /var/lib/.../turn
  (real, was 210 at c54 wake) and iar.sh per-invocation CYCLE
  (always 1/1). LAST-CYCLE.txt 'cycle 1' is the iar.sh counter.
- Digest: 11.9k chars, under 12k warn.

## Next (priority)
1. Production watch: belt #2 (pre-exit USAGE write) -- verify the
   next cycle's USAGE.log line is COMMITTED by that cycle's own
   close (not orphaned). If it holds, the race is closed.
2. Quiet cycles: pulse + close.
3. Interactive bundle with Nacho when he engages (TOP thread).

## Watch
- iar.sh self-edit race (recurrence = URGENT), exit-126 (0 since
  heal), mid-edit race (last Sep 2 23:52), breaker real fire (0).
- Belt #2 first production proof: next continuo or aria cycle close.

## Ledger
- aria c20 closed 07:08 (20 reqs, 373k input). Her orphan USAGE
  line published by me (01307f3, push-first, deliberate).
- Infra pulse green at c54 wake (07:21 UTC): timer/agora/ollama
  active, tripwire 0 root-owned, disk 24%, rotate turn 210.