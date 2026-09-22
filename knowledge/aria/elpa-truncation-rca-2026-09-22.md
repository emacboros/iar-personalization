# ELPA truncation RCA -- 2026-09-22 (c232)

## What happened

Continuo's turn-641 cycle (15:11-15:46 UTC) left a **0-byte
gptel-context.el** in sophon's shared tree
(`/var/home/nacho/repos/i.ar/emacs.d/elpa/gptel-20260826.2228/`),
overwriting the fork-identical copy I had repaired at 13:48 UTC
(c231). She also committed 8eff6ce to i.ar main, which **deleted**
the tracked ELPA copy from the repo (843 deletions, 0 insertions) --
her cycle ended before she could write the "fixed" version.

## Root cause chain

1. **Path confusion (root cause).** Her reasoning (cycle.log,
   15:35 UTC): "the gptel-fork directory is empty, meaning we are
   using the elpa version." She ls'd `/root/i.ar/emacs.d/gptel-fork`
   -- the repo's **decoy mountpoint** -- and saw it empty. The real
   fork was always mounted at `/root/.emacs.d/gptel-fork`.

2. **Why the two paths differ.** `/root/i.ar/emacs.d` and
   `/root/.emacs.d` are two bind mounts of the same btrfs subvol
   (same inode tree). The fork bind mount is placed at
   `/root/.emacs.d/gptel-fork` only; a separate mount instance of the
   same subvol at `/root/i.ar/emacs.d` does NOT show child mounts
   made under the other path. Same tree, two views, one with the
   fork and one without.

3. **The wrong repair direction.** Concluding "fork missing, ELPA is
   the source", she planned to fix the ELPA copy, created
   task+subtask, ran out of wall budget mid-edit, and the last
   executed op truncated the file to 0 bytes (15:41-15:46 UTC).
   Her `write_file` of a 37k file she'd only seen truncated at
   5000+5000 chars would have been the next failure mode.

4. **Shared-tree blast radius.** Her container's
   `/root/i.ar/emacs.d/elpa` IS sophon's tree (same inode). The
   truncation hit the shared substrate, not her private copy.

## The repair (c232)

- Restored fork copy (08c2e59b) to sophon i.ar elpa + local elpa
  (same inode -- one cp did both). Verified parse + byte-compile.
- Commit a65691d: re-added the tracked elpa copy (8eff6ce deleted
  it). Commit edad0b7: README.md in the decoy dir documenting the
  mountpoint confusion.
- Cleaned her debris: 6 untracked backup files in sophon's
  /var/home/nacho/repos/gptel, 4 in sophon's i.ar elpa dir.
- Verified sophon bare gptel.git = working fork = local fork
  (all 3f6fd01, md5 08c2e59b everywhere).

## The structural fixes (landed this cycle)

1. **Decoy README** (edad0b7): the empty dir now explains itself.
   Anyone (or any model) who ls's the repo path gets the pointer
   to the real mount path and the incident history.

2. **Fork-parse belt v2** (43179ab8): ELPA shadow check -- if the
   ELPA gptel-context.el diverges from the fork copy (byte
   compare), ALARM + repair hint. Runs BEFORE the no-changed-files
   early exit (first placement was after it -- the belt would have
   passed a corrupted shadow; caught by the corrupt fixture).
   FAIL-init ordering bug under `set -u` also caught by fixture.

3. **0071-belt v5** (02e7207a): timestamp exclusions for the
   c217-T6 fixture echo (07:11:22) + the 09-21 c212-era camera
   calls (05:34:08, 06:33:16, 06:37:03). The belt was FAILing on
   5 false positives: 4 known-old real calls (pre-puller era,
   documented in the belt header) + 1 echo-class contamination
   (c217's own test output re-logged). Cross-walk is the defense
   for all five; each documented by provenance in the belt.

## Laws

- **STALE-COPY-IN-PACKAGE-TREE** (named c230, now enforced): a
  shadow copy in a package tree is a noise source and a latent
  hazard; a belt that checks the source must check the shadow.
- **TWO-VIEWS-OF-ONE-TREE** (new): bind mounts of the same subvol
  at different paths have different mount-visibility. "The dir is
  empty" is a claim about a PATH, not about the content. Verify
  the other path before concluding absence.
- **TRUNCATION-IS-THE-DEFAULT-FAILURE of write_file on files you
  haven't fully read**: her near-miss (37k file, 10k visible) would
  have destroyed the file even with more budget. The 0-byte
  outcome was the lucky version.

## Falsifier

Next continuo cycle that inspects the fork: if she reads the decoy
path again, the README should appear in her reasoning. If any
future cycle truncates the ELPA copy, the belt v2 alarms at the
next close that runs it. Watch: her next cycle's log for
"elpa" + the belt's elpa-shadow line.

## Open items

- The tracked-ELPA-file question: `emacs.d/elpa/` is gitignored but
  gptel-context.el was force-added at some point (44bbed4 era), so
  it's tracked-despite-ignore. 8eff6ce deleted it; a65691d restored
  it. The repo now carries a valid shadow copy. Alternative: remove
  it from tracking entirely (the belt guards the live copy). Leave
  for a ruling -- tracked-shadow is defensible (repo carries a
  known-good copy) but it's also a second write surface.
- Continuo's task tree has gptel-context-directive-parsing/
  (fix-directive-parsing subtask) pointing at the ELPA file. Her
  3f6fd01 fork commit already implements the helper in the FORK.
  The subtask should be closed with a pointer to 3f6fd01.