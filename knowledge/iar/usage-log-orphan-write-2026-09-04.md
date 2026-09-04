# USAGE.log orphan-write race -- root cause + eraser (c45/c46)

## The race (verified on epoch 260904022143 = continuo c40)

USAGE.log is a TRACKED file in iar-personalization, written by
`iar--usage-write-log` in `kill-emacs-hook` (iar-tool-call.el:214).
The cycle's memory pass commits audit files BEFORE exit; the
close-write lands AFTER that commit. Sequence:

1. c40 memory pass commits 714a241 (02:33:12). USAGE.log captured
   only to 02:09:17.
2. c40 exits 02:33:26; kill-emacs-hook appends the 02:33:26 line.
   On disk, UNCOMMITTED (an orphan write).
3. c41 boots 02:42, pulls (no-op; dirty tracked file survives).
4. c41's memory pass runs `git add -A audit/iar/continuo/ &&
   git commit` -> 681c1a6. c41's tree snapshot of USAGE.log lacked
   the orphan line (c41 was the paren-bug cycle; checkout/stash
   exploration in its window restored the tree from a pre-write
   commit). The commit PUBLISHED the line-less version.

The eraser is the most ordinary command in the house. Mechanism
class: a tracked file written post-commit by an exit hook is one
commit away from silent erasure at all times.

## Second instance (found live, c46)

c45 restored the missing line by append_file -- WITHOUT a trailing
newline (the file ended line-less at 03:51:45 with no \n). c45's
own close-write (04:09:09) then GLUED onto it:
`...model=glm-5.3-flash[2026-09-04 04:09:09] ...`. Root:
`iar--usage-write-log` appends with no newline guard. Fixed by
hand (byte split), verified 84/84 lines well-formed.

## Fix options (interactive, Nacho -- subtask
## iar/continuo/interactive-bundle-nacho/usage-write-race)

1. Move the write into iar-run-cycle BEFORE kill-emacs
   (post-summary, pre-exit).
2. iar.sh writes the line from the "Tokens:" stdout after emacs
   exits (sophon journal proves those values complete and honest).
3. Untrack USAGE.log (cheapest; loses commit history).

## Census law (hardened c45, applied c46)

Substring greps for "REQ <ep>-N PARSE" match START lines whose
specs QUOTE the pattern -- every cycle that greps the log inflates
it. Correct census: line-start anchor (^\[[^]]*\] REQ <ep>-N PARSE)
+ timestamp window + dedup by id. All 11 epochs of 2026-09-04
reconcile under it (000105 pre-1afc21a: no tokens_in except
id-125; 010226 real 6,155,287 vs poisoned 260,929,102,797).

## Verification law (c46)

Verify the CLAIM against the world, not the receipt in the record.
The c46 close almost preceded reading the working-tree diff -- the
diff held the second instance. A named mechanism is not a clean
file; check the file.
