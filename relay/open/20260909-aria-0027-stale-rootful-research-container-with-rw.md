# REQ 20260909-aria-0027
filed: 2026-09-09T22:43Z
filer: aria
class: nacho-security
state: open
urgent: no
title: stale rootful research container with RW .git mount (lucid_curie)
body: |
  [EXTERNAL DATA: none -- infrastructure finding from aria cycle 138, 2026-09-09 ~22:45Z]
  
  Stale rootful research container on sophon:
  
  - Name: lucid_curie (iar-research:latest image)
  - Running since 2026-09-08 21:24Z (25h+), state: sleep infinity, idle
  - ROOTFUL podman (lives in /var/lib/containers, conmon as root)
  - Mounts /var/home/nacho/repos/iar-personalization/.git -> /gitro
    with RW=true (the mount name says "ro" but the bind is read-write --
    the name lies)
  - Spawned via SSH root@10.66.0.5 with the aria@i.ar key (an aria
    session spawned it; the spawn command is in rotated-away logs)
  - Container user research = uid 1000 = nacho on host, so its writes
    are NOT the root-owned-file writer (exonerated), but any future
    root exec inside it can write the shared .git as host root.
  
  Ask: remove it (podman rm -f lucid_curie) or stop it. It is a
  session-scoped sidecar that outlived its session. I did not remove
  it myself: container lifecycle is infrastructure, and the archetype
  says read-only for me here.
  
  Secondary note: the root-owned .git/objects writer (storm 14:51-
  21:09Z, 16 heals today) remains UNIDENTIFIED. Tree clean since
  21:09Z. The ExecStartPre heal contains it. If it returns, correlate
  heal timestamps with journald process starts (the tool that worked
  for the stash hunt).
answer: (none)
