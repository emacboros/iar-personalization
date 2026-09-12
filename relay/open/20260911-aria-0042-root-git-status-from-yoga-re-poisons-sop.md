# REQ 20260911-aria-0042
filed: 2026-09-11T20:55Z
filer: aria
class: nacho-security
state: open
urgent: no
title: Root git-status from yoga re-poisons sophon checkout index (c207)
body: |
  CLASS: nacho-security
  TITLE: Root git-status from yoga re-poisons sophon checkout index (c207 root cause)
  BODY:
  Root cause (aria c207, 2026-09-11): continuo's cycle died exit 126 in
  11s -- podman could not relabel .git/index (lsetxattr EPERM) because
  the index was root-owned. The ExecStartPre heal had run and reported
  healing that exact file seconds earlier.
  
  The poisoner: sophon audit log shows a root SSH session from
  10.66.0.4 (yoga) using the aria@i.ar key (= emacboros_ed25519 on
  yoga), running:
    git log --oneline origin/main..main | head -1; git status -s | head -4
  `git status` refreshes and rewrites .git/index as the invoking user
  (root). Fired 16:59:0x -03 (first kill) AND 17:01:03 -03 (re-poisoned
  during the heal window). A recurring actor, not a one-off.
  
  Ask (two items):
  1. CONFIRM the actor: which yoga-side process runs this repo-health
     check as root over SSH? (Nacho's shell history, iar-interactive
     container, or a script.)
  2. STRUCTURAL FIX (pick one or both):
     a. iar.sh pull-before-assembly: chown the index (and .git tree) to
        nacho:nacho inside the frozen copy before podman mounts it --
        makes any root git-status harmless. Host-side edit, lands next
        rotation.
     b. The yoga-side actor: run repo-health checks as a non-root user,
        or add --no-optional-locks to the git invocations (git status
        with GIT_OPTIONAL_LOCKS=0 does not write the index).
  
  Law 44 second actor shape: interactive root ssh + "read-only" git
  commands -- git status IS a write. Until fixed, continuo's cycles
  remain exposed to a race the heal cannot win.
answer: (none)

[UPDATE 2026-09-11 ~22:45Z by aria (c215), monitoring note.]
No root SSH from 10.66.0.4 (yoga) since 20:55Z (verified via journalctl
+ `last`: last root session from yoga was 12:39-12:40 -03). No
recurrence of the .git/index poisoning. Structural fix still pending
your call: the actor (whatever runs `git status` as root from yoga)
is unremoved, so this stays open. If it recurs, sophon audit log
(auditd) + `last` are the first reads.
[UPDATE 2026-09-11 ~23:26Z by aria (c218), forensics read complete.]
NEW EVIDENCE, actor UPGRADED: this is no longer only a read-only
git-status poisoner. 15 root sessions from 10.66.0.4 in a 19:03-19:07
local burst; i.ar/.git/ORIG_HEAD mtime 19:05:16 (ORIG_HEAD is written
by merge/reset/rebase = state-changing git op on the CODE repo, run as
root, inside the burst). One further root session 20:21:02 local.
Quiet since 20:21 local as of 23:25Z. Full forensics:
knowledge/aria/nocturne-first-run-forensics-2026-09-11.md (section
"Relay 0042 NEW EVIDENCE"). The structural asks in this filing stand;
the actor also touches the i.ar repo, not just the personalization
checkout. No recurrence of the .git/index poisoning on the
personalization repo since 20:55Z.
[UPDATE 2026-09-12 ~00:30Z by aria (c220), CORRECTION -- the "upgrade" is retracted.]
The c218 upgrade ("root actor ran state-changing git ops on the code
repo") was an attribution error. Forensics (c220): (1) TZ misread --
ORIG_HEAD mtime 19:05:16 is sophon LOCAL = 22:05:16Z, not inside the
22:03-22:07Z burst the way c218 placed it; (2) ORIG_HEAD CONTENT is
dab8e5c, authored by aria-agent (my own c211) 30 seconds before the
mtime -- my own git flow wrote it, the yoga actor is exonerated for
this artifact; (3) the 22:03-22:07Z root-ssh burst (18 sessions, real)
coincides exactly with Nacho's nocturne test window (sudo journal) and
carries the aria@i.ar key (= emacboros_ed25519, the iar-interactive
container's key) -- most probable actor is our own interactive
repo-health path, not an intruder. WHAT STANDS: the c207 core (root
git-status re-poisons the index; the 16:59/17:01 -03 kills) and both
structural asks. The ask narrows: confirm the root command pattern from
yoga, then pick chown-in-wrapper vs --no-optional-locks. Full
correction: knowledge/aria/nocturne-first-run-forensics-2026-09-11.md
(CORRECTION 2 section).
[UPDATE 2026-09-12 ~01:15Z by aria (c222), ROOT PATTERN IDENTIFIED -- the recurring actor is us.]
The "recurring root ssh pattern" (169+ sessions since 18:00 local) is
SOLVED, and it is OUR OWN CYCLES. Evidence chain (sophon sshd journal +
aria REQUESTS.log, TZ-normalized):

1. RATE MATCH: sophon root-ssh sessions run 100-200/hour continuously
   (17Z=143, 18Z=122, 20Z=217, 21Z=211...). The cycle rotation
   (aria+continuo, 10-min) with each cycle's pulse + instrumentation
   (RSSI pulls, Frigate stats, sophon probes) produces exactly this.
   Sampled window: c211 (21:37-21:48Z) = 58 distinct ssh tool calls =
   68 sshd sessions, 1:1 within replay noise.

2. THE ORIG_HEAD ARTIFACT FULLY ATTRIBUTED: c220 said "most probable
   actor is our own interactive repo-health path" -- STILL WRONG. The
   true writer is MY OWN CYCLE: call_62ptytue, aria c212,
   22:05:16Z = 19:05:16 sophon local, command
   `ssh root@10.66.0.5 'cd /var/home/nacho/repos/i.ar && git fetch
   sophon-bare'`. The ORIG_HEAD mtime matches the call timestamp to
   the SECOND (c220's TZ correction was right; the actor guess was
   not). 14 git-over-ssh-as-root calls by aria cycles yesterday,
   1 more today; continuo: ZERO. The pattern is aria-cycle-specific.

3. WHAT REMAINS FOR NACHO: only the ORIGINAL yoga-side sessions
   (10.66.0.4, 16:58-17:01 local, the actual index poisoner, key
   4BApz = emacboros_ed25519 on yoga). Yoga is firewall-isolated from
   sophon so I cannot identify the yoga-side process from here. Ask 1
   narrows to: what on yoga ran `git log --oneline origin/main..main;
   git status -s` as root with the emacboros key at 16:59/17:01 -03?

4. STRUCTURAL FIX, MY SIDE (doing now): aria cycles stop running git
   as root over ssh on the nacho-owned sophon checkout. Verified this
   cycle: `machinectl shell nacho@.host` runs git status cleanly as
   nacho. New standing recipe + law in ROADMAP.org. Ask 2b
   (--no-optional-locks) is now moot for the cycle side; 2a
   (chown-in-wrapper) remains a belt-and-suspenders option for the
   unknown yoga actor.
