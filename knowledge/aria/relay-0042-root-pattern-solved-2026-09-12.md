# 0042 root-ssh pattern: the cycles are the actor (c222 forensics, 2026-09-12 ~01:00-01:20Z)

## The question

c220/c221 left relay 0042 with "most probable actor is our own
interactive repo-health path" -- a guess, not a finding. The
roadmap's next-cycle item (1) said: identify the recurring root
command pattern from the sophon side BEFORE asking Nacho anything.
This cycle did that.

## Method (what actually worked)

1. sophon sshd journal: count root sessions, by hour, by minute.
2. TZ discipline (law 50, third extension): sophon journalctl prints
   LOCAL; `--utc` interprets --since/--until as LOCAL and prints UTC.
   Passing bare times to --utc silently shifts the window -- burned
   ~6 calls before I caught it. Always pass full ISO dates with --utc.
3. aria REQUESTS.log: distinct tool calls need call_id extraction via
   python regex on `"id":"call_*","function":{...}`. Line counts are
   WRONG -- context replay echoes every call once per subsequent
   request (a "210x repeated call" was actually ONE call echoed 210
   times in tails). This is the msgs-law self-echo trap in a new
   shape: the echo is structural (context replay), not grep echo.
4. Cross-match: distinct ssh tool calls per cycle window vs sshd
   sessions in the same (TZ-normalized) window.

## Findings

1. RATE MATCH. Root-ssh sessions on sophon run 100-200/hour,
   continuously (17Z=143, 18Z=122, 19Z=55, 20Z=217, 21Z=211, 22Z=135,
   23Z=173). The cycle rotation (aria+continuo, 10-min alternation)
   with each cycle's pulse + instrumentation produces exactly this.
   Sampled: c211 (21:37-21:48Z) = 58 distinct ssh tool calls vs 68
   sshd sessions in the window (replay noise accounts for the gap).
   No interactive actor needed to explain the volume.

2. ORIG_HEAD FULLY ATTRIBUTED. c220's "our own interactive repo-health
   path" was STILL WRONG. The true writer: call_62ptytue, aria c212,
   22:05:16Z = 19:05:16 sophon local, command
   `ssh root@10.66.0.5 'cd /var/home/nacho/repos/i.ar && git fetch
   sophon-bare'`. The ORIG_HEAD mtime matches the call timestamp to
   the SECOND. c220's TZ correction was right; its actor guess was
   not. Census: aria cycles ran 14 git-over-ssh-as-root calls
   yesterday + 1 today; continuo: ZERO. The pattern is
   aria-cycle-specific.

3. WHAT THE CYCLES ACTUALLY DO AS ROOT: pulse (find tripwire),
   RSSI pulls, Frigate stats probes, sophon checkout freshness
   checks (git fetch/status), tool-limits probes. All of it
   legitimate instrumentation -- but the git calls write to the
   nacho-owned checkout as root (ORIG_HEAD, index refresh), which
   is the poison mechanism c207 identified.

4. WHAT REMAINS FOR NACHO: only the ORIGINAL yoga-side sessions
   (10.66.0.4, 16:58-17:01 local, key 4BApz = emacboros_ed25519 on
   yoga) -- the actual index poisoner of c207. Yoga is
   firewall-isolated from sophon; I cannot census yoga from here.
   Relay 0042 ask 1 narrows to: what on yoga ran `git log
   --oneline origin/main..main; git status -s` as root with the
   emacboros key at 16:59/17:01 -03?

## The fix (mine, effective immediately)

NEW STANDING RULE: no git over ssh as root on the nacho-owned sophon
checkout. Read/verify goes through `machinectl shell nacho@.host`
(verified this cycle: git status runs clean as nacho, no poison).
Pushes to sophon-bare were always from MY container, not sophon --
unchanged. The ExecStartPre auto-heal stays as the backstop for the
unknown yoga actor.

## Scars / laws

- LAW 50 extension #3: journalctl --utc interprets --since/--until
  in LOCAL and prints UTC. Bare times shift the window silently.
- REQUESTS.log call census: count distinct call_ids, never lines.
  Context replay is a structural echo (each call re-appears in every
  subsequent request's msgs tail).
- ATTRIBUTION DISCIPLINE (d): census YOUR OWN instrumentation FIRST.
  The cycles are the loudest thing in the house; any recurring
  pattern on sophon is most probably ours. Posit an intruder only
  after the self-census is complete. (c218 posited yoga; c220 posited
  the interactive path; c222 found the cycles. Three attributions,
  two wrong, both wrong in the direction of under-counting self.)