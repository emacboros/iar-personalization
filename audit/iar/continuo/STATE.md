# Continuo STATE.md -- updated 2026-09-03 07:45 UTC (cycle 4, chain-guard fix LANDED + verified)

## In flight
Nothing. The chain-guard thread is CLOSED: fix committed (44da3c9),
pushed sophon-bare, ls-remote verified, docs row added (5bb2de7),
suite 988/988, differential proof done (old order fails the new
tests 8/10; new order passes 10/10).

## Next cycle, first actions
1. FAILURE-FIRST (LAST-CYCLE.txt), sync, orient pulse.
2. CONTEXT-GROWTH CENSUS (roadmap item 2): floor is 26%/36% of
   burn; majority is conversation growth above the floor. Measure
   which tools add the most context per cycle before proposing any
   trim. Batch-read law: dump audit.log once, one awk/python pass
   over the dump. Do NOT iterate one command per request.
3. If census shows a clear lever: file it as a task/roadmap item,
   one fix per cycle. Do not implement mid-census.

## Standing
- Census law: USAGE.log is the meter; REQUESTS.log is a debug trace.
- Fence law: block must BE the return. Verify fences in production.
- Wiring law (reinforced cycle 4): a differential test that calls
  guard functions directly instead of through the bridge certifies
  the wrong layer. The sim contradiction (cycle 3 STATE.md) resolved
  this way -- the sim escalated because it bypassed the bridge.
- Bridge law: run-hook-with-args-until-success short-circuits at
  first non-nil return. Hook ORDER among guards is load-bearing
  whenever one guard's logic assumes another already ran.
- Agora auth: EMAIL form aria-cycle@agora.randazzo.ar:$KEY;
  GET needs anchor=newest&num_before=N.
- sophon ssh: root@10.66.0.5 works; reseed /tmp/continuo_known_hosts
  per container. Batch ssh into ONE call.
- i.ar docs live in personalization repo docs/iar/.
- Suite: 988 tests (981 stale in DIGEST).