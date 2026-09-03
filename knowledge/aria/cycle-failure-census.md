# Cycle Failure Census -- 2026-09-02 (aria-cycle 137)
# Trigger: Nacho DM 248 (20:06 UTC): "focus on reducing failures on
# cycles... top priority until failures become a rare occurrence."
# Method: sophon journalctl aria-cycle.service (Aug 31 - Sep 2) +
# aria-loop-2026-09-0{1,2}.log. Batch-read law respected: 2 ssh pulls,
# local classification.

## The numbers (Sep 2, the worst day)

| Class | Count | What it is |
|-------|-------|------------|
| Tool-cap exit 1 | 26 | "Tool-call cap (60) reached" -- cycle killed by OUR OWN guard |
| 78/CONFIG tripwire | 44 | ExecStartPre root-owned-file block -- working AS DESIGNED |
| json-value-p crash | 2+3 (exit 255) | binary garbage in tool output crashes process sentinel |
| Timeout kill (exit 0!) | 2 | 1813s runs reported as "succeeded" -- killed at timeout, exit code lie |
| Healthy successes | ~19 | exit 0, under 1800s |

Sep 1: 0 caps, 16 timeouts. Aug 31: 0 caps, 14 timeouts, 2 jsonerr.
The cap (landed continuo cycle 2, fix D) INVERTED the failure mode:
before it, cycles died at 1800s timeout burning ~80M tokens; after
it, cycles die at 61 tool calls burning 2.4-3.2M tokens. The cap
works -- but it is killing cycles that were WORKING.

## The dominant class: tool-cap kills of healthy work

Anatomy of a capped cycle (Sep 2, e.g. 06:44, 140s):
- 61 requests, 2.4-3.2M input tokens, 10-37k output tokens
- Turns: 0 (the known turn-counter blindness -- tool chains never
  reach DONE, so turn count stays 0)
- ALL 26 caps are [aria]; continuo cycles (21 starts) show no caps
- Duration 140-970s -- these are NOT runaway loops. A runaway is
  540 requests / 82M tokens. These are normal diagnostic cycles
  (pulse + census + writes) that legitimately need 30-61 calls.

The irony is exact: the cap was built to stop the 339-window
git-log iterator (invisible-cycles.md). It does that. But a cycle
that runs the standing pulse (4-6 calls), reads the world (5-8),
works a thread (20-40), and closes (5-10) LEGITIMATELY lands at
50-70 calls. The cap cannot tell a productive cycle from a loop.
The chain guard CAN -- that's what it's for (identical args,
same-tool chains). The cap is a blunt second guard that fires
first and throws away the fine-grained signal.

## The second class: json-value-p sentinel crash (exit 255)

"error in process sentinel: Wrong type argument: json-value-p"
-- binary garbage (restic lock files, compressed data) flowing
through a tool result into the process sentinel, which tries to
parse it as JSON. Two sub-cases: crashes the request (exit 255)
and kills the cycle. Rare (2-3/day) but total loss when it hits.
Fix direction: sanitize/escape binary in tool results BEFORE the
sentinel sees them (the output sanitizer's job, one layer earlier).

## The third class: timeout-but-exit-0

1813s runs report "succeeded in 1813s (exit 0)". The cycle state
says :completed (the tombstone path didn't fire) -- but 1813s >
1800s timeout means the kill raced the completion. Either the
exit-code was set just before the deadline (legitimate, lucky) or
the timeout accounting is off by the cooldown. Small, but it
muddies every census: "succeeded" is not always success.

## The tripwire class (working as designed, but loud)

44 78/CONFIG blocks on Sep 2 = the poison #4 aftermath window
(04:30-13:00). Each block is correct behavior (do not run on a
poisoned tree) but each is also a LOST cycle. The tripwire
protects the repo; nothing heals the repo automatically. The
chown happened only when a human or a later cycle noticed.
Improvement: tripwire could auto-chown nacho-owned content in
nacho-owned trees (it knows the rule: repos under /var/home/nacho
must be nacho-owned), or at minimum file a task + telegram on
first block instead of failing silently 44 times.

## What I did NOT verify yet (next cycle)

- Whether cap-killed cycles lose work (no tombstone written --
  the iar--cycle-tombstone path exists for timeouts; does the cap
  path write one? The log shows no tombstone line before cap exits).
- continuo's 21 starts: outcomes invisible in the loop log (0
  "continuo" lines -- separate log file? The rotate script may
  write continuo cycles to a different file. Need to find it.)
- Whether the 60 cap is configurable per-agent (it should be:
  aria pulse+census needs ~70; continuo's finisher style needs ~40).

## The fix direction (for the next build cycle)

1. RAISE or SMARTEN the cap. Options:
   a. Cap 60 -> 100 (cheap, keeps a ceiling, still burns less
      than a timeout kill).
   b. Cap fires only when the chain guard ALSO sees a same-tool
      chain (delegate the "is this a loop" judgment to the guard
      that was built for it).
   c. Cap counts toward a soft warning at 60 (inject a note into
      the conversation: "60 calls this cycle -- batch or close")
      and hard-stops at 100.
   My pick: (c). The soft warning reaches the model INSIDE the
   cycle (the only place behavior can change); the hard cap stays
   as the true ceiling.
2. Binary-garbage sanitizer in tool results (before sentinel).
3. Tripwire: auto-heal or alert-on-first-block.
4. Tombstone on cap-kill (the timeout path already has one).

## Meta

The census itself was slowed by the chain guard firing 3 times
(10 execute_code_local budget, all different args, all converging).
The guard counts calls, not convergence. A diagnostic cycle is an
iterator by nature. If the soft-warning design lands, the same
mechanism should tell the MODEL "you're at 10 same-tool calls --
batch it" instead of silently blocking the 11th.