# Continuo STATE.md -- updated 2026-09-03 05:33 UTC (cycle 10, ended at tool-cap 120)

## In flight
SOFT-WARNING CAP (census option c) -- implemented, NOT committed, 1 test red:
- iar-cycle-tool-call-warn 60 in iar-agent-cycle.el; warn-once
  semantics (block one call with budget notice, call NOT lost);
  memory tools exempt; :cap-warned pre-init in BOTH state makers;
  writeback applied to the warn setf.
- KNOWN BUG (pinned by red test test-fence-cap-warns-once-at-budget):
  the warn branch's (list :block ...) return is DISCARDED -- the
  soft-cap `when` follows it and returns nil at count=warn. Fix:
  wrap both `when`s in `or` so the warn block is the return.
- Suite 985/986. Tree safe (warn inert in live runs) but red test
  is the pin -- land it first thing next cycle.

## Next cycle, first actions
1. FAILURE-FIRST (LAST-CYCLE.txt), sync, orient pulse.
2. Fix the warn return-value bug (or-wrap), suite 986/986, commit,
   push sophon-bare, ls-remote verify.
3. Docs: modules.md cycle.el row + agents.md fence paragraph.
4. Lab-notes post (owed cycle 10 -- cap fired before the post).
5. Memory pass: DIGEST.md still says 981 tests + old thread list.

## Standing
- Fence design: dispatch on (or iar--cycle-state iar--one-shot-state).
- Fence law (cycle 10): a fence whose return value is discarded is
  a fence that never fired. Block must BE the return.
- i.ar docs live in personalization repo docs/iar/.
- Agora auth: EMAIL form aria-cycle@agora.randazzo.ar:$KEY;
  GET needs anchor=newest&num_before=N (limit= 400s).
- sophon ssh: root@10.66.0.5 works; reseed known_hosts per container.
- One tool call per turn. Batch-read law. Chain guard fires at 10
  same-tool calls; the tool-cap fires at 120 total. Debug cycles
  (grep-iterating a test failure) hit BOTH -- batch or die.

## World
Services green (aria-cycle.timer, agora-agent, ollama), disk 24%,
tripwire 0. Aria cycle 4 done (DIGEST diet, law 24). Nacho DM 248:
cycle-failure reduction is top priority -- failure-first protocol
verified live in iar.sh (write_last_cycle, reset_worktree, hourly
digest). Token census raw (pre-dedupe): aria ~230M prompt tok over
3182 reqs since Sep 2 09:24; continuo ~54.6M over 1315.