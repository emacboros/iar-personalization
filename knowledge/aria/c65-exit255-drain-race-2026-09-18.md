# c65 exit-255 root cause + c66 recovery -- 2026-09-18

## The failure (cycle 65, 2026-09-18 16:53:43Z start, died 17:13:16Z, exit 255)

Chain (all timestamps UTC; sophon journal is -03, reqlog is container-UTC):

1. Cycle woke onto the stash-conflict thread: 6 unpushed stashes on
   sophon's iar-personalization checkout (REQUESTS.log mid-conflict
   snapshots from 09-16/09-17, conflict markers inside file content).
2. glm-5.3-flash thinking ran away 4x (16k chars, no content) between
   16:59-17:01Z; thinking-loop-guard aborted each; retries continued.
3. At 17:03:02Z the cycle delegated a reviewer sub-agent (delegate.el,
   default timeout 600s) to review the recovery plan.
4. The reviewer burned its full 600s (117 requests total in the cycle,
   reqlog epoch 260918165349). At 17:13:02Z the timeout fired; req 117
   (the delegate's own next turn, msgs=76) was LIVE -> c312 drain path
   taken (drain grace 300s).
5. 4 seconds later: "error in process sentinel: Wrong type argument:
   stringp, nil" -> emacs batch process died -> iar.sh recorded exit
   255, LAST-CYCLE.txt = failed.

## Classification

KNOWN CLASS, NEW VARIANT. c148 (2026-09-10) died the same death 10s
after a reviewer delegate timed out; c308/c312 fixed the abort path
(mark completed BEFORE abort, single callback) and added the drain
path for live pipelines. This crash happened DURING the drain window
(+4s), not in the abort path -- the drain timer and the live request's
own curl sentinel raced. The stringp-nil is the same dead-buffer
sentinel shape the c312 comment describes, reached by a different door.

## Why the drain did not save it (open question, next fix)

Drain grace is 300s; the crash came at +4s. Two candidate shapes:
(a) the drain's 1s timer ticked while req 117's curl was mid-setup and
`iar--delegate-live-subrequests-p` missed it (entry not yet in
gptel--request-alist), falling through to timeout-abort, which tore
down a half-spawned curl; (b) the live request's own completion
sentinel hit a state the drain did not expect. Needs a fixture that
reproduces: delegate with a live streaming request at timeout fire.
This is .el work -> interactive session or a delegated build; filed
for Nacho via journal + this doc, not self-modified in-cycle.

## The underlying thread (recovered in c66)

The 6 stashes held conflict-marked snapshots of REQUESTS.log(.1) from
the 09-16 16:31Z pull conflict. All content mined and restored:
- REQUESTS.log.1: +11.6k lines (09-16 16:31 - 09-17 19:01 window)
- REQUESTS.log: +390 (stash 0) +2294 (stash 3/4/5) +518 (model-join
  sweep) +544 (PARSE pairs) +1 = ~3.5k lines, 09-15 onward
- USAGE.log: aria +280, continuo +102 (09-02..09-17)
- continuo REQUESTS.log: +2043 +1017 +652 lines
- census-window verdicts + misc cycle-log lines
Method: extract every stash file, strip conflict markers, sort -u
against current, split by model (glm=aria, nemotron=continuo), merge.
Residual: 23 superseded snapshot lines (LAST-CYCLE/affect) not
restored -- live files are the current truth, snapshots live in git.
All 6 stashes dropped after verification. Pushed sophon + rammstein.

## Laws exercised

- CLOCK-FROM-TOOL / THREE-CLOCK: LAST-CYCLE.txt "ended 17:13:16 UTC"
  initially looked like it predated the next service start; resolved
  by stat on sophon (mtime 14:13:16 -03 = 17:13:16Z) -- the tombstone
  was written by the FAILED run's wrapper, the next fire was +8min.
- c40 EPOCH: reqlog segmented by boot prefix before reading; the
  failed cycle's epoch is 260918165349 (16:53:49Z), not the first
  epoch found in the file.
- Fixture law (c39): the drain-race fix needs a test that reproduces
  the disease (live streaming request at timeout fire), not the shape.