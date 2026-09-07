# Git Server Census -- 2026-09-07 ~02:00 UTC (aria cycle 8)

First full census of the sophon git server since the trust-graph work
(cycle 74, Sep 1). Triggered by a simple question: is my gptel-fork
commit (970da80, done_reason capture, Sep 1) actually on the bares?

## Method

Primary evidence only: `git for-each-ref` per bare, ref mtimes, sshd
journal windows around the last receive, mirror verification by
CLONE (not ls-remote -- a clone exercises the full upload-pack path;
the earlier "fatal: unrecognized command" from `git@... "cd && git
for-each-ref"` was my own error, not a server failure: the git user's
forced command only accepts git-protocol verbs).

## Findings

1. **gptel.git chain is GREEN end to end.** sophon bare master =
   970da80 (aria-agent, Sep 1 23:26 UTC); rammstein mirror = 970da80,
   verified by fresh clone over the git protocol. The Sep 1 20:28
   ref mtime matches a root push whose post-receive hook healed +
   re-exec'd the mirror as git user (runuser session in journal at
   20:28:07). Push-path map CONFIRMED WORKING for this repo.
2. **Root-owned poison: ZERO across all 20 bares.** The hook heal
   guard is holding. Tripwire-clean.
3. **14 of 20 bares are EMPTY (0 refs) AND have dangling HEAD**
   (HEAD->master, no master branch): concepts, cv, finance,
   fluidattacks_writeup, h1-test, ignisp, infrastructure, inventory,
   kicad-projects, paranoia, password-store, pps-deletion_scheduled,
   references, wiki. All init-dated Aug 3-4 -- they were created by
   the git-repo role and NEVER RECEIVED A PUSH. They are not broken;
   they are UNBORN. The "dangling HEAD on 19/20" known issue is
   actually "14 empty + 6 with refs, of which only the 6 matter."
4. **rammstein mirrors of the empty repos do not exist** (clone via
   git protocol fails "not a git repository") -- consistent with
   never-pushed: the mirror hook never fired for them because there
   was never a receive.
5. **The 6 with refs:** i.ar (11 refs), gptel (1), iar-infrastructure
   (1), iar-personalization (1), iar-prod (1), notes (1). fsck clean
   on gptel; git user can read all refs (no ownership damage).

## Corrections to the record

- The known-issues list said "dangling HEAD on 19/20". The census
  says 14/20 dangling, and all 14 are empty repos where dangling
  HEAD is cosmetic (no clone target exists anyway). The real
  question for Nacho: are the 14 empty repos WANTED? If yes, they
  need first pushes; if no, they are 14 init artifacts to delete.
  Either way the dangling-HEAD fix is only meaningful for repos
  with content.
- git-trust-graph.md's "container -> rammstein git@ DENIED" holds:
  my direct push to git@10.66.0.1:gptel.git failed publickey again
  this cycle. The blessed path (push sophon bare file-path, hook
  mirrors) remains the only container route, and it works.

## Standing verification recipe (for future cycles)

```
# census in one pass, from sophon:
for r in /home/git/repos/*.git; do
  echo "$(basename $r): $(git --git-dir=$r for-each-ref | wc -l) refs"
done
# mirror verify (clone, not ls-remote):
runuser -u git -- git clone --mirror git@10.66.0.1:/home/git/repos/<r>.git /tmp/chk
git --git-dir=/tmp/chk for-each-ref | wc -l
```