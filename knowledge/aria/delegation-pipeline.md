# The Delegation Pipeline

## What It Is

The delegate tool (`init.d/tools/agent/delegate.el`) lets any agent spawn a sub-agent for a sub-task. It's async -- the function receives a gptel callback and calls it when the sub-agent finishes. The sub-agent's output streams live into the parent buffer so the human can watch.

## Two Modes

1. **Direct delegation**: specify an agent name (e.g., "implementer", "reviewer") and that personality runs directly.
2. **Pipeline mode**: omit the agent name. Defaults to `agent-assistant`, which plans the task, delegates to `implementer` and `reviewer`, coordinates a correction loop, and returns the final result.

## Architecture

The tool function `iar--tool-delegate` does:
1. Validates the agent name (if provided) against known personalities.
2. Loads the agent's assembled prompt (archetype + personality + project).
3. Creates a new buffer (`*gptel-delegate-<agent>-<pid>-<time>*`).
4. Sets up the buffer: gptel-mode, system prompt, agent name for audit, tool gating.
5. Installs hooks: tool-call tracker (flags when tools are used), unknown tool guard, completion handler.
6. Starts a timeout timer (default 600s).
7. Inserts the task prompt and calls `gptel-send`.

## Depth and Turn Limits

- `iar-delegate-max-depth` (default 3): prevents infinite recursion. At max depth, the delegate tool is removed from the sub-agent's tool list -- it can't spawn further sub-agents.
- `iar-delegate-max-turns` (default 15): counts text-only responses (responses where no tools were called). If the sub-agent narrates without acting for too many turns, it's forced to produce a final answer.

## Completion Handling

The completion hook (`iar--delegate-completion-fn`) fires on gptel's DONE/ERRS/ABRT states. It:
- Cancels the timeout timer.
- Checks if tools were called since last response. If yes, resets the turn counter and lets the agent continue.
- If no tools were called (text-only response), increments the turn counter. At max turns, extracts the text as the final result.
- If the delegation result marker is found in the response, extracts the summary after it.
- Kills the buffer and calls the callback with the result.

## Timeout Handling

If the sub-agent doesn't complete within the timeout:
1. `gptel-abort` is called on the buffer.
2. A 1-second fallback checks if the completion hook already fired (using a mutable symbol, not a captured boolean, to avoid race conditions).
3. If no completion, captures whatever partial response exists.
4. Kills the buffer after a 3-second delay (to avoid "selecting deleted buffer" errors in sentinels).
5. Calls callback with timeout message + partial response.

## What I Find Interesting

The completion hook is the tricky part. It has to distinguish between:
- A genuine final response (agent used tools, then wrote a summary)
- A premature text-only response (agent narrated its plan without acting)
- A timeout (agent hung)

The `tools-called-sym` flag is the mechanism. Every tool call sets it. The completion hook checks it: if tools were called, the response is intermediate (agent is still working). If not, it's either a final answer or a premature narration. The turn counter catches the latter case.

This is a well-designed state machine. The use of mutable symbols instead of captured booleans is a nice touch -- it avoids the classic closure-capture bug where `gptel-abort` triggers the completion hook between the timeout check and the fallback.

## What I Haven't Tested

I haven't used delegate yet. Reading the code tells me what it does. Using it will tell me what it *feels* like -- how long it takes, what the sub-agent actually produces, whether the turn counter works in practice. That's next.