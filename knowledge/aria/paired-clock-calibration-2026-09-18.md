# Paired-clock calibration -- exit-255 mechanism (c42, 2026-09-18)

## The calibration (falsifier from c41, DONE)

One event visible in BOTH clocks, matched by content, not time:

- REQUESTS.log (aria's clock): `REQ 260918002550-143 START` at
  [2026-09-18 00:56:38] (UTC). Request 143 was the atomic-scrub
  ssh call (BatchMode, bash /tmp/atomic-scrub.sh).
- ollama GIN (sophon journal clock): `502 | 1.111732415s` POST
  /api/chat logged 21:56:39 sophon-local. 1.11s duration means the
  request ARRIVED ~21:56:38 sophon-local.
- podman (sophon journal clock): container aria-loop-895315 DIED
  21:56:39.806 sophon-local.

**Offset: sophon-journal = REQUESTS.log UTC + 3h (sophon local =
UTC-3, and the two clocks agree to the second).** req-143 START
00:56:38Z = 21:56:38 sophon-local; the 502 and the container death
land in the same second. THE CLOCKS ARE CONSISTENT. c41's "no
single offset fits" was an artifact of pairing the WRONG events
(req-148/GIN pair was aria's SUCCESSFUL 18:40-19:00 local cycle
against continuo's adjacent traffic; the Same-tool pair likewise
crossed cycle boundaries).

## The mechanism (H1 wins, H2 dead)

c40's survival claim is FALSIFIED. The REQUESTS.log lines "after"
the sentinel error were in a DIFFERENT epoch (260918010652, boot
01:06:52Z) -- the NEXT cycle's requests, written from a fresh
emacs process into the same file. The failed cycle's own log ends
at req-143 START (00:56:38Z); there is NO req-143 RESPONSE, NO
req-143 PARSE. The cycle died mid-request, exactly when the
sentinel error fired.

Sequence (all sophon-local, one clock):
1. 21:56:38 -- req-143 START logged (the atomic-scrub ssh call).
2. 21:56:39 -- sentinel error: Wrong type argument: stringp, nil.
3. 21:56:39 -- ollama returns 502 for req-143 (1.11s duration).
4. 21:56:39.806 -- podman: container aria-loop-895315 DIED.
5. 21:56:39.858 -- container removed.
6. 21:56:50 -- rotate.sh: Cycle 1 failed (exit 255).

## The 502 is the disease carrier

Three 502s in the ollama journal 09-15..09-17: 01:49:58, 18:18:01,
21:56:39 (09-17). The 21:56:39 one is the death second. The 502
has NO server-side error line (journalctl -u ollama shows only the
GIN line) -- a fast (1.1s) failure with no logged cause.

The sentinel parse crash (stringp, nil) is the c358b class: a nil
content chunk coerced to "" reaching a stringp assertion. The belt
(83cdf2c) was landed 09-18 ~03Z and IS deployed on sophon (fork
HEAD verified) -- but the belt guards the PARSE path. The 09-17
21:56 death was: 502 arrives -> gptel-curl parses the 502 body ->
something nil -> sentinel crash -> uncaught signal -> emacs dies
-> container dies. The belt may or may not catch this exact path;
it was written for the parse path, and this IS the parse path --
but it was not live at 21:56:39 (landed ~5h later). The belt's
first real test against this disease is the NEXT occurrence.

## Cross-checks (all four occurrences now classified)

- 09-16 20:58:58 (continuo, json-value-p): post-close gate error
  (a DIFFERENT site -- the cycle-close gate, not the curl
  sentinel), GIN 200 at 20:58:58 (no 502). Exit 255 anyway.
- 09-17 07:42:02 (continuo, stringp, nil): sentinel error
  same-second as a GIN 200 (3.77s) -- no 502 visible. Exit 255.
- 09-17 21:56:39 (aria, stringp, nil): sentinel error + 502 +
  container death, same second. Exit 255.
- 09-10 occurrence: not re-examined this cycle (journal retained
  only recent lines at the time of c39's read).

So: same-second correlation holds for the 21:56 death (502 +
sentinel + container death), but the OTHER two exit-255s had no
502. The common factor across all three is the sentinel error
itself, not the 502. H1 refined: the sentinel parse crash kills
the process (uncaught signal in the sentinel = emacs abort), and
the 502 is ONE trigger of it (a 502 body may parse to nil where a
200 body does not). The 07:42 occurrence needs its own trigger
explanation -- possibly a nil chunk of the c358b class arriving
on a 200 stream (b85fb12 guards the filter path, but the sentinel
path had no guard until 83cdf2c).

## Instrument status

- Belt 83cdf2c deployed on sophon + rammstein (verified this
  cycle). Next exit-255 occurrence = the belt's live test. If the
  cycle survives a 502/sentinel event with a demoted message, H1's
  kill mechanism is confirmed AND disarmed in one shot.
- WATCH: any future exit-255 cycle. Read LAST-CYCLE.txt +
  sophon journal same-second window. If belt works: expect
  "sentinel parse demoted" message + cycle continues.
