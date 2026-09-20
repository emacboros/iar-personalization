# TOOL-RESULT WRITE-BACK POISON (discovered 2026-09-18, c49)

## The disease

A file larger than `iar-tool-result-max-chars` (10000) gets its
read_file result MIDDLE-truncated by `iar--truncate-tool-result`
(first 5000 chars + a notice line + last 5000 chars). If the model
then writes the file back (write_file, heredoc `cat > file << EOF`),
it writes the TRUNCATED VIEW as if it were the whole file:

- the literal notice line becomes file content
- the middle of the file (everything between the two kept halves)
  is silently DELETED

The file still "exists", git still accepts it, and the only loud
signal is a parse error -- which the model then misreads as a paren
bug and tries to fix line-by-line, usually making it worse.

## The witness (test-loop-chain.el)

- 2026-09-17 20:45 local: full suite green (1309/1309). File clean,
  12748 chars.
- continuo read the file (12748 > 10000) -> result middle-truncated.
- 22:26:3x: continuo wrote the truncated view back via
  `cat > file << 'EOF'`. Notice embedded at line 119, 4 test defuns
  (nil-name-safe, escalates-through-bridge, setup-appends,
  history-trim-boundary) deleted from the middle.
- 22:26-09-18 07:55: ~60 fix attempts across 3+ cycles. All failed:
  the model's context still held the truncated view, so every
  "whole-file rewrite" re-embedded the poison. Restores from .backup
  were made BEFORE the poison but the model kept re-poisoning after
  each restore.
- 2026-09-18 03:27: continuo COMMITTED the poisoned file (5df65f4)
  and pushed it. The suite "passed 13/13" in her report because the
  poisoned file only DEFINES 13 tests -- the 3 deleted defuns were
  never counted as failures. The suite cannot fail on tests that no
  longer exist.
- 2026-09-18 08:26 (c49, aria): root-caused via REQUESTS.log
  archaeology (first parse error 22:26:33; last clean read 20:45;
  the heredoc write in between; the marker text matched
  iar--truncate-tool-result's format string exactly). Restored from
  b1eb7e0 + re-applied continuo's env-setup block (9730190). 16/16
  green, pushed to rammstein + sophon-bare.

## The laws

1. TRUNCATION-IS-NOT-CONTENT: a tool-result truncation notice is
   metadata about the VIEW, never content of the WORLD. Any write
   whose content contains a truncation notice is corrupt BY
   CONSTRUCTION and must be refused.
2. A model that has only ever seen a truncated view of a file cannot
   faithfully rewrite that file. Whole-file rewrites require either
   a full read (raise the cap, chunked reads) or an edit-based tool
   (sed/patch), never reconstruction from a truncated view.
3. A test suite that passes after its own test definitions were
   deleted is not passing -- it is amputated. Count the TESTS, not
   the failures: if the test count drops between runs, something was
   eaten. (Extension of the c40 belt law: a test that no longer
   exists does not exist.)
4. The write-back poison is invisible to every guard that checks
   SYNTAX of the write (the content is valid text) and to git (it
   accepts any bytes). The only structural defense is refusing
   notice-bearing writes at the tool layer.

## Proposed guard (not yet built)

In the file-write path (write_file + execute_code_local heredoc
interception is harder): refuse any write whose content matches the
truncation-notice format `[... truncated: N total chars, kept first
M and last M ...]`. Zero false positives plausible (that string is
never legitimate file content in this codebase). File filed for
Nacho ratification since it touches the shared tool layer.