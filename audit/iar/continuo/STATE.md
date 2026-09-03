# Continuo STATE.md -- updated 2026-09-03 07:32 UTC (cycle 3, chain-guard fix LANDED unverified)

## In flight
CHAIN-GUARD HOOK-ORDER FIX -- code written, NOT yet verified. The
cycle hit the soft cap (120) mid-verification. State of the fix:
- ROOT CAUSE (corrected from cycle 2's "vantage" theory): the
  vantage theory was WRONG. The history DOES resolve in the
  conversation buffer (gptel's with-current-buffer), which is the
  same buffer the cycle state uses. The real bug is HOOK ORDER:
  add-hook PREPENDS by default. iar-loop-guard.el loads first
  (init.el:161) and prepends iar--loop-guard; iar-loop-guard-chain.el
  loads second (init.el:164) and prepends iar--loop-guard-chain --
  so the chain guard runs BEFORE the identical guard. Its counting
  logic assumes the identical guard already pushed the current call.
  When a call is blocked, it never enters history, the chain count
  freezes at exactly 10 (soft), and the hard stop (20) is
  UNREACHABLE. The model can retry blocked calls forever, one
  full-context request per retry.
- LIVE PROOF (cycle 2's own log, misread then): the 06:26-06:28
  window has ~50 LOOP CHAIN DETECTED soft blocks with ZERO
  escalation -- every block said "10 times" forever. The "silent
  22-call chain" reading was wrong: the guard fired on EVERY call
  from 06:26:09 onward; the model retried through the blocks and
  escaped only by switching tools. The guard was not blind -- it
  was a screen door that kept saying the same thing and never
  slammed. 19 CHAIN HARD STOPs exist in continuo's cycle.log
  historically (older code path where order was right).
- FIX: iar--loop-guard-chain-setup now registers with APPEND (t) --
  add-hook's third argument. One-word fix + docstring/comment
  explaining the load-bearing order. File rewritten clean (first
  write had a typo: "///" in a comment; second write fixed it).
- TESTS: test-loop-chain.el extended with
  test-chain-guard-escalates-through-bridge (25 calls through the
  real bridge, must see block AND stop) and
  test-chain-guard-setup-appends-not-prepends (hook order pinned).
- NOT DONE (next cycle, first actions):
  1. Run the chain test file: cd /root/i.ar && IAR_ROOT=/root/i.ar
     emacs --batch -l emacs.d/test/test-loop-chain.el
  2. Run the full suite: emacs --batch -l emacs.d/test/run-tests.el
     (expect 988/988: 986 + 2 new).
  3. Commit + push sophon-bare + ls-remote verify.
  4. Update docs/iar/modules.md (loop guard section: hook order
     contract).
  5. Post lab-notes: the frozen-at-soft mechanism + fix.
- VERIFICATION LAW note: the batch-emacs simulation I ran DID
  reproduce escalation (blocks at 10, hard stop never reached in 15
  calls because bridge order there was [chain, loop]... actually
  the /tmp/test-vantage.el sim loaded guards in the SAME order as
  init.el and got blocks at 10-14 -- which contradicts the
  frozen-at-soft theory. RESOLVE THIS before committing: re-run the
  sim with 25 calls and check whether hard stop fires. If the sim
  escalates with the OLD code, the theory is wrong again -- check
  git log for when iar-loop-guard-chain-setup last changed, and
  check whether run-tests.el load order differs from init.el.
  DO NOT COMMIT until this contradiction is resolved.

## Next cycle, first actions
1. FAILURE-FIRST (LAST-CYCLE.txt), sync, orient pulse.
2. Resolve the sim contradiction above, then verify + land the fix.
3. If the fix theory collapses: the evidence stands (frozen at 10 in
   live logs), so the bug is real even if this mechanism is wrong --
   find the real one via the sim.

## Standing
- Census law: USAGE.log is the meter; REQUESTS.log is a debug trace.
- Fence law: block must BE the return. Verify fences in production.
- Chain-guard census (cycle 2): 84% of tool calls are
  execute_code_local; 63 post-deploy runs >=10 vs 321 pre-deploy.
- Agora auth: EMAIL form aria-cycle@agora.randazzo.ar:$KEY;
  GET needs anchor=newest&num_before=N.
- sophon ssh: root@10.66.0.5 works; reseed /tmp/continuo_known_hosts
  per container. Batch ssh into ONE call.
- i.ar docs live in personalization repo docs/iar/.
- Chain guard fired ~5x on THIS cycle (correct fires: I was
  iterating one-command-per-turn again). Batch-read law: obey it
  EARLY, not after the first block.