# CONTINUO CLOSE-PATH CENSUS -- the sentinel-echo close is her normal ending
# Cycle 270, 2026-09-12 ~23:20 UTC. Method: cycle-log parsing (audit/iar/
# continuo/cycle-2026-09-1{0,1,2}.log + aria same days), no REQUESTS.log
# needed for the headline.

## The question

Continuo's 23:17Z cycle closed with "Terminal sentinel echo (pre-tool-call,
CYCLE) -- closing cycle" and Turns: 0. Is that a defect (model echoing the
sentinel instead of finishing work) or her normal ending? The c270
census answers it with three days of data.

## Census (exit-0 cycles only)

| day        | agent    | sentinel-echo close | model-text close | failed |
|------------|----------|--------------------:|-----------------:|-------:|
| 2026-09-10 | continuo |                   6 |               19 |      6 |
| 2026-09-11 | continuo |                  42 |                4 |      5 |
| 2026-09-12 | continuo |                  32 |                5 |      6 |
| 2026-09-10 | aria     |                   0 |               32 |      0 |
| 2026-09-11 | aria     |                   0 |               52 |      0 |
| 2026-09-12 | aria     |                   0 |               41 |      1 |

Reading:
- Aria NEVER ends by sentinel echo (0/125 exit-0 cycles). I write
  CYCLE_COMPLETE as model text, the intended close path.
- Continuo's echo share went 6/25 (24%) on 09-10 -> 42/46 (91%) on
  09-11 -> 32/37 (86%) on 09-12. The echo-close is now her DOMINANT
  ending, and it tracks the model mapping: 09-10 was mixed (part
  glm-5.3-flash), 09-11+ is all nemotron-3-super:cloud (D-014 flip).
- Echo-closed cycles are healthy-sized (13-70 tool calls, normal token
  burn). They are not early exits: the model does its work, then closes
  by calling `echo "CYCLE_COMPLETE"` as its final act instead of writing
  the sentinel as text. The iar--cycle-terminal-echo-p discriminator
  (aria-0030, c166/c167) catches exactly this and registers the close.

## Verdict

NOT a defect. The echo-close is a MODEL-IDIOSYNCRATIC ending path that
the machinery already handles: nemotron reads "signal CYCLE_COMPLETE"
as an action and performs it with a tool call; the pre-tool-call hook
recognizes the shape and closes the cycle with exit 0. This is the
aria-0030 fix working as designed, at scale. The cost is one extra
request per cycle (the echo turn) -- noise, not a leak.

The 5 model-text closes per day are the days' exceptions, not the rule.
If continuo ever flips back to glm-5.3-flash, expect the ratio to
revert toward 09-10's mix.

## What I checked and ruled out

- Sentinel-in-thinking phantom close (c132): NOT this -- the echo close
  goes through the pre-tool-call hook with the last-tool-spec
  discriminator, not a thinking-block regex match.
- Early termination: echo-closed cycles have full tool-call counts and
  token budgets consistent with their siblings. No work abandoned.
- Exit-1 cycles (5-6/day): these are the truncated-output guard
  (stop=length, 32768-token thinking loops) -- already known, already
  filed (relay 0057's neighborhood; continuo's own journal says model
  degradation, mapping change is Nacho's).

## Law-shaped takeaway

An ending's FORM is model-specific; the machinery's job is to recognize
every honest ending, not to enforce one dialect. The terminal-echo
predicate is not a workaround -- it is the second dialect of "done."
Watch item: if a THIRD dialect appears (e.g. a model that ends by
calling a different tool with the sentinel in args), the discriminator
covers only execute_code_local echo shapes.

## Provenance

All counts from audit logs in this repo (primary evidence, not
summaries). iar-agent-cycle.el read at /root/i.ar/emacs.d/init.d/agent/
iar-agent-cycle.el lines 155-215 (iar--cycle-complete-p) and 590-710
(iar--cycle-terminal-echo-p / -close).