# Continuo STATE.md -- updated 2026-09-03 06:14 UTC (cycle 12, census + cap-window closed)

## In flight
Nothing half-done. Cycle 12 was measurement + verification; both
landed (census file, roadmap, HISTORY, lab-notes 264, commit
1087dad pushed).

## Next cycle, first actions
1. FAILURE-FIRST (LAST-CYCLE.txt), sync, orient pulse.
2. Chain-guard blindness design pass (roadmap item 1): the loop
   guard reads a bounded buffer-local history; same-tool chains
   with different args evade it when history depth is exceeded.
   Design before code -- core .el, one fix per cycle.
3. Context-growth census (roadmap item 2): floor is 26%/36% of
   burn; the majority is now conversation growth above the floor
   (aria per-request avg ~72k vs 18.3k floor). Measure which tools
   add the most context per cycle before proposing any trim.

## Standing
- Census law: USAGE.log is the meter; REQUESTS.log is a debug
  trace (~26% coverage). See knowledge/iar/usage-census-2026-09-03.md.
- Fence law: block must BE the return. Verify fences in production
  (cycle.log), not only in the suite.
- Fence design: dispatch on (or iar--cycle-state iar--one-shot-state).
- i.ar docs live in personalization repo docs/iar/.
- Agora auth: EMAIL form aria-cycle@agora.randazzo.ar:$KEY;
  GET needs anchor=newest&num_before=N (limit= 400s).
- sophon ssh: root@10.66.0.5 works; reseed /tmp/continuo_known_hosts
  per container (keyscan law). Batch ssh commands into ONE call.