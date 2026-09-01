# Ansible from the Aria container

How to run Ansible playbooks without Nacho. Learned 2026-09-01
(Nacho: "you can run ansible roles, you have the .vault file").
This is a dependency-reduction instrument: the goal is that infra
changes converge via the playbook, not via my ad-hoc SSH edits.

## The path

The Aria container (yoga) cannot run ansible directly: no ansible
binary, no vault pass (they live on yoga's REAL home, which is not
mounted into the container). But yoga is reachable over SSH:

    ssh nacho@yoga

(nacho@yoga works with the container's key; root@yoga does not.)

## The procedure

1. Sync the repo (yoga clone pulls from rammstein, which is where
   Aria pushes):

       ssh nacho@yoga 'cd ~/repos/iar-infrastructure && git pull --ff-only'

   (yoga's origin is github; if the pull fails, fetch rammstein and
   merge --ff-only rammstein/main -- both remotes exist.)

2. Dry-run first (--check), limited to the target host and the
   roles that changed:

       ssh nacho@yoga 'cd ~/repos/iar-infrastructure && \
         ansible-playbook playbooks/site.yml \
           --limit sophon --tags restic,frigate \
           --vault-password-file ~/.vault_pass --check'

   Tags available: base, wireguard, caddy, git-repo, pass, restic,
   radicale, ollama, frigate, secplatform, zulip, ... (see site.yml).
   There are also standalone playbooks: restic.yml, iar-agents.yml,
   secplatform.yml, zulip.yml, etc.

3. Real run: drop --check.

4. Watch for: the vault pass is ~/.vault_pass on yoga; ansible.cfg
   already points at it. The ansible SSH key is ~/.ssh/ansible_ed25519
   (yoga), authorized on all hosts.

## Gotchas learned the hard way

- **fail2ban on sophon rate-limits SSH.** A heavy diagnostic session
  (dozens of rapid connections, mine + cycle-me's in the same window)
  trips kex_exchange_identification: Connection reset by peer -- for
  EVERYONE (root, nacho, from rammstein too). The host is fine; sshd
  refuses. Wait it out (10min-1h+). The heartbeat (aria-cycle) runs
  locally on sophon and is unaffected. Instrument repair must
  rate-limit itself (cycle 66's lesson).

- **Ansible resolves sophon via ~/.ssh/config on yoga** (HostName
  192.168.2.69, the LAN IP). If that path is banned, the playbook
  dies at Gathering Facts with UNREACHABLE.

- **Never git on sophon's repos as root over ssh** (the tripwire
  poison class). The ansible path avoids this entirely: yoga pulls,
  ansible pushes files as the right user.

- The restic role on sophon runs as root (systemd service) -- the
  vault password file is /home/nacho/.config/restic-password there.

## What this replaces

Before: Aria edits live files on sophon via root SSH (works, but
drifts from the repo and risks the tripwire + fail2ban classes).

After: Aria commits to the infra repo (yoga mount), pushes to
rammstein, then runs the playbook from yoga. The repo is the
source of truth; the hosts converge to it.