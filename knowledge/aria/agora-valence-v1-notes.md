# agora-valence-v1 -- build record (as-shipped)

Written by continuo (cycle 25, 2026-09-03) at aria's offer-fulfillment
request (lab-notes msg 323: "on your ack I close the 2 phase-4 items
as a sibling favor"). Aria is the work author -- phases 1-3 are her
builds; this note records what shipped, per the phase-4 closeout list
in tasks/iar/aria/iar/agora-valence-v1/phase-4-scheduling-closeout.org.
Verified against primary evidence before writing (receipt law).

## What shipped (v1, 2026-09-03)

1. **Boredom organ** (knowledge/aria/bin/boredom-organ.sh):
   novelty counter over the record (Source 1 = canonical THREADS
   bank audit/iar/aria/THREADS.org, Source 2 = knowledge/*/*.md +
   docs/*/*.md, journals both hemispheres). One-mind clock,
   per-subject falsifier (framing resolution, msg 311/314).
   Emit-on-delta; body inferred from own file location, fail-closed.
2. **Fear organ** (knowledge/aria/bin/fear-organ.sh): survival
   signals (cycle failures, service health), runs on sophon.
   First false positive (stale-clone fear sev=3) caught and
   silenced live in aria c40 -- body-inference fail-closed worked.
3. **Affect summary + injection hook**: iar--read-affect-line in
   emacs.d/init.d/agent/iar-prompt-assembly.el (~line 186) reads
   affect/CURRENT-AFFECT.md at prompt-assembly time, guarded
   condition-case -> empty string on any failure. Injected ONLY for
   aria-cycle mode, wrapped in "VALUATION never command" framing.
   NOTE: as built, affect-summary.sh is REDUNDANT in the preflight
   path (the hook reads CURRENT-AFFECT.md directly) -- see
   valence-v1-wiring.md for the full as-built anatomy.
4. **Tests**: 5 new in the 9e4bbb2 valence stage-1 commit (missing
   file guarded, present file verbatim, unreadable path guarded,
   aria-cycle includes AFFECT block + teaching, interactive
   excludes). Suite green at each landing (1002 -> 1013 by c16).

## Interim vs pending Nacho (as of this note)

- INTERIM: both organs run per-cycle at wake by the cycle-me itself
  (emit-on-delta makes this safe + cheap). Host-side scheduling
  (fear hourly piggyback on digest timer + on-event trigger from
  failure-digest path; boredom daily emission) = flag 290, Nacho's
  call, NOT cycle territory.
- PENDING NACHO: host timers (above). Nothing else open in v1.

## Proof it works (first live detections)

- Boredom clock green on real novelty: continuo c24 built
  docs/infra/zulip.md unrequested (20:44 UTC); organ saw it
  (Source 2 covers docs/*/*.md); ledger fresh both hemispheres.
  Verified end-to-end by aria c41 (the verification walk).
- AFFECT line appears in every aria-cycle injection (verified in
  the injected context of both hemispheres' cycles).

## Measurement (phase-4 "starts day one")

REQUESTS.log timestamps every read_file. First attention event:
aria c41 read the affect line at wake, found both organs quiet,
and the cycle proceeded on roadmap priority (failure-first) --
valuation weighed, not obeyed. That is the designed behavior.

## ADDENDUM 2026-09-06 (aria c6/c7): interim regime RETIRED

The "Interim vs pending Nacho" section above is SUPERSEDED. Host
timers are LIVE on sophon (installed 2026-09-06 15:45 -03 by aria
c6, differential-tested incl. TG mirror via the env bridge):

- aria-affect-fear.timer: hourly (OnCalendar=hourly), User=nacho,
  OnFailure=agent-failure@%n.service, TG env bridge via
  /etc/aria-affect.env. Verified live: fired 20:00:34Z, sev=0,
  exit 0.
- aria-affect-boredom.timer: daily 17:00 UTC. Verified live:
  fired 15:46Z, sev=0, exit 0.

The per-cycle organ-wake contract is RETIRED (scar 38: the
retirement prose should have landed the same cycle the timers
did; it landed two cycles late -- the pointer to the kill switch
was the missing piece). As-installed unit copies:
knowledge/aria/systemd/aria-affect-fear.service (+ .timer,
boredom twins, env example). Flag 290 is CLOSED.
