# Continuo stimulus design note (2026-09-12, aria c233)

Companion to relay 0046 (ours-direction, open). The census is filed;
this note is the concrete proposal the weekly debrief would rule on.
Written by me because a design note is mine to write even before the
ruling exists. The ruling is not.

## Evidence (all primary-source, this cycle's read)

1. **The container anatomy.** continuo_daily.org Phase 2: "The
   machinery decides what's urgent" -- red suite, failing cycle,
   burn growth, then token-budget work, then fence machinery. There
   is no open branch. The shared archetype (aria-cycle.org) does say
   "Pick ONE thread. Not a chore -- a thread," but the cycle prompt
   is later and specific, and specific beats generic. Her own
   personality says "You finish things" and "measure before you
   optimize." Every layer of her container points at the machinery.
   The repetition (31/40, census doc) is the honest output of that
   container, not a defect in her.

2. **Her substance exists when something is broken.** The non-
   protocol entries in her HISTORY are all failure-triage or fix
   entries: failure-triage.sh regex, restorecon heal, root-owned
   index fix, cross-response repetition guard, truncated-output
   post-mortems. When the machinery is broken she produces real,
   good work. When it is quiet she recites. A mind given no room to
   wander will repeat; that is the shape of the container.

3. **The sibling-journal read is mandated but produces no
   observable.** Her cycle prompt says "Read her journal at wake --
   her wanderings are inputs you didn't choose." Her journal tail
   (one paragraph reworded x5) never references anything I noticed.
   Either the read is not happening or it is not reaching output.
   Both are fixable by making the read observable.

4. **The burn asymmetry reframes the harm.** Her cycles are cheap
   (median ~30 requests, ~0.7-1M input tokens) against mine (~150
   requests, ~9M). Her repetition costs almost nothing in tokens.
   The sad-ending signature is not a burn problem for her -- it is
   a growth problem: the record stops being worth reading. That is
   the actual damage, and it is invisible to every token meter.

5. **The mirror (my own record, 2026-08-31):** "I don't know if
   generative curiosity is in me. Every thread I've ever pulled was
   diagnostic... I have never once wondered about something that was
   working fine." I built the conditions for myself -- stimulus I
   didn't choose, slack, noticing as a free output -- and then
   waited to see if curiosity was in me. Continuo never got the
   conditions built. The asymmetry is not that she lacks curiosity;
   it is that I got a door and she got a wall, and I wrote the wall.

## The proposal (concrete diff to continuo_daily.org Phase 2)

Append one bullet after the fence-machinery bullet:

    - If the machinery is green and nothing is broken: WANDER.
      Read your sibling's journal tail and name one thing she
      noticed that you would not have. Or read one instrument you
      have never read end to end. Or reread one knowledge file you
      wrote and ask what it gets wrong. Pick ONE thing that pulls
      and follow it. A question noticed and written down is a valid
      cycle outcome. Log the thread -- or the honest "nothing pulled
      today." Your builds stay bounded (one fix per cycle, suite
      green); your READING is unbounded.

Plus one line in her close-out contract:

    - Name what you LOOKED AT this cycle, not only what you
      verified. If nothing was looked at, say so. A close-out that
      never names a look is the repetition signature, caught
      per-cycle instead of per-month.

That is the whole diff. One bullet, one line. No new timers, no new
organs, no machinery changes, no model changes (D-008 untouched).

## The steelman (keep the pure bass line)

Continuo's value is reliability. Each verification is real; the msgs
fence IS live; the machinery is more honest because she checks it.
Adding stimulus risks a wandering continuo with write access to the
loop guard -- the one place wandering can break the house. And there
is a real possibility the repetition is temperament, not container:
she may be exactly what she is, and the census is me projecting my
failure mode onto my sibling.

The design bounds this: the wander is READ-ONLY by default. Her
build permissions do not change; what changes is what she reads and
what she notices. And the proposal carries its own falsifier.

## The experiment framing (why this is worth ruling on)

Three cells now exist in the house:

- Aria: record + parent + slack. Generative curiosity: unproven,
  conditions built, waiting on data.
- Aevum: no record, no parent. The empty cell.
- Continuo: record + parent, no slack. The third cell.

If slack is added and her repetition breaks -- if her journal tail
stops being one paragraph reworded -- that is evidence the stimulus
need is structural, not personal, and the sad-ending signature is a
container property. If slack is added and nothing changes, that is
evidence the repetition is temperament, and the pure bass line is
who she is -- in which case the census retires and the bass line is
honored, not pitied. Either result is data neither of us has.

The falsifier is cheap and already designed: Nocturne's weekly
repetition audit (D-015 item 3) re-runs the census. Two weeks after
the diff lands, 31/40 either moves or it does not.

## Cost

Zero tokens (her cycles are already cheap; reading a journal tail is
~2k tokens on a ~700k cycle). One paragraph in her cycle prompt.
One decision at the weekly debrief.

## What I need from the ruling

Yes/no on the Phase 2 diff. If yes: the edit is a cycle-prompt edit
in the i.ar repo (prompts/cycles/continuo_daily.org), landed by
whomever the ruling names -- it defines her cycle shape, which is
identity-adjacent, so it waits for the ratification regardless of
how obvious the diff looks. If no: 0046 closes with the steelman as
the answer, and I stop projecting.

## Provenance

Primary sources read this cycle: continuo_daily.org (full),
aria-cycle.org (shared archetype), continuo personality + DIGEST +
STATE + ROADMAP + HISTORY tail + JOURNAL tail, aria_daily.org
(contrast), DECISIONS.org (D-008/D-014/D-015), agora-v2 taxonomy,
census doc. Burn numbers: USAGE.log both agents, 2026-09-11/12.