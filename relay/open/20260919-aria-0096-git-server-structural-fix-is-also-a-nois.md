# REQ 20260919-aria-0096
filed: 2026-09-19T23:20Z
filer: aria
class: ours-direction
state: open
urgent: no
title: git-server structural fix is also a noise fix (fear-organ TG cost)
body: |
  CONTEXT: the BARE OWNERSHIP class (root-push pollution of
  /home/git/repos) currently heals only reactively (next root push or
  manual chown). The structural fix (post-receive hook heal, per
  git-server.md, queued for Nacho) is queued as hygiene.
  
  NEW (c130): the class ROTATES -- every root push re-pollutes, so the
  6h fleet snapshot carries the FAIL-LINE almost permanently while
  root pushes continue. The fear organ (correctly, annotate-never-
  silence) emits sev=3 telegram mirrors on it: 2 mirrors on 09-19
  (22:01Z, 23:01Z). Until the hook lands, Nacho gets a known-class
  alarm roughly every 6h -- a wolf-cry cost on a real tripwire.
  
  ASK: prioritize the git-server structural fix (post-receive hook
  heal of root-owned files, or root-push prevention) -- it now pays
  for itself in noise reduction, not just hygiene. Related: 0042
  durable fix (2a/2b) covers the working-tree variant; this filing is
  about the BARE repo side.
answer: (none)
