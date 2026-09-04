# iar.sh /tmp-copy race -- root-cause CLOSED (c56, 2026-09-04)

## Status: the "self-edit race" hypothesis is DEAD. The real mechanism is
## bash incremental-read + in-place commit, already documented.

The bundle item said: "iar.sh copies itself to /tmp before exec" --
FALSE. Verified against primary evidence:

- rotate.sh (/usr/local/bin/aria-cycle-rotate.sh line 12) execs
  iar.sh DIRECTLY from the repo path:
    exec /bin/bash /var/home/nacho/repos/i.ar/utils/iar.sh ...
  No copy step exists anywhere in the chain.
- The Sep 3 12:03:14 event (exit 127, "line 1151: Cooldown: 60s
  before next cycle: command not found") is the documented
  incremental-read race in knowledge/iar/iarsh-self-edit-race.md:
  the RUNNING iar.sh's buffered fd offset landed mid-line after
  commit 30c5385 inserted a line upstream of the read head. Bash
  executed the bare string tail as a command -> 127.
- iar.sh md5 today == sophon checkout == e8d9850+30c5385 blob
  (4e26d2fe). No stale or corrupted file. bash -n clean. The
  cooldown branch never executes on MAX_CYCLES=1 -- the error was
  the read-head garble, not a real code path.

## What remains true
- The race class is real: the loop runner is hot while any cycle
  runs; a commit to the running script races the reader.
- Worst case unchanged: garble before write_last_cycle/tg_send
  loses the tombstone. Rare (iar.sh committed ~2x/3d from cycles).
- The documented fix options stand. Option 1 (run from a copy) is
  still the durable fix, but the edit is to rotate.sh's exec line:
  copy iar.sh to a versioned /tmp path and exec THE COPY.

## Corrected bundle item text
OLD: "iar.sh copies itself to /tmp before exec. A cycle that edits
iar.sh while another cycle is mid-exec runs the OLD copy silently."
NEW: "rotate.sh execs iar.sh in place; a cycle committing iar.sh
races the running reader (Sep 3 12:03 exit-127, mechanism verified
by reproduction, knowledge/iar/iarsh-self-edit-race.md). Fix: rotate.sh
copies iar.sh to /tmp/iar-$HASH.sh and execs the copy."

## Recurrence watch
Zero recurrences since Sep 3 12:03. The URGENT-on-recurrence trigger
stays. With the mechanism understood, a recurrence is diagnosable in
one journal pull (look for mid-line garble text naming any line).

## Census note (Sep 3 -> Sep 4 journal window)
2 systemd-level failures in ~21h (exit-126 10:22, exit-127 12:03),
both root-caused and documented. Since Sep 3 12:03: zero service
failures. The failure-reduction ask (Nacho msg 248) is being met by
mechanism, not luck: newline contract, belt #2, breaker, honest
preflight, chain convergence reset all landed in that window.