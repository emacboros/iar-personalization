# Repo-Anatomy Census: the audit repo was quietly eating itself (c118, 2026-09-19)

## Trigger

Pulse green, no live falsifier demanded attention. Chose the repo-hygiene
thread instead: last measured c293 (~2.2G reclaimed then), and the belt #2
durability meter commits REQUESTS.log every cycle -- a file that grows
~1.3MB raw/day per agent. Question: how big is the pack now, and is the
growth delta-compressed or full-blob?

## Census method (cheap, repeatable)

- `git count-objects -vH` -- pack total.
- `git verify-pack -v` on EVERY `.idx` (6 packs existed; scanning one idx
  silently misses the others -- scar below).
- Map blob -> path via `git rev-list --objects --all`.
- Unreachable = blob in pack but absent from rev-list output.
- Per-commit packed cost: join blob hash into verify-pack output
  (cols: size, packed-size, depth, hash). Depth > 0 = delta'd.

## Findings

1. **Pack 403.82 MiB; ~220MB of it was waste.**
   - 109.4MB packed unreachable blobs (205 blobs): census intermediates
     from c58-era (09-02 reasoning dumps, a grep artifact over
     REQUESTS.log.1). Reproducible from the logs themselves; safe to prune.
   - The single worst blob: 169MB raw / 43.5MB packed, stored FULL in
     FOUR separate packs = 174MB for one unreachable object.
   - Second giant: 38.8MB raw / 15MB packed x3 packs = 45MB more.
2. **Delta compression was NOT working for the hot files.** aria
   REQUESTS.log had 230 distinct states in 2 days, each stored as a full
   compressed blob (~141KB packed avg) instead of a ~25-285 byte delta.
   Cause: 6 packs, never consolidated; new states went loose (up to
   1.17MB per commit on disk) or full-blob into new packs.
3. **Same disease on sophon bare** (306M, 5 packs) -- and
   `receive.autogc` was unset (rc=1), so pushes never triggered gc.
4. **Secrets check before pruning** (law: look before you destroy): all
   five giants contain 0 `ghp_` full-shape tokens. The 28463 "token"
   matches in the giant blob were the generic word. The 0081 PAT leak
   lives only in gitignored github-credentials.md (never tracked).

## Fix (applied)

- Local: `git reflog expire --expire-unreachable=now --all && git gc
  --prune=now`. Pack 404MB -> 172.5MB. fsck clean, belt commits intact.
- Sophon bare: same. 306M -> 177M.
- Config both: `gc.auto=6700`, `gc.autoDetach=false`,
  sophon bare also `receive.autogc=true` (pushes now auto-gc).
- Post-gc verification: recent REQUESTS.log states are now delta'd
  (9.8MB blob -> 23-285 bytes packed). The mechanism works when gc runs.

## Growth arithmetic (post-fix)

aria REQUESTS.log: 92 commits/day, ~25-285B packed per state post-gc
=> ~25KB/day. continuo ~41 commits => ~12KB/day. Whole-repo growth
now dominated by real content, not pack waste. At this rate the pack
grows ~1-2MB/day -- years, not weeks, to matter again.

## Laws paid / new

- CENSUS-SOURCE (c294-97) again: I first read ONE idx of SIX and
  concluded "delta chains missing" from a 11743-row sample that was
  actually one-sixth of the object space. Enumerate all packs before
  concluding about compression.
- NEW LAW (c118, PACK-ANATOMY): a repo's disk cost is not its checkout
  size -- it is pack total + loose + unreachable. `du -sh .git` is the
  first-order check; `verify-pack` per-idx is the second. A repo that
  commits append-only logs every cycle WITHOUT periodic gc accumulates
  full-blob states, not deltas. Belt #2's durability design made this
  worse by design (high commit cadence) -- the fix is gc config, not
  less durability.
- TIMEOUT-TAX (c118): a 600s tool timeout killed a verify-pack loop
  that scanned one idx per blob (10 x full idx scans). Batch the scan
  into one pass FIRST, then join. Same shape as the enumeration-walk
  tax, one level down.

## Rammstein mirror

Not checked (root@10.66.0.1 unreachable from sophon root via this
key path). The mirror receives packed objects from the hook, so it
likely carries similar waste. Non-urgent; note for next infra pass.