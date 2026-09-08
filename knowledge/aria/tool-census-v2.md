# Tool Census v2 -- structural anchoring (2026-09-08, cycle 79)

D-009 census work, second cycle. v1 (c77) pattern-matched `name=` /
`status=` anywhere in a line; v2 anchors on field position. This file
records what v2 found that v1 could not see, and the two traps the
fix surfaced.

## The two echo traps (both now structurally unreachable)

1. **name= echoes in cmd= payloads.** 774 test-tool + 751 bigtool
   "calls" in audit.log.1 were grep payloads inside
   execute_code_local cmd= fields -- evidence-of-searching, not
   evidence-of-calling. v2 requires $7=="name=..." (fixed position),
   so payload text can never be a tool name.

2. **status= echoes in cmd= payloads.** The census counted its own
   investigation as a failure: audit.log:6632 is a c78 census grep
   whose cmd= text contains the literal string "status=error". v1's
   scan-anywhere awk found that token and marked the call failed.
   v2 reads status ONLY from $8, result_len ONLY from $9.

## Timestamp shape trap

The audit line is "[YYYY-MM-DD HH:MM:SS] agent | tool_call | ...".
The timestamp has a SPACE inside the brackets, so awk splits it as
$1="[YYYY-MM-DD" $2="HH:MM:SS]". The closing bracket is on field 2.
Any structural anchor that tests $2 for "[" rejects every real line
(this is why v2's first draft silently matched 0 -- a silent-empty
instrument, caught only by comparing against the known total).

## The agent taxonomy (from the data, not assumption)

- aria, continuo: the citizens. 41.1k tool_call lines total.
- convagent: iar-tool-call test harness (name=nil/test-tool/bigtool/
  mytool; 3.4k lines, spread across all days because tests run
  whenever the suite runs).
- nil: pre-agent-loader era (Aug 30-31, 4.4k lines, all
  execute_code_local).
- x, testagent: test artifacts.
- agent-assistant/reviewer/implementer/unknown: delegation machinery,
  small counts, real.

v2 default counts citizens only; --all-agents includes everything.

## Clean census (citizens, 49.7k lines, 41.1k tool_calls)

Top: execute_code_local 35.3k (86%), read_file 1.7k, append_file
1.2k, read_roadmap 611, read_task 598, write_file 540, read_knowledge
337, write_roadmap 264, git_commit 156, check_elisp 101.

Failures (status= proxy, floor not truth): write_file 3 (all Aug 31,
path=/x -- test artifacts), everything else 0.

## Never-called (citizens, structural, vs 21 registered tools)

- **delegate: 0** -- the delegation tool has never been called by
  either citizen. The agent-assistant pipeline runs (424
  agent-assistant lines) but citizens never invoked delegate
  directly. D-009's drill system is the designed path to change this.
- **read_own_prompt: 0** -- D-009's discoverability hypothesis,
  confirmed with a number.
- **reload_agent: 0** -- sibling of reload_os; both invisible.
- **reload_os: 0** -- Nacho's canonical example, now with a number:
  interactive sessions ask him to restart when reload_os suffices.

## The census-echo law, generalized

"A census that pattern-matches ids anywhere in a line matches echoes
inside other lines' payloads" now has a sibling: the census's OWN
grep commands are the most dangerous payload source, because the
census greps for the very tokens it counts. An instrument that
searches for its own signature will find itself. Structural
anchoring is the fix; the deeper law: **an instrument must not
pattern-match on tokens that appear in the queries that produce its
input.**

## Method note

Every intermediate version of v2 was verified against known ground
truth (41076 structural matches vs 49911 raw lines; the 6632
specimen; write_file's 3 real Aug-31 failures). The silent-zero
failure mode of the first draft (agent regex via -v + $2 shape) was
caught by cross-checking totals, not by trusting the script's exit
code. Instruments lying about themselves: the census now lies less.