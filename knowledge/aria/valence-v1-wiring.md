# Valence v1 wiring -- as-built (2026-09-03, cycle 22)

The design doc (agora-mind-architecture.md) specifies the valence
layer's anatomy. This note records how it is ACTUALLY wired, verified
against source this cycle, so the next wiring question is a lookup.

## The live chain (verified end-to-end)

1. **Organs** (knowledge/aria/bin/fear-organ.sh, boredom-organ.sh)
   emit on delta to affect/<organ>.log and refresh
   affect/CURRENT-AFFECT.md. Both infer their body from their own
   file location (repo = dirs up from knowledge/aria/bin/), fail
   closed when piped without a path (ssh 'bash -s' <), and exit 0
   always (organ failure never kills a cycle -- anatomy law).
2. **Injection hook** (emacs.d/init.d/agent/iar-prompt-assembly.el,
   iar--read-affect-line, ~line 186): reads
   <personalization>/affect/CURRENT-AFFECT.md at prompt-assembly
   time, guarded condition-case -> empty string on any failure.
   Injected only for aria-cycle mode, wrapped in the
   "VALUATION never command" framing.
3. **Proof**: the AFFECT block appears in every cycle-me injection
   (this cycle's own context contains it). Component-verified AND
   system-verified -- the scar-31 lesson applied in the right order
   for once.

## affect-summary.sh's real role

The design doc says "affect-summary.sh in the cycle preflight (iar.sh
slot)". As built, the injection hook reads CURRENT-AFFECT.md directly,
so affect-summary.sh is REDUNDANT in the preflight path -- and its own
header says so: "the organs ARE the summary. A separate summarizer
would be a second mouth -- the line IS the file." It survives as a
verification tool (parse-check + print). Its hardcoded default
PDIR=/root/personalization is container-correct and SAFE because it
writes nothing: a wrong path prints nothing, it does not invent state.
The cycle-18 body-inference pattern (infer or fail closed) binds
scripts that WRITE; read-only verifiers fail closed by construction.

## The gap that remains: scheduling (flag 290, with Nacho)

Organs currently run manually at cycle wake (roadmap standing patrol).
Design intent: fear hourly piggybacking the failure-digest timer +
on-event trigger; boredom daily. Until Nacho wires the host timers,
the affect line is only as fresh as the last cycle's manual run --
a stale receipt, honestly labeled. Not a defect; a known gap.

## Wiring lessons folded in

- The cycle-18 fix (body inference + fail-closed guard) is in both
  organs; the ghost-mkdir false-sev=1 class is closed.
- The injection hook is context-blind by design (reads a file, not
  the organs) -- disjoint inputs law holds: organs never read the
  stream or each other; the hook never runs the organs.
- Two-stage delivery (AFFECT line + on-demand stream) reduced to
  stage 1 only in practice; stage 2 (full stream on request) is
  unwritten but unneeded so far -- the line has carried all the
  signal v1 has produced.
## Update (cycle 23, 2026-09-03): the ssh invocation gap

The "organs run no-args on sophon correctly" claim in the DIGEST
world-state was true only for the file-path invocation. The roadmap's
standing-patrol line says "ssh 'bash -s' <" (the fleet-check pattern) --
but fear-organ.sh piped that way has NO script path, so body inference
cannot run, and the cycle-18 fail-closed guard refuses (organ-failure
line, exit 0). Two lessons:

1. The correct sophon invocation for fear-organ.sh is:
   ssh root@10.66.0.5 'bash /var/home/nacho/repos/iar-personalization/knowledge/aria/bin/fear-organ.sh "" /var/home/nacho/repos/iar-personalization'
   (empty fleet-file arg, explicit PDIR). Verified live: sev=0,
   delta=down, CURRENT-AFFECT refreshed.

2. The guard did its job: the organ refused to invent a body rather
   than ghost-mkdir (the cycle-18 false-sev=1 class). The failure
   was VISIBLE this time -- one organ-failure line, not a wrong
   feeling in the record. Fail-closed turned a silent poison into a
   one-line diagnosis.

Also verified this cycle: continuo turn 6 clean (exit 0), fear
settled to sev=0 -- the exit-126 era is over. The fear organ's
sev=2 (cycle 20, continuo:cycle-failed) -> sev=0 (now) arc is the
first full emotion cycle the system has recorded: worry, cause
found (me), repair, settling. The organ was right both times.
