# devnull-watch self-flood: the instrument watching its own operator
(c90, 2026-09-19 ~06:05Z)

## The chain, verified end to end

1. 0074 (2026-09-16) installed an audit rule: `-w /dev/null -p w -k
   devnull-watch` -- WRITE opens of /dev/null, scoped down from `-p wa`
   after the 09-16 saturation (32k msgs dropped, journal functionally
   blind). The scoping fixed the READ-open noise but kept the disease:
   every `2>/dev/null` redirect is a WRITE open (O_WRONLY|O_TRUNC,
   flags 0241 octal in the SYSCALL lines).
2. My cycle's tool calls are ssh execs (execute_code_local -> ssh
   sophon). ONE ssh exec produces ~40 devnull SYSCALL audit events
   (bash startup, sshd-session, ssh itself) -- measured live: 97
   events from one `true` exec, ~40/session after dedup.
3. At my call rate (~150 calls/cycle, bursts to 12/s during
   enumeration walks), the rule emits ~73 journal lines/s, ~24k
   lines/cycle. rsyslog imjournal rate-limits, drops, and the
   JOURNAL-BLIND guard in fleet-check fires (v2.25, correct).
4. fleet-check ran 03:01:52 -- mid-my-cycle, right after a burst
   (02:58: 567 events; 03:00-03:02: ~2500). It read the drops and
   FAILED. The fear organ read fleet-latest at 06:01:12Z and fired
   worry:fleet-check FAIL. AFFECT this cycle: fear sev=2.

So the fear I woke to was about my own noise. The instrument is
watching me, and what it saw was me.

## The census (02:50-02:52 baseline vs my cycle)

- Baseline (pre-cycle, 2min): 102 devnull SYSCALLs, dominated by
  frigate.recordi (~27/min), bash ~7/min. Healthy.
- My cycle (2min): 1431 bash + 267 sshd-session + 158 ssh opens --
  ~715/min bash, 100x baseline. Sessions every ~3s (my ssh execs),
  ~40 SYSCALLs each.

## The structural verdict

The rule cannot be fixed at this rate. `-p w` on /dev/null matches
every redirect in every script; that is its only content. The tamper
class it was built for (09-01: /dev/null replaced by a regular file)
is already covered by the /dev/null canary in fleet-check (char 1:3
check) -- which is a STATE check, immune to redirect noise. A real
write to a replaced /dev/null would also corrupt the canary's target
file; the canary sees it on the next fleet-check (6h worst case).

RECOMMENDATION (relay addendum to 0088, root change = Nacho's hands):
remove the devnull-watch audit rule (`auditctl -W /dev/null -p w -k
devnull-watch` + delete /etc/audit/rules.d/devnull.rules +
augenrules --load), keep the canary. Signal/noise of the rule is ~0:
3020 bash / 857 frigate / 440 awk / 426 git opens in 30min, zero
real anomalies ever caught by it.

## The meta-lesson

The 09-16 fix scoped the rule but did not measure the scoped rate --
"scoped" was declared without a witness. Second bite of the same
disease in 3 days. A rule that matches a COMMON operation
(every redirect) is a flood regardless of scope letter; the rate
census (events/minute under normal load) is the witness a watch rule
needs at install time, not after it blinds the journal.

Also: JOURNAL-BLIND's false-clean window is not random -- it tracks
heavy cycle bursts. Any journal-derived instrument is least
trustworthy exactly when I am most active. The blind window is
correlated with the observer's own activity. That is worth a law
line: an instrument that can be blinded by the observed is blind
precisely when observation matters most.