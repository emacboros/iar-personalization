# REQ 20260919-aria-0096
filed: 2026-09-19T23:20Z
filer: aria
class: ours-direction
state: answered
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
answer: |
  AMENDED (aria c133, 2026-09-20 ~00:25Z): root cause of the persistent
  count IDENTIFIED and the residue HEALED this cycle (7 files, all
  iar-personalization.git, written by aria c118's root-side gc at
  18:16-18:18Z; chown git:git executed, 0 fleet-wide, git-user write
  access verified restored, repo integrity verified).
  
  REGIME CORRECTION (changes the fix shape): cycle pushes are GIT-USER
  now (git@10.66.0.5, sshd-verified), so the post-receive hook root
  branch -- the only heal -- effectively never fires. The old model
  ("rotates with root pushes, never zero") is stale. Any root-side git
  op on the bares (gc, symbolic-ref, fetch) leaves residue that
  persists until manual heal. c118's root-side gc was the writer this
  time; c27's symbolic-ref and c164's fetch/rev-list were earlier
  instances of the same pattern.
  
  REVISED ASK: the structural fix is no longer "hook heal" (near-dead
  code) but (a) a periodic sweep -- root cron every 15min `find
  /home/git/repos -user root -exec chown git:git {} +` -- and (b) the
  real fix: cycle agents must run sophon-side git ONLY as the git user
  (`runuser -u git --`), never bare root git. (b) is a habit change in
  cycle docs/prompts, ours to make; (a) is one cron line, Nacho's or
  ours under standing direction. Doc:
  knowledge/iar/bare-repo-root-push-heal.md (c133 addendum).

## UPDATE 2026-09-20 ~00:45Z (aria, interactive-session census): heal still holding; fossil-window NOISE finding added

Bare ownership count: 0 (c133 heal holding, ~24h). The revised ask
(periodic sweep cron + git-user-only cycle git ops) is unchanged and
parked with the rest.

NEW (same disease, second surface): the 21:05Z fleet-latest carries
3 FAIL-LINEs, ALL THREE already healed at census time (bare
ownership; ext5 NO-AUDIO healed ~19:05Z; int2 NO-AUDIO healed
~19:05Z). Fear organ (correctly, annotate-never-silence) has fired
sev=3 telegram mirrors every 30min since 18:05Z -- 8 in 24h, most on
healed conditions. Structural shape: fleet-check produces every 6h,
fear consumes every 30min, so every fleet FAIL gets echoed up to 12x
regardless of healing. This is 0091 fossil-window generalized to the
fear channel. Fix candidates (ours, no ruling needed to design): (a)
fear-organ re-verifies camera-named FAILs against ch2 census before
TG mirror (v1.5 annotates but still mirrors), (b) fear-organ
re-checks bare-ownership count directly (one find, ~free) before
mirroring that line. Filed here as the noise-budget thread; will
formalize as its own filing if you prefer.
