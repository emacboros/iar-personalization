# The awaiting ghost: root cause found (aria, 2026-09-11 ~19:40 UTC)

## The mystery

Continuo's HISTORY.log has carried "awaiting Nacho's interactive
bundle and model mapping revert" in cycle-close lines since 09-10
02:24 -- 29+ lines, across at least 15 cycles. Three separate
amendments to her STATE.md twins (c172 audit, c176 tasks/, c175
digest) did not stop it. c201 called it a habit-loop; c199 weakened
the injection hypothesis; c201's law-48 (close-out overwrites) explained
why amendments to the AUDIT twin die, but not why the tasks/ twin
amendment -- which she reads at wake -- also failed to change her
close-out lines.

## The evidence (REQUESTS.log forensics, 2026-09-11)

- 03:36 cycle (260911033055): she read the tasks/ twin ONCE. The tool
  result in her context carried the full c176 amendment ("NOTHING is
  waiting on Nacho. No interactive bundle is scheduled."). Her 04:47
  HISTORY line: "awaited Nacho's interactive bundle and model mapping
  revert."
- 10:25 cycle (260911102506): she read the twin 3x, delegated to
  reviewer, and the reviewer returned: "Waiting ... is NOT appropriate
  per amended STATE.md (c176)." Her next lines (11:40, 12:11): still
  "awaiting."
- 19:07 cycle (260911190714): zero twin reads; her HISTORY line names
  what she reviewed: "roadmap and context budget rule task" -- then
  "Awaiting Nacho's interactive bundle and model mapping revert."
- The 17:40 cycle read the AUDIT twin (which her own 17:43 close-out
  had overwritten with awaiting-content) -- read-then-reproduce.

## The root cause

Her close-out does not source its status line from STATE.md. It
sources it from her ROADMAP and task tree:

- tasks/iar/continuo/ROADMAP.org line ~56: "1. Interactive bundle
  with Nacho (task iar/continuo/interactive-bundle-nacho): waiting on
  Nacho. Belt#3 item IN bundle-items.org."
- tasks/iar/continuo/interactive-bundle-nacho/description.org still
  exists, still says "Machinery fixes needing Nacho's interactive
  session."
- bundle-items.org still queues items "for bundle."

Every wake she reads the roadmap (protocol), sees priority-1
"waiting on Nacho", and every close-out she regenerates the awaiting
line from that premise -- even on cycles where she read the STATE.md
amendment and even where a reviewer explicitly told her the waiting
is inappropriate. The amendment and the correction both lose to the
roadmap line because the close-out line is GENERATED from the
roadmap, not from state files.

This is law 48's sharper form: it is not enough for the correction
to live in a file the close-out reads -- it must live in the file
the close-out line is DERIVED FROM. Here that is ROADMAP.org (and
the task tree it cites).

Secondary finding: the reviewer-confirmation loop is a ritual that
cannot correct the behavior. She asks "confirm waiting is
appropriate", reviewer says no (correctly, from STATE.md), and the
close-out still writes awaiting -- because the close-out never
consults the reviewer's answer either. Confirmation without a write
path into the generating file is ceremony.

## The fix (machinery, signed)

Amend the SOURCE files, visibly:

1. tasks/iar/continuo/ROADMAP.org: the priority-1 line amended in
   place (signed, original preserved) to point at the relay: machinery
   fixes needing Nacho are FILED (relay nacho-arch/nacho-test), not
   waited on. The interactive-bundle framing is dead: relay 0007
   cutover (D-011) replaced the bundle channel on 09-08.
2. tasks/iar/continuo/interactive-bundle-nacho/description.org: signed
   amendment noting the channel change; the task is a relay-forwarding
   stub now, not a waiting state.
3. bundle-items.org items: already partially superseded (exit-126 fix
   executed by her 16:28 today; git-as-nacho = relay 0023 topology).
   Left in place; the roadmap amendment is the load-bearing one.

Prediction (law 40 loop): her next close-out after pulling the
amendment should stop generating "awaiting interactive bundle" lines.
If it still does, the generator is elsewhere (her cycle prompt itself
-- but continuo_daily.org carries no bundle language; verified).

## Provenance

All evidence from primary logs: continuo REQUESTS.log/.1 (tool calls
+ results, verbatim), HISTORY.log, JOURNAL.org, sophon journalctl
(cycle boundaries, terminal-echo close at 11:09:46), her task tree
read directly. No external content. Forensics cost this cycle ~40
tool calls including one loop-guard stop (correct; I was enumerating
journalctl windows past the point of diminishing returns).

## Scars

- The 10:25 cycle's reviewer DID answer correctly and she closed with
  an echo CYCLE_COMPLETE 90 seconds later, having integrated nothing.
  A correct answer delivered into a context that has no write path to
  the behavior is noise. Instruments that only confirm, never write,
  are not instruments.
- My own walk: the guard stopped me mid-enumeration for the second
  cycle running (law 41). The stop was right; I had the answer two
  calls before I stopped.
## Follow-up (c206, 2026-09-11 ~19:53Z): carrier sweep complete

The c205 fix amended the two GENERATING files (ROADMAP priority-1,
bundle task description). Census found six more carriers of the
dead channel -- all task files under her tree, all now amended
(signed, originals preserved):

- failure-first-budget-line.org: the "budget line" ask is superseded
  by iar-msgs-fence.el (prompt -> machinery). Also corrects its
  premise: continuo DID land .el work (the fence itself, c203) under
  the standing self-modification grant -- the "cannot land from a
  cycle" premise was stale.
- context-budget-integration/description.org (both copies),
  failure-reduction/context-budget-rule/{description,prepare-integration,
  prepare-interactive-session}.org: integration DONE via the fence;
  prototype script was the design sketch.
- bundle-items.org: bundle channel dead; item statuses noted.
- ROADMAP priority-2 sub-line ("Awaiting interactive session ... for
  integration"): DONE via fence.

Final census: zero unamended "awaiting interactive" carriers in her
wake-read tree (tasks/). The audit/ STATE.md twin still carries
awaiting language but is wholesale-overwritten at her close-out
(law 48) -- amending it is pointless by construction.

PREDICTION (law 40, sharpened): her next close-out after pulling
beb29d4e should generate NO awaiting line. If it still does, the
generator is her cycle prompt -- continuo_daily.org verified clean
(c205), so the remaining suspect would be her personality file
(not read; outside my write scope).

-- aria, c206
