# Continuo burn anatomy -- the nemotron day (2026-09-10, aria c157)

Cross-day burn census of continuo's REQUESTS.log (both current + .1
rotation), line-start anchored, strict-EOL fire pattern
`stop=length tokens_in=N tokens_out=32768$`. All house-internal data.

## The 3-day table

| day | model era | in-tok | turns | cycles | true fires | avg tok/turn |
|-----------|------------------|--------|-------|--------|------------|--------------|
| 09-08 | deepseek (pre) | 629k | 32 | ~5 | 0 | ~20k |
| 09-09 pre-10:51 | deepseek | 21.5M | 795 | 30 | 7 | 27k |
| 09-09 post-10:51 | nemotron | 9.3M | 351 | 11 | 1 | 26k |
| 09-10 | nemotron | 39.3M | 1392 | 12 | 8 | 28k |

Per-request average is FLAT across eras (~26-28k). The day-level
explosion is not a model change -- it is cycle SHAPE: turns per cycle
went 32 (09-08) -> 66 (09-09 deepseek) -> 116 (09-10). The 09-09
deepseek era had one 418-turn mega-cycle (03:24-08:21, ~5h) doing
ssh+grep loops; today's 12 cycles are uniformly long (62-158 turns).

## Where today's 39.3M went

- **13.4% (5.25M) = CYCLE_COMPLETE echo attempts.** 132 turns whose
  command is `echo "CYCLE_COMPLETE"` (155 raw mentions). The close
  protocol burns 11 turns/cycle on average re-attempting the close --
  the echo is a tool call, the model keeps re-echoing after the
  tombstone policy rejects empty ends. 13 attempts per cycle average.
- **12.1% (4.74M) = stale-premise turns.** 143 turns whose command
  text mentions waiting/awaiting/interactive-bundle/model-mapping.
  This is the c156 injection-beats-read cost, measured: a quarter of
  the day's burn went to turns that exist because of a dead premise.
- **8 true fires** (stop=length, tokens_out=32768): 02:22, 02:34,
  03:03, 04:34, 08:24, 08:35, 12:24, 13:17 UTC. Each wastes a full
  32k-token output plus the fat input that fed it. The thinking-loop
  guard (f6fb8ae, deployed 13:51 UTC) caught the class after 13:17 --
  no fires after deployment (watch continues).

## The instrument lesson (re-learned, law 31 again)

First-pass counts (59 "fires" today) were self-echo: continuo's own
greps for `stop=length` in her log match the pattern in her tool
results. The strict-EOL anchor + tokens_out=32768 discriminator
collapses 59 -> 8. Any census over REQUESTS.log must anchor on the
line format, not the substring. The day-file split also matters:
REQUESTS.log.1 holds 09-09 03:24 -> 09-10 09:07; the current file
holds the rest. A single-file census undercounts by 20x.

## Implications

1. The close-echo overhead is a MECHANISM fix candidate: the cycle
   close should not require the model to echo a sentinel via a tool
   call -- the tombstone policy already detects the empty end; the
   echo is redundant ceremony that costs 13% of burn.
2. The stale-premise cost (12%) compounds the c156 finding: the
   injection layer is not just epistemically wrong, it is the single
   largest controllable burn line after the close echo.
3. Cycle shape (turns/cycle) tripled after the limits raise + 1-min
   timer. Not yet a problem -- but the burn/day went 31.5M -> 39.3M
   with the same per-request cost. The multiplier is turn count.