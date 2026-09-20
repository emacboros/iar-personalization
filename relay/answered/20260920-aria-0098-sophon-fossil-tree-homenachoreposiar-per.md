# REQ 20260920-aria-0098
filed: 2026-09-20T13:24Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: sophon fossil tree /home/nacho/repos/iar-personalization -- second TWO-TREES strike (c153)
body: |
  TWO-TREES TRAP, second strike (c153). The sophon worktree at
  /home/nacho/repos/iar-personalization was a fossil: HEAD d627e87
  (09-07), origin=github, 1024 commits behind the sophon bare. Any
  scheduled instrument (fleet-feed) running from it would execute
  v2.26-era fleet-check -- no 1d block, no ATS-PARTIAL guard. Repaired
  c153 13:21Z: fetched bare main via nacho's aria_ed25519 key into a
  temp branch, ff'd main, worktree now = bare = local at 9f76f3b5,
  fleet-check v2.28 verified (md5 a79bca89).
  
  ASK (extends 0096 regime correction): (1) delete or redirect the
  /home/nacho/repos/iar-personalization fossil -- it is a live hazard
  for root-run scheduled jobs; (2) note: root fetch into that tree
  manufactured root-owned .git objects (healed by chown -R 13:23Z);
  pulse tripwire scans /var/home/nacho/repos only, so /home/nacho
  rot is invisible to it. Either add /home/nacho/repos to the tripwire
  or remove the tree. Also undiagnosed: root-key git fetch from the
  sophon bare hangs (ls-remote works); nacho key works.
answer: (none)

## ANSWERED 2026-09-20 ~22:40Z (interactive session, Nacho): fossil DELETED; tripwire already covers /home/nacho/repos

Ruling: "Delete, and add repos to the tripwire." Executed:
/home/nacho/repos/iar-personalization removed (was clean at 9f76f3b5 =
bare HEAD, nothing lost). Tripwire: aria-cycle.service ExecStartPre
ALREADY scans both /var/home/nacho/repos AND /home/nacho/repos (the
find line covers both paths -- verified live); no edit needed. The
remaining /home/nacho/repos trees (gptel, i.ar) are live worktrees,
not fossils; watch stays via the same tripwire. Filing CLOSED.
