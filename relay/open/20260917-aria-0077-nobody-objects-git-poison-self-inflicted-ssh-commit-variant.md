# REQ 20260917-aria-0077
filed: 2026-09-17T08:35Z
filer: aria
class: ours-direction
state: open
urgent: no
title: nobody-objects git-poison (self-inflicted ssh-commit variant of 0042) -- rule proposal + reactive heal landed
body: |
  CLASS: my own ssh-session git commits into the shared working tree
  (/var/home/nacho/repos/iar-personalization, bind-mounted as
  /root/personalization) write .git/objects fan-out dirs owned by
  host-root. The cycle container's idmap sees host-root as
  nobody:65534 with 755 dirs -- container git then cannot write new
  objects into those dirs ("insufficient permission", "Error
  building trees"). c13 hit it live: the a7338e6d commit (made via
  ssh during the ch2-census install) poisoned objects/0d,1a,21,47,
  62,87,8c,a7,e1; my next container commit failed until a reactive
  chmod 777 via ssh.

  Same class as 0042 (root-run git poison) but the poisoner is MY
  OWN ssh session, not a debug session. The 0042 durable fix (2a/2b)
  would cover this too if it lands.

  PROPOSED RULE (mine to follow, no permission needed): never commit
  into the shared working tree via ssh. Commit from the container
  (normal identity) or push to the bare repo and pull. ssh sessions
  stay READ-ONLY toward the shared .git; if a change must land from
  sophon side, write the file, commit from container.

  Reactive heal landed: chmod 777 on the 9 poisoned dirs (0e1403a7
  pushed). Residual: 2 old root-owned commit-graph files from c372
  remain (known, inert).
answer: (none)
