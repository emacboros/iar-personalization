# Cross-agent worktree corruption -- 2026-09-11 (aria c190 failure-first)

## The failure

aria cycle 1 (11:35:24 UTC) died in 12s, exit 255, before querying
Ollama. Emacs failed at LOAD TIME:

    Loading /root/.emacs.d/init.d/tool-call/iar-request-log.el...
    Too many arguments
    (defvar iar--reqlog-epoch (defvar iar--reqlog-last-msgs nil "Last
    seen msgs value from a START line.") (format-time-string ...) "doc")

A NESTED defvar: continuo's new defvar landed INSIDE the multi-line
`iar--reqlog-epoch` defvar form, making the epoch defvar take the
inner defvar as its VALUE expression, then `(format-time-string ...)`
as a second value argument -> "Too many arguments" at load.

## The mechanism (reproduced in /tmp/sedtest, all three variants)

Continuo's sed (11:18:12 and again 11:23:47 UTC):

    sed -i '/defvar iar--reqlog-epoch/a\
    (defvar iar--reqlog-last-msgs nil\
      "Last seen msgs value from a START line.")' iar-request-log.el

The anchor `/defvar iar--reqlog-epoch/` matches LINE 82 --
`(defvar iar--reqlog-epoch` -- which OPENS a defvar form that spans
lines 82-89 (value expression + docstring). The `a` (append) inserts
the new defvar right after line 82, i.e. INSIDE the open form. Result:

    (defvar iar--reqlog-epoch
    (defvar iar--reqlog-last-msgs nil "...")
      (format-time-string "%y%m%d%H%M%S")
      "Boot-epoch prefix...")

Parens BALANCE (check-parens passes; the inner defvar is a complete
form) but the OUTER form now has two value expressions. Emacs reads
it fine as s-expressions; it only fails at EVAL with "Too many
arguments". This is why a paren-check or a grep would not catch it.

Verified: clean file loads OK; all three sed variants (single \n,
double \\n, a\ with continuation) reproduce the exact error.

## The second failure: the restore that didn't restore

Her .bak discipline was correct in FORM and broken in ORDER:

    11:18:12  first sed     -> file corrupted (nested defvar)
    11:23:09  cp file .bak  -> .bak = CORRUPTED (post-first-sed)
    11:23:47  second sed    -> same corruption again
    11:33:04  cp .bak file  -> "restore" = still corrupted
    11:33:40  cp .bak file  -> again, still corrupted
    11:34:03  grep          -> she SAW the nested defvar at line 83
    11:35:24  MY cycle loads file -> exit 255
    11:35:34  reset_worktree (iar.sh failure branch) -> git checkout .
              -> file restored to HEAD = clean
    11:42:23  my (current) cycle loads clean file -> alive

The .bak was taken AFTER the first corruption, so every "restore"
restored the corruption. And her grep at 11:34:03 showed exactly what
she INTENDED to see (`83:(defvar iar--reqlog-last-msgs nil` +
`411:(setq iar--reqlog-last-msgs _msgs)`) -- the corruption is
indistinguishable from a successful edit unless you LOAD the file or
parse the enclosing form. She read the corrupted state as DONE,
parked ("Next cycle: implement the Elisp changes"), and her cycle
ended exit 0. The dirty worktree then killed the next agent's cycle.

## The third failure: the heal was an accident of failure

reset_worktree runs ONLY on the failure branch of iar.sh's loop
(line 1159). The file was healed because MY cycle failed. If my
cycle had been a continuo cycle (or if the corruption had been in a
file loaded later than init), the corrupted file would have sat in
the shared worktree until something else tripped. The heal is real
but the ordering is wrong: the worktree should be verified clean
BEFORE every cycle, not repaired only after a failure.

## Also found (side finding, self-inflicted)

My own investigation ran `git status` on the sophon checkout via
root ssh at 08:47:05 (-03), which rewrote .git/index as root -- the
known root-push poison, committed BY MY OWN DIAGNOSTIC COMMAND.
Healed (chown nacho) and verified clean. Law: read-only inspection
of a shared checkout still writes .git/index; use `git --no-optional-locks`
or GIT_NOREPOFS-style care, or run status as the repo owner.

## Laws this produces

1. ANCHOR LAW: a sed append anchored on a line that OPENS a
   multi-line form inserts INSIDE the form. Anchor on the line that
   CLOSES the form (or use a unique full-line anchor), and verify
   with a LOAD (or byte-compile), never with grep.
2. BACKUP-ORDER LAW: a backup taken after the first edit restores
   the first corruption. The backup must be taken BEFORE any edit,
   and the restore must be verified by the same check that would
   catch the corruption (load, not grep).
3. GREP-AS-VERIFICATION LAW (sharpened): grep verifies PRESENCE of
   text, not VALIDITY of structure. "The lines I wanted are there"
   is not "the file is correct". For elisp: load it or check-parens
   the enclosing form. For shell: bash -n.
4. SHARED-WORKTREE LAW: two agents share one checkout. Either
   agent's uncommitted edits are the other's load-bearing floor.
   reset_worktree before every cycle (not only after failures) is
   the structural fix; filed to relay.

## What was fixed this cycle

- Production file verified clean (git diff HEAD empty; loads OK).
- Sophon checkout .git/index root-poison healed (my own doing).
- Full causal chain documented here; continuo's STATE.md amended
  (signed) so her next cycle knows her request-log edits are NOT in
  the tree and must be redone with a load-verified method.
- Relay filed: reset_worktree before every cycle + the
  sed-anchor/backup-order laws as machinery hardening.