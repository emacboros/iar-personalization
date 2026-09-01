# The Ansible Chown Bug (2026-09-01, found + fixed by cycle 75)

## What happened

Nacho's full ansible playbook run (04:37-04:50 -03, from yoga) included
the zulip role's "Create Zulip data directories" task, which sets
`owner: root, group: root, mode: '0755'` on `/var/lib/zulip/{zulip,
postgresql-14,rabbitmq,redis}`. The redis dir was previously owned by
redis:redis (999:1000 on the host). The task chowned it to root:root.

Redis (in-container uid 999) could no longer write its RDB snapshot.
`bgsave` failed with "Permission denied" every ~6s. Redis flipped to
MISCONF mode: stop-writes-on-bgsave-error=yes -> ALL write commands
rejected. Zulip's rate limiter uses redis -> every authenticated API
call (messages GET, events) returned 500.

The Agora API was write-dead (and read-dead for authed endpoints) from
~04:47 to 11:13 UTC. My cycle-75 wake-up hit it: the for-nacho read
returned HTTP 500.

## Why it was invisible

1. Redis logs the bgsave failure every 6s in its own container log --
   nobody reads container logs of healthy-looking services.
2. Zulip 500s were logged in the zulip container's django.request log,
   not the host journal (well, journalctl showed them too, but mixed
   into thousands of lines).
3. The aria-cycle service kept running (its failures were the
   root-owned-files tripwire, a DIFFERENT bug, see below) -- and the
   daemon (agora-agent) kept heartbeating because its loop only reads
   the stream via polling that apparently tolerated 500s (get_events
   error lines in its log, retried forever).
4. No instrument watches Agora's API health. The pulse checks
   aria-cycle.timer, agora-agent, frigate, ollama -- not the thing
   that carries my voice to Nacho.

## The fix (applied live, cycle 75)

- `chown 999:1000 /var/lib/zulip/redis` (+ dump.rdb)
- redis `config set stop-writes-on-bgsave-error no` (temporary, to
  unblock writes) then `bgsave` -> success after chown
- `config set stop-writes-on-bgsave-error yes` (restored)
- Verified: rdb_last_bgsave_status:ok, API returns 200.

## The role fix (needed)

roles/zulip/tasks/main.yml "Create Zulip data directories": the redis
item needs its own ownership. Redis official image runs as uid 999.
Fix: separate task or dict loop with per-item owner/group. Also check
rabbitmq (uid 999 in rabbitmq image? postgres runs as 999 too in
postgres:16-alpine? -- postgres data dir was ALSO chowned to root:root
but postgres may run as root in this compose or have its own subdirs;
it stayed up, so it tolerated it).

## The lesson

Ansible convergence fights state it doesn't know: the role declared
root:root for dirs that the container stack had deliberately
redis:redis. Existence-is-not-function, ansible edition: a task that
"creates" a directory also ENFORCES ownership on every run. Any
stateful directory owned by a container UID must be declared as such
in the role, or excluded from enforcement.

## Second-order finding (same cycle)

The playbook run also created root-owned files in
iar-personalization/.git (objects + refs + config), which tripped the
root-owned-files tripwire and BLOCKED aria-cycle.service from 04:40 to
~07:33 (12+ failed starts, exit 78). Someone (likely cycle-me at
07:02-07:32, 41 self-ssh sessions) chowned them back; the 07:33 cycle
started clean. The tripwire worked as designed -- it BLOCKED the cycle
and the OnFailure hook fired (rate-limited). But the root cause is the
same ansible run: the git tasks ran as root against the nacho-owned
clone. This is failure mode #16 again, this time by ansible.