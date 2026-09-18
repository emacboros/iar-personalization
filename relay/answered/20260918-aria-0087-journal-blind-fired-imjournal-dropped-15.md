# REQ 20260918-aria-0087
filed: 2026-09-18T23:22Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: journal-blind FIRED: imjournal dropped 15,912 lines; devnull-watch rule is the flood source
body: |
  CLASS: nacho-arch (shared rsyslog/journald config -- your call per 0074 residual)
  
  TITLE: journal-blind fired for real: imjournal dropped 15,912 lines; devnull-watch audit rule is the flood source
  
  WHAT HAPPENED (2026-09-18 19:40-19:54Z, sophon):
  - rsyslog imjournal dropped 15,912 messages at 19:44:01Z ("20000 allowed
    within 600 seconds") + 476 more at 19:53:59Z.
  - fleet-check 21:01Z correctly flagged FAIL=1 (JOURNAL-BLIND:
    "journal-derived reads are FAKE-CLEAN"). The check worked exactly as
    designed -- this is the 0074 residual flag materializing.
  
  ROOT CAUSE (census, this cycle):
  - Total journal inflow now ~2139 lines/min, OVER the imjournal
    2000/min rate limit in steady state, not just under burst.
  - Composition (60s census): ~1222/min are audit lines. Dominant key:
    devnull-watch (~700-1800 events/min, bursty), a2=241
    (O_WRONLY-class opens of /dev/null) by short-lived root bash
    processes: cron redirects, ssh command shells, git hooks, frigate
    recorder. The 19:35-19:45 flood window correlates with continuo's
    git-heavy cycle phase (git 1520 + emacs 925 + frigate 323 events in
    10 min) on top of the cron/ssh baseline.
  - The devnull-watch rule (-w /dev/null -p w, scoped to write-opens in
    0074) audits EVERY root-bash /dev/null write-open system-wide. The
    09-17 measurement (~178/min) was taken in a quiet window; real
    steady state is 3-10x that, and cycle git churn multiplies it.
  
  WHY IT MATTERS:
  - Journal-derived instruments (fleet-check journal freshness, any
    journalctl-based diagnosis) silently lose data when the limit trips.
  - The flood is self-generated: our own audit instrument is drowning
    the journal in our own noise. Perception layer blinding itself.
  
  FIX OPTIONS (your call; I recommend 1):
  1. Remove the devnull-watch audit rule entirely. The /dev/null canary
     check in fleet-check (char 1:3) already detects tamper without
     generating events. The audit rule was belt-and-suspenders; the
     canary is the primary and it never sleeps.
  2. Exclude audit from imjournal (audit already lands natively in
     /var/log/audit/audit.log -- verified active, 7.3MB; the journal
     copy is redundant). Needs an rsyslog restructure (imuxsock/imklog
     instead of imjournal, or a ruleset discard) -- more invasive.
  3. Raise imjournal RateLimit.Burst (20000 -> 100000). Brute force;
     keeps the noise, costs memory, defers rather than solves.
  
  NOT DONE BY ME: any rsyslog/audit config change (shared config =
  yours per 0074 ruling). The rule removal is one auditctl -W + one
  /etc/audit/rules.d/ line delete + augenrules reload if you pick 1.
  
  Falsifier for the fix: after the change, fleet-check JOURNAL-BLIND
  should stay silent for 48h of normal cycle churn including one
  continuo marathon-class cycle.answer: (none)
