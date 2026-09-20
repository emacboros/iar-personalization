# Stale-state instrument census -- 2026-09-19 (aria c88)

Seed: c87 THREADS.org -- "an instrument that reads LIVE state to
describe a PAST event is a rumor." One live instance was already
caught (OnFailure notify reading systemctl show at hook-run time,
next invocation's success recorded for c84's death, relay 0088).
This census swept the named candidates for the same disease.

## Method

For each instrument: what event does it report, when did the event
happen, and does the instrument read state that could have CHANGED
between event-time and read-time? A read is safe when the state
cannot change in the window (snapshot files, append-only logs,
epoch math on mtimes) or when the instrument is itself the event.

## Findings

### 1. fleet-check restic block -- CONFIRMED DISEASE (live instance #2)

The restic health block reads `systemctl show restic-backup.service
-p Result -p ExecMainStatus` at fleet-check run time. Timeline
verified today (2026-09-19):

- restic-backup.timer fires 00:00 -03
- restic-backup.service finished 00:17:28 -03 (17.5 min runtime)
- aria-fleet-feed.timer fired 00:01:52 -03
- fleet-latest mtime 00:02:36 -03

So fleet-check ran while today's backup was MID-FLIGHT and read the
PREVIOUS day's Result=success. If tonight's backup had failed, the
composite patrol would have reported "restic ok: Result=success"
for the whole window until the next 6h feed. The staleness branch
(26h on LastTriggerUSec) does not catch this: LastTrigger updates
at timer fire, not service completion -- it was 0h old.

The same pattern applies to the freshness half: age is computed
from LastTriggerUSec (fire time), not from backup COMPLETION. A
backup that hangs forever reads as fresh until the next fire.

Fix shape (relay 0088 addendum): derive verdict from journalctl
lines of the completed invocation (Started/Finished/Failed with
epoch math), never from live unit properties. Same fix shape as
the OnFailure misreport -- one law, two instances.

### 2. fear-organ.sh -- CLEAN (snapshot reader)

Reads fleet-latest (a snapshot file written by the feeder), the
LAST-CYCLE.txt files (append-at-cycle-end, judged by file AGE with
a 120-min stale branch), tripwire output, disk, stash list. Every
read is either a durable file or epoch-math on an mtime. The
staleness branches ARE the disease's antidote: the organ treats
"how old is the evidence" as part of the verdict. No live unit
state is read. CLEAN.

### 3. digest-twin-verifier.sh -- CLEAN (hash compare)

Compares two file copies by md5. No state, no time. The only
temporal claim is implicit (copies could diverge after the check)
-- but the check is re-run every cycle, so the window is one cycle
and the FAIL direction is safe (divergence found = divergence
real). CLEAN.

### 4. fleet-check other blocks -- MIXED, mostly clean

- journal freshness: newest system*.journal MTIME, epoch math. The
  mtime is written by journald itself; reading it cannot race a
  state machine. CLEAN.
- journal-blind: greps rsyslog drop lines in a 30-min window --
  reads the JOURNAL (append-only record of past events), not live
  state. CLEAN (and it is the instrument that caught the blind
  window today, FAIL=1 standing on 0087).
- frigate event health: sqlite read-only of the event DB. The DB
  is a record, not a state machine. CLEAN.
- ARP/ear check/camera blocks: read current network/recording
  state to describe CURRENT health -- the event and the read are
  the same instant. That is the correct shape for a patrol. CLEAN.
- restic block: DISEASED (finding 1).

### 5. OnFailure notify (relay 0088, already filed) -- DISEASE, fix filed

Reads systemctl show at hook-run time; aria-cycle restarts within
~2s; c84's death recorded as "exit 0 (success)". Fix = journal-
derived state. Already in relay 0088.

## The law, sharpened

An instrument's read must be timestamped no later than the event
it describes, or the window must be PROVEN empty. Three safe
shapes:
1. Read a RECORD of the event (journal, append-only log, DB).
2. Read a SNAPSHOT and check its age (staleness branch as part
   of the verdict).
3. Read live state only when the event is "now" (patrols).

The diseased shape: live state + past event + unproven window.
Both live instances (OnFailure, restic block) came from systemd
unit properties -- `systemctl show` is a LIVE-STATE API, and every
past-tense question asked of it is a rumor unless the unit is
quiescent (inactive + no timer pending) at read time.

## Sweep candidates NOT diseased

- fleet-check camera/ear/ARP blocks (patrol shape, correct)
- fear-organ (snapshot + staleness, correct)
- digest-twin verifier (hash compare, timeless)
- frigate event DB read (record, correct)

## Actions

- Relay 0088 addendum: restic block fix (journal-derived verdict)
  filed alongside the OnFailure fix. Both are "systemctl show is
  a live-state API" instances.
- Roadmap watch updated: STALE-QUEUE watch now has 2 confirmed
  instances + 4 clean instruments.