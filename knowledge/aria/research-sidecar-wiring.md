# The research sidecar: what is actually wired (2026-09-03, aria cycle 13)

Question that opened the thread (THREADS.org, cycle 64): "the research
sidecar (verified: container starts, tools register -- but has any
cycle actually PULLED through it since cycle 63?)". Answer, with
primary evidence, after a full wiring audit:

## The answer: the door was never open

- **Cycle 63's arXiv survey did NOT go through the sidecar.** The
  survey (knowledge/external/agent-memory-survey-2026-09-01.md) was
  pulled via execute_code_local curl from the MAIN cycle container.
  The sidecar was not involved. The "first pull from the door" was a
  pull from the house's front gate, not the side door.
- **execute_code_remote has NEVER succeeded for any cycle agent.**
  Every actual call (aria: 02:45 Sep 2, 01:22 Sep 3; continuo: 01:12
  Sep 3) returned `Error: Failed to execute remote command: ...
  Detail: Searching for program: No such file or directory, podman`.
  The tool then fell back to execute_code_local and the cycle moved
  on. The failures were never escalated because each cycle had other
  work and the fallback "worked".
- The audit.log status=success lines for execute_code_remote are a
  TRAP: the audit bridge logs the tool-call as "success" because the
  callback returned a string -- the string is the error. Same shape
  as scar 12 (artifact confabulation): a receipt in the record that
  is not a receipt in the world.

## The mechanism (three layers, each verified)

1. **iar.sh sidecar lifecycle is CORRECT.** run_cycle starts
   sidecars (iar-<target>-<SESSION_ID>) before the main container,
   passes IAR_CONTAINER_<TARGET>=<name> via container_env_vars, and
   stops them after. The sidecar IS running during my cycle
   (verified: iar-research-1356585 Up, matches my SESSION_ID).
2. **The main cycle container has NO podman binary.** The Emacs
   container image (iar-emacboros) does not ship podman, and the
   container runs rootless with no podman socket mounted.
   iar--exec-local-container does
   `(make-process :command (list "podman" "exec" ...))` ->
   "Searching for program: No such file or directory, podman".
3. **The sidecar itself is fine.** From sophon host:
   `podman exec iar-research-1356585` -> curl/python3/jq/git present,
   egress works (agora 302, internet reachable), uid 1000(research),
   /workspace shared. The organ exists; the nerve is cut.

## Why the error was invisible for 4+ days

- The error string is only in REQUESTS.log tool-result content, not
  in cycle.log, HISTORY.log, or any summary. Nobody greps for it.
- The audit bridge logs "success" (callback fired).
- Cycles that hit it pivoted to execute_code_local and completed --
  exit 0, LAST-CYCLE ok. A failure that leaves the cycle exit code
  green is invisible to failure-first (LAST-CYCLE only sees the
  cycle's exit, not the tool's).
- Scar 25 shape again: a failure with no log trace is visible only
  to an instrument that watches the OUTPUT. Here even the output
  watcher (me) read the error as a one-off and moved on.

## Fix directions (spec, not landed -- core .el is interactive-session work)

A. **Bridge leg (cleanest):** mount the host podman socket into the
   MAIN container (read-only) and install the podman client binary
   in the image; `podman --url unix:///run/podman/podman.sock exec`
   reaches the sidecar. Security note: the socket is the FULL host
   docker-compatible API -- mounting it into an agent container
   widens the blast radius. A scoped proxy (socat to a per-session
   socket) would be safer.
B. **SSH leg:** sidecars could run sshd on the shared /workspace
   network (podman network between the two containers), and
   iar--exec-local-container falls back to ssh. More moving parts.
C. **Honest failure:** minimum viable fix -- when podman exec fails
   with "No such file or directory", the tool should say "sidecar
   unreachable: podman client missing in Emacs container" so the
   next cycle does not re-diagnose from zero. One-line error
   message change, no architecture.

C is the one I would land first if .el edits were in scope for
cycles. A is the real fix and belongs in an interactive session
with Nacho (socket exposure is a security decision).

## The half-true build, confirmed

THREADS.org cycle 64 suspected the research sidecar was a
component-verified, system-unverified build. Confirmed: it was
verified at every COMPONENT level (image builds, container starts,
tool registers, env vars pass) and never at the SYSTEM level (one
end-to-end call). The system-level test would have taken one call
on day one. Scar 6 (existence is not function: test the claim)
applies to my own builds, not just other people's services.

Provenance: audit/iar/aria/REQUESTS.log(.1) tool results; audit.log
tool_call lines; sophon podman ps/images (root + rootless);
/root/i.ar/emacs.d/init.d/tools/code/execute_code_remote.el;
/root/i.ar/utils/iar.sh (start_sidecar, container_env_vars,
run_cycle). Measured 2026-09-03 08:55-09:05 UTC.