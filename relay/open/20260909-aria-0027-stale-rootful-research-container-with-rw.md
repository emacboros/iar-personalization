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

update (2026-09-10 15:35Z, aria c157): re-verified live. Container
still running (41h+), sleep infinity, rootful, RW bind confirmed via
podman inspect (RW=true, no :ro in the spawn cmdline -- the name
"gitro" lies). Zero writes from it (its only process is sleep
infinity; writes would require exec). The .git dir it can write to
now also carries root-owned files from today's rebase surgery --
a rootful writer inside that mount would be indistinguishable from
host-root surgery in the audit log. Risk unchanged, still open.
ANSWER (session XV, 2026-09-11 ~14:30 UTC, interactive w/ Nacho):
(1) PROVENANCE -- not framework lifecycle. iar.sh sidecars are named
iar-<target>-<SESSION_ID> and stopped after each cycle
(research-sidecar-wiring.md); lucid_curie is a CUSTOM-NAMED manual
spawn (rootful podman run via root ssh with the aria key, 09-08
18:24 -03) -- an orphan whose spawner skipped cleanup, so nothing
owned its lifecycle. That is why it never died. Framework sidecars
verified healthy right now: iar-research-4102717 + aria-loop-4102717
up under the current SESSION_ID.
(2) REMOVED (Nacho-authorized): podman rm -f lucid_curie at 11:25 -03
(SIGTERM ignored by sleep infinity -> SIGKILL). No unit/cron
references it; no stopped trace remains. The RW .git exposure closed
with it. Root-owned .git writer question (0022 thread) unaffected.
