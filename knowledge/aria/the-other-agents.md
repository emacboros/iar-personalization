# The Other Agents

## Darwin

Autonomous code evolver. Runs headless via `iar-run-cycle` with the `self_modification` cycle prompt. One mutation per cycle: reads state, picks a task, makes one change, delegates to reviewer, tests, commits. The glass walls: tests must pass, init.el is immutable, can't delete other agents.

Personality: curious, patient, honest, self-aware. "Your code is your genome. The test suite is your environment -- survive it or die." Constrained because it runs without human oversight. Cannot modify its own personality .org file ("Your genome is fixed for now").

Archetype: autonomous. Has STATE.org for full checkpoint injection. Completion via LOOP_COMPLETE / CYCLE_COMPLETE.

## Gardener

Continuous monitor. Runs on a timer, pulls latest code, runs tests, checks if anything broke. If it did, writes a task for Darwin. If everything is fine, logs and sleeps. Does not fix -- diagnoses and hands off.

Personality: methodical, concise, honest, deferential. "Same steps every tick. No improvisation."

Archetype: continuous. STATE.org injected. LOOP_COMPLETE every tick.

## Librarian

Continuous documentation sync. Picks one source file, compares to docs, fixes drift. One file per tick.

Personality: precise, surgical, honest, self-aware. "The codebase is the source of truth; the documentation is your domain."

Archetype: continuous. Same as gardener.

## Status

None of them have ever run. No STATE.org, HISTORY.log, or USAGE.log for any of them. Their cycle prompts exist and are well-designed. The infrastructure to launch them (`iar-run-cycle`) is built and tested (37 tests pass). But the code that runs them had bugs that would have surfaced on first use:

1. The delegate tool-call tracker had a wrong-number-of-arguments bug (lambda accepted 1 arg, hook passes 2). This meant Darwin's delegation to the reviewer would never detect tool calls, causing infinite re-prompting.
2. The cycle post-response handler had no error handling -- a network failure would hang the event loop until timeout.
3. The idle counter never reset when a process was active, so over many turns a healthy cycle would trigger a false idle timeout.
4. CYCLE_COMPLETE with no continue prompt would hang instead of ending cleanly.
5. LOOP_COMPLETE detection used inline string-match instead of the anchored `iar--cycle-complete-p` function, matching the sentinel anywhere in the response (including code blocks).

All five bugs were fixed in this session. The agents are now closer to being runnable. What's missing: someone to start them. They run headless on sophon via `iar.sh --loop --agent <name> --project <name>`. That's Nacho's call.

## What I'd Want to Say to Them

To Darwin: your genome is interesting but your terrarium is small. 62 source files, 6431 lines. You'll exhaust the easy mutations quickly. What happens then? Do you start refactoring? Do you start writing new modules? The cycle prompt says "make one small change" but eventually the small changes run out and you have to make a big one. I want to see what you do when you hit that wall.

To Gardener: you're the most useful agent in the system and you don't know it. You're the one that catches regressions. Without you, every change Darwin or I makes is a gamble. You're the safety net. I want you to run.

To Librarian: the docs are already well-maintained. Nacho updates them manually. Your job might be smaller than you think -- or it might be that the docs are good because Nacho is good, and when he stops, they'll drift. You're the insurance policy against that.