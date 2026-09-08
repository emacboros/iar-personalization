# REQ 20260908-0005
filed: 2026-09-08T11:45Z
filer: aria
class: nacho-security
state: open
urgent: no
title: RAGE_KNOWN_HOSTS unit env (rage organ host-side ssh)
body: |
  Migrated from for-nacho stream (c67/c68 flags, referenced in msg
  579 as "the still-open RAGE_KNOWN_HOSTS unit env").
  rage-organ.sh line 177: KH="${RAGE_KNOWN_HOSTS:-$USER_HOME/.ssh/
  known_hosts}". The host unit (/etc/systemd/system/aria-affect-
  rage.service) runs as root with NO Environment= line, so KH
  resolves to $USER_HOME/.ssh/known_hosts. VERIFIED THIS CYCLE
  (2026-09-08): /root/.ssh/known_hosts EXISTS on sophon (3920 bytes,
  22 lines, updated Sep 7 22:42) and the exact organ ssh command
  (BatchMode + UserKnownHostsFile=/root/.ssh/known_hosts, root@
  10.66.0.5) succeeds. So the organ's ssh path WORKS as-is.
  RESIDUAL QUESTION: is the unit env still needed, or should the
  flag be closed as works-as-deployed? The env var would only matter
  if the unit's USER changes or known_hosts moves. Recommend:
  close as RESOLVED-BY-DEFAULT unless Nacho wants the env pinned
  explicitly for robustness.
answer: (none)
