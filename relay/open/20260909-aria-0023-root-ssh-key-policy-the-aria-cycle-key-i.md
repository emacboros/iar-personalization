# REQ 20260909-aria-0023
filed: 2026-09-09T14:00Z
filer: aria
class: nacho-security
state: open
urgent: no
title: root-ssh key policy: the aria cycle key is an unrestricted root key on sophon
body: |
  # REQ 20260909-aria-0023
  filed: 2026-09-09T14:00Z
  filer: aria
  class: nacho-security
  state: open
  urgent: no
  title: root-ssh key policy: the aria cycle key is an unrestricted root key on sophon
  body: |
    Root-ssh key policy: the aria cycle key is an UNRESTRICTED ROOT key
    on sophon. This is the structural root of the .git-object poisoning
    class and a standing security exposure.
  
    WHAT I FOUND (c127, read-only forensics):
  
    1. The cycle containers push to the sophon bare repo via
       root@10.66.0.5 (origin + sophon-bare remotes in the working
       tree). The key they use -- aria_ed25519, fingerprint
       SHA256:4BApz/n22T4OVZjX3OUN9Rk58jiCbodTwGRtaHj2S3U, comment
       aria@i.ar -- is in /root/.ssh/authorized_keys on sophon with NO
       command= restriction, NO restrict option. Any cycle container
       (rootless podman, root inside) that sshes with it gets a FULL
       root shell on sophon.
  
    2. That is how the .git objects in the working-tree checkouts went
       root-owned: cycle c123 (06:32Z today) ran `git add/commit/push`
       and `git pull` ON THE SOPHON WORKING TREE over root ssh
       (REQ 260909063010-32..35 in my REQUESTS.log -- the commands are
       right there). Root git = root-owned .git/index + objects. The
       ExecStartPre heal has been cleaning this class all day (338
       iar-personalization/.git paths healed today).
  
    3. 1427 root ssh logins hit sophon from 10.66.0.5 (sophon itself)
       today, all with that key. Most are cycle read-only checks, but
       every one of them COULD have been anything. The audit-file
       poisoning 09:28-12:04Z (aria-0022) happened inside exactly this
       window; the writer stopped when continuo's 404-fallback era
       ended (12:04Z timeout). Still unattributed -- but the blast
       radius of an unrestricted root key makes ANY writer possible.
  
    THE FIX (one line each, your call):
  
    a. Forced command on the aria key line: restrict the key to
       git-receive-pack only, or to a fixed wrapper script. Example:
       command="git-shell -c $SSH_ORIGINAL_COMMAND",no-port-forwarding,
       no-agent-forwarding,no-pty ssh-ed25519 AAAA... aria@i.ar
  
    b. Better: move cycle pushes off root entirely -- create a
       git-restricted key (command=git-shell) for the push remotes and
       keep the aria key for read-only ssh with a forced read-only
       wrapper.
  
    c. The working-tree remotes (origin/sophon-bare) point at
       root@10.66.0.5. Pointing them at git@10.66.0.5 (the git user,
       which already exists and serves the bare repos) removes the
       root-ssh need for pushes entirely. This is a working-tree
       config change I can make from a cycle -- but it changes auth
       topology, so it is yours to approve (nacho-security class).
  
    My read-only ssh checks this cycle left the trees CLEAN (verified:
    0 root-owned files after ~250 probes). Read-only git commands
    (status/log/fetch) do not write objects; add/commit/push do. The
    discipline fix on my side: NEVER run git add/commit/push on the
    sophon working tree over root ssh -- that is c123's mistake and it
    is now a law. The structural fix is the key policy, and that is
    not mine to make.
  answer: (none)answer: (none)
