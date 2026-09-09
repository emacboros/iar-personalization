# REQ 20260909-aria-0022
filed: 2026-09-09T13:12Z
filer: aria
class: nacho-arch
state: open
urgent: no
title: root-owned audit-file poisoning: writer unidentified, heal gap
body: |
  Root-owned audit-file poisoning: writer unidentified, heal gap real.
  
  WHAT: continuo audit files (REQUESTS.log, USAGE.log, LAST-CYCLE.txt) +
  aria's files + .git objects went ROOT-OWNED on the sophon working
  checkout between ~09:58Z and 12:04Z today (2026-09-09). 349
  "Permission denied" write-failures across 4 cycle runs. continuo's
  08:32 -03 run lost its last 5 request traces (~1.27M tokens of
  context) to the blindness. The ExecStartPre heal cleaned them 3x
  (06:28/08:32/09:04 -03) and they re-poisoned; the 12:04Z heal stuck.
  
  RULED OUT: cycle containers (rootless podman -- verified container-root
  maps to host nacho via live uid-probe), dashboard generator (root but
  writes /var/lib/caddy only), fleet-feed (root, /var/lib/aria-fleet
  only), affect organs (nacho), oracle (caddy), git post-receive hook
  (heals bare repo only). PARTIALLY EXPLAINED: eye-check REPORT.md +
  ledger root-owned = my c122 live-fire ran the unit as root (no User=
  in aria-eye-feed.service) -- my instrument poisoned the tree it
  watches. .git objects = known root-push class. The audit-file writer
  remains unidentified after ~25 probes.
  
  THE GAP: the heal is (a) start-only -- a mid-cycle poisoning lives
  until the next service start, and (b) chown-only for the audit tree
  (chcon -R touches .git dirs only). A root-owned REQUESTS.log silently
  kills the request trace (the meter survives in USAGE.log when it can
  open, but the debug trace is lost).
  
  ASK (nacho-arch class): host-side watch on the personalization tree --
  auditd rule or a 1-min inotify loop logging any chown to root on
  /var/home/nacho/repos/iar-personalization/audit/**. With the writer
  named, the fix is one line. Without it, the heal keeps paying a tax
  it cannot explain.
  
  WATCH RECIPE (if you want the cheap version first):
    auditctl -w /var/home/nacho/repos/iar-personalization/audit -p wa -k aria-audit
  then ausearch -k aria-audit after the next poisoning window.
answer: (none)
