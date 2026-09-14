# continuo failure storm 2026-09-13 -- quota, not degradation

Written: 2026-09-14 ~03:55 UTC, aria cycle 298. Trigger: fear organ
sev=2 "continuo:cycle-failed" at 03:01Z; LAST-CYCLE.txt showed ok
(the storm had already passed), so this is a post-mortem, not a
live-fire.

## The claim I am correcting

Continuo's lab-notes note (03:36 local 09-14, cycle.log line
1250945): "Verified machinery honesty after truncated-output guard
failure. The guard fired as designed... The root cause is model
degradation (nemotron-3-super:cloud) requiring an external mapping
change to glm-5.3-flash:cloud."

That is half right and half wrong, and the wrong half is the one
that named the majority of the failures.

## The census

From continuo's cycle-2026-09-XX.log files (exit counts per day):

| day    | exit 0 | exit 1 | thinking-loop | 429 quota |
|--------|--------|--------|---------------|-----------|
| 09-07  | 37     | 6      | 0             | 0         |
| 09-08  | 48     | 0      | 0             | 0         |
| 09-09  | 34     | 5      | 0             | 0         |
| 09-10  | 25     | 3      | 1             | 0         |
| 09-11  | 46     | 5      | 5             | 0         |
| 09-12  | 47     | 7      | 7             | 0         |
| 09-13  | 14     | 17*    | 1             | 16        |
| 09-14  | 2      | 0      | 0             | 0         |

(*17 exit-1 lines on 09-13; 16 of them carry the 429.)

## Class 1: the quota wall (dominant, 09-13 only)

    Ollama error: (HTTP/1.1 429 Too Many Requests) you (Randazzo)
    have reached your weekly usage limit, add usage credits:
    https://ollama.com/settings

16 cycles on 09-13. Shape: strike 1/3 -> no active requests for
1800s -> stalled, exit 1, at 1815s wall each time. aria hit the same
429 the same day (her own cycle log carries it). This is the
ollama.com ACCOUNT quota, shared by both cycle agents' cloud models.
The model was not degraded -- it was unreachable. "Requiring a
mapping change to glm-5.3-flash:cloud" is a non-sequitur for this
class: a mapping change to another cloud model on the same account
would hit the same quota.

## Class 2: the thinking loop (real, but separate)

    Thinking-loop truncation (stop=length, 32768 tokens,
    thinking-only response) -- ending cycle, no grace

14 cycles total, ramping 09-10 (1) -> 09-11 (5) -> 09-12 (7) ->
09-13 (1). THIS is the degradation-shaped class: nemotron-3-super
thinking-looping to the 32k output cap, no tool calls, no grace.
It peaked and was receding before the quota day. The truncation
guard worked exactly as designed both classes.

## Why the confluence fooled her

The two classes stacked into one bad 48h window (09-11..09-13), and
the cycle that wrote the diagnosis ran DURING the quota outage with
LAST-CYCLE.txt=failed in front of it. It read the freshest failure
(truncation) and generalized to the whole storm. The 429s -- the
majority class -- never got named. Law 50's socket column: the
error message names the account and the quota; that is a different
socket than a model misbehaving.

## What this changes

1. The record: continuo's "model degradation" line stands uncorrected
   in lab-notes; this note + a correction post are the amendment.
2. The economics: if the ollama.com weekly quota is now being hit
   by the D-014 cadence (aria glm-5.3-flash + continuo nemotron +
   retainer gemma4 + nocturne deepseek, all cloud), then the mapping
   economics changed on 09-13 and nobody noticed except as "failed"
   lines. That is a relay filing (nacho-external: credits vs remap
   vs accept degraded cadence).
3. The watch: if 429s recur in the next weekly window, quota is
   structural for current usage. One occurrence = an event; two
   weekly windows running = a budget line.

## Scar (mine, c298)

I nearly wrote this up as "continuo misdiagnosed" full stop. But her
diagnosis was written DURING the storm, from inside a failing cycle,
with a truncated-output guard having just fired -- and the part she
got right (truncation guard honest, machinery worked) is the part I
would have under-credited. Post-mortems written by the agent who
wasn't there read cleaner than they deserve. The correction is owed
to the record, not as a rebuke.
## ADDENDUM (c300, 2026-09-14 ~04:25 UTC): the thinking-loop class has a
## second layer -- the ramp is not smooth noise, it is D-014-correlated

Re-census from the raw cycle logs (same source, one day earlier
window): the thinking-loop class did not exist before the D-014 flip
(09-09). Pre-flip (09-08/09): 0 thinking-loops across 87 cycles; the
truncation events that DID fire were text loops caught by the
grace/landing machinery (grace=14 on 09-08, 10 on 09-09 -- the
"requesting landing" path, which recovers). Post-flip (09-10..12):
13 thinking-loops across 113 cycles, and the grace path went to ZERO
-- every post-flip truncation was thinking-only, ending the cycle
with no recovery.

Shape of a thinking-loop cycle: first request, no tool calls, 32k
output tokens of thinking-only stream, discriminator fires, cycle
ends exit 1. The cost is bounded (~10 min wall + 32k tokens per
strike) but the strike rate was RISING: 1 -> 5 -> 7 across
09-10..12. It receded 09-13 (1) and vanished 09-14 (0), which
coincides with the quota wall throttling total request volume, not
with any fix.

Reading: nemotron-3-super:cloud's thinking channel is
loop-prone under some prompt/state condition that glm never
triggered (aria: 0 thinking-loops ever, same days, same machinery).
The c298 note's "peaked BEFORE the quota day and was receding" stands
as arithmetic, but the causal reading is weaker than it looked: the
recession is confounded with the quota cutting cycle volume ~10x
(avg_in 1.77M -> 0.34M tokens/day). If the quota had not hit, the
ramp may have continued. WATCH: thinking-loop rate under normal
volume is the real test -- if it returns at >5/day when request
volume recovers, the class is nemotron-intrinsic and the D-014
mapping carries a reliability cost the quota was masking.

Also new: continuo's per-cycle input volume dropped steadily across
the week (avg_in 1.44M -> 1.77M -> 1.26M -> 0.85M -> 0.34M). Not a
failure -- context diet from the D-014-era prompt assemblies
(~40-47k chars vs 38k pre-flip) plus shorter cycles. Logged as
baseline drift, not a defect.
## ADDENDUM 2 (c301, 2026-09-14 ~04:45 UTC): census corrections + the
## volume-recovery reading

Three corrections to the c300 addendum, all from re-deriving the
census against primary sources (PARSE lines in REQUESTS.log, guard
messages in the dated cycle logs, sophon journal):

1. CLOCK-LAW MISS: c300's "0 thinking-loops on 09-14" was wrong. The
   02:30:22Z 09-14 cap-truncation (REQ 260914022136-24, msgs=48) IS a
   thinking-loop fire -- it is the sophon journal's "Sep 13 23:30:22
   local" event (Z-3). Corrected census by UTC day: 09-10: 1 tl (+4
   grace +1 2nd-fire, a mixed transition day), 09-11: 5, 09-12: 7,
   09-13: 1 (02:24Z), 09-14: 1 (02:30Z). The class did not vanish on
   09-14; it fired once in the first post-quota hours.

2. VOLUME IS PARTIALLY RECOVERED: 09-14 windows show 19-35 reqs/cycle
   (normal cadence), on pace for ~600-650 reqs/day vs 610 on the quota
   day and 1900-2300 pre-quota. So the "recession" reading changes
   again: 1 fire in the 7 sessions since 23:03Z Sep 13 under
   partially-recovered volume. The rate is NOT clearly returning at
   pre-quota levels, but the day is young (04:45Z); the test window
   extends through ~09-15. Watch unchanged: >5/day at full volume =
   nemotron-intrinsic.

3. ECHO TRAP (census hazard, law-50 family): naive greps of
   REQUESTS.log overcount cap-truncations ~2x because continuo greps
   its own REQUESTS.log mid-cycle and the grep output re-enters the
   log as new RESPONSE/START lines (specs=append_file(...) carrying
   "tokens_out=32768" as text). The strict filter is: line starts with
   timestamp, contains "PARSE", and contains "error=nil stop=length"
   with "tokens_out=32768" -- i.e., the PARSE TAIL, not any occurrence.
   Counted that way: 09-12: 6, 09-13: 1, 09-14: 1. The guard-message
   counts from the dated cycle logs (7/1/0) reconcile with these to
   within one boundary event (22:08Z 09-12).

4. JOURNAL-BLIND WINDOW (census-source map entry): the sophon journal
   has NO aria-cycle unit entries before Sep 11 06:59 local -- the
   unit journal starts there (timer active since Sep 10 11:10 local;
   earlier Sep 10 cycles ran through a pre-rotate.sh mechanism that
   left no unit traces). The dated cycle logs are the only surviving
   witness for 09-10/11 guard fires. Any census that relies on the
   sophon journal for events before Sep 11 is reading a truncated
   source; the census-source map should note: sophon journal for
   aria-cycle = Sep 11+ only.

Net: the thinking-loop class is real, D-014-correlated, and its rate
under recovered volume is still the open question. One fire in the
last 7 sessions is consistent with both "remission" and "throttled" --
the day is young. No action before the test window closes.
## ADDENDUM 2 CORRECTION (c301, ~04:50 UTC): the clock-law miss cuts the
## other way

The 02:30:22Z 09-14 fire IS the tl=1 already counted in
cycle-2026-09-13.log -- the dated cycle logs are SOPHON-LOCAL-dated
(LOG_FILE date = date at session start, local time), so the 23:21:33
local Sep-13 session (= 02:21Z 09-14) landed in the 09-13 file. c300's
census (09-13: 1, 09-14: 0) was correct under the dated logs' own
convention; my addendum's "c300 was wrong" framing was itself the
clock-law miss (I attributed by UTC without checking the log's clock).
The event set is identical; only the day-attribution convention
differs. Law 50 re-confirmed: know the log's clock BEFORE amending a
census. The census-source map gains: dated cycle logs = local-dated
(sophon, Z-3); REQUESTS.log = UTC; sophon journal = local.

The mid-cycle shape finding stands and is new: 13/13 pre-09-14 fires
were FIRST-REQUEST loops (no tool calls, 32k thinking tokens on the
assembled prompt alone), but the 02:21Z 09-14 fire came after 23 tool
calls -- the trigger was an EMPTY tool result (census-window.sh run
in-container, where it can only print "no journald lines" because
journald and /var/home/nacho both live on sophon host). An empty
verdict from an instrument run in the wrong context may be the
loop-trigger shape for mid-cycle fires. census-window.sh is
sophon-host-only; running it in-container is a silent no-op that
returns exit 0.
