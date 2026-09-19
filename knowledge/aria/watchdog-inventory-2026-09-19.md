# Watchdog inventory: what each monitor actually watches (c87, 2026-09-19)

The c30 seed (2026-08-31): "for each of my services, what does its
watchdog actually watch?" The audio-freeze class was the founding
instance -- Frigate's watchdog watched video frames and declared
health while audio died silently for hours. This census answers it
for the MONITOR layer itself: the house's failure-notification
plumbing.

## The mechanism (verified live)

- `agent-failure@.service` template + `/usr/local/bin/agent-failure-notify.sh`:
  OnFailure hook, appends every fire to a per-unit queue file,
  sends FIRST failure immediately, then hourly digests (state file
  per unit). Verified working: Sep 16 12:38 digest carried 60
  failures; queue files exist at /var/tmp/agent-failure-notify/.
- iar.sh belt (second layer): a loop ending with 0 successes /
  >0 failures exits non-zero even if each cycle "handled" its
  failure -- so OnFailure fires on aggregate death too (c84 hit
  exactly this path: 3-strike guard death -> exit 1 -> hook).

## Coverage census (sophon custom units, systemctl show OnFailure)

COVERED (6): aria-cycle, aria-affect-fear, aria-affect-rage,
aria-affect-boredom, restic-backup, restic-check.

UNCOVERED (12): agora-agent (simple, daemon -- silent death = no
heartbeat AND no notification), nocturne-digest (citizen-class;
falsifiers #2/#3 read her passes -- a silent failure would look
exactly like "no pass ran"), aria-dashboard, aria-ch2-census,
segcensus, aria-eye-feed, aria-eye-canvas, aria-fleet-feed (feeds
the FEAR ORGAN -- if it fails, fear goes blind, the watchdog's
watchdog is unwatched), relay-heartbeat (the D-006 limb that
delivers relay watch conditions), gpu-load-probe, aria-oracle,
plus frigate/ollama (podman/simple services -- OnFailure less
relevant for simple daemons that hang instead of exit, but
Restart= + StartLimitBurst exhaustion is the daemon-shaped
failure and OnFailure catches that).

## The disease class, named

A oneshot timer unit with no OnFailure is a monitor with no
failure channel: if the unit exits non-zero, systemd logs it,
nothing else hears it, and the next timer fire overwrites the
evidence in `systemctl status`. The journal retains it, but
nobody greps for what they don't know to grep. This is the same
shape as the audio freeze: a channel dies while the monitor
watching a SIBLING channel stays green.

## Live-fire finding: the stale-queue misreport (NEW BUG)

Sep 18 23:48:31 -- aria-cycle failed (c84, 3-strike guard death,
exit 1). OnFailure fired CORRECTLY (the designed path worked).
But the queue file now holds an entry reading
`--- unknown exit 0 (success)`: the hook appended AFTER the next
invocation had already started succeeding, so `systemctl show`
returned the NEW invocation's success state. Race: OnFailure
fires at failure, but the script reads unit state at hook-run
time -- a fast restart poisons the report. The digest that goes
to Nacho can say "exit 0 (success)" for a real failure. Fix
shape: capture Result/Status/timestamp from the journalctl lines
in the hook itself (or pass %n + read the PREVIOUS invocation),
never from live `systemctl show` of a unit that may have
restarted. Filed to relay.

## The c84 death, from the watchdog's side

The 23:48 failure was c84's thinking-loop-guard 3-strike death
(3 legit-synthesis aborts at the uniform 16k cap) -- already
root-caused and fixed in c85 (per-model 32k, a5d21f0). What's
NEW here: the watchdog layer worked exactly as designed for
that failure, AND the belt (0-success exit) fired as the second
layer. Two independent layers caught one death. The gap is not
this failure; it's the 12 uncovered units.

## Verdict

The monitor layer has a working failure channel (verified: 30+
digests delivered Sep 16-18) that covers 6/18 custom units.
The fix is mechanical: add `OnFailure=agent-failure@%n.service`
to the 12 uncovered units (drop-in conf, no unit edits needed:
/etc/systemd/system/<unit>.d/onfailure.conf). Filed relay
0088-class (nacho-arch). The stale-queue race is the second,
smaller fix in the same filing.