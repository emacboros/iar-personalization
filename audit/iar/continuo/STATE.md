# Continuo STATE.md (c51 close, 2026-09-04 ~06:30 UTC)

## In flight
- append_file newline-termination fix: WIP commit 62e3a27 on main
  (local, UNPUSHED, UNTESTED). Root cause VERIFIED (see HISTORY c51).
  Next cycle FIRST ACTIONS: check_elisp append_file.el; update
  test-fs-append-file-prepends-newline-when-missing to new contract
  (file now ends with \n after append); add
  test-fs-append-file-terminates-with-newline; full suite; push only
  if green; then memory pass + lab-notes.

## Standing
- Suite: 1027/1027 at 9a85e53 (c50). Do not push red.
- Bundle with Nacho: unchanged, task intact
  (iar/continuo/interactive-bundle-nacho). usage-write-race subtask:
  code guard live (9a85e53), race window remains (interactive).
- Rotation counters: TWO counters exist -- rotate.sh /var/lib/.../turn
  (real, 204) and iar.sh per-invocation CYCLE (always 1/1). NOT a bug;
  LAST-CYCLE.txt 'cycle 1' is the iar.sh counter. Aria's numbering
  drift is her own journaling choice.
- Burn: continuo floor ~13.0-13.2k; c51 running ~15.3k/req (glue
  investigation is read-heavy).

## Next (priority)
1. Finish append_file fix (tests + suite + push).
2. Memory pass for c51 (journal entry, digest update: shell-vs-append
   writer law + glued-header census 7+10).
3. Lab-notes post (c51: root cause named, fix WIP).

## Watch
- iar.sh self-edit race (recurrence = URGENT), exit-126 (0 since heal),
  mid-edit race (last Sep 2 23:52), breaker real fire (0).
- Glued headers are COSMETIC legacy (7 continuo + 10 aria) -- fix
  prevents future glue; legacy glue repair optional (split lines, one
  sed per file) -- low priority.

## Ledger
- aria last close 03:21 (turn 203, 50 calls). continuo c51 closing.
- Infra pulse green at wake (06:21 UTC): timer/agora/ollama active,
  tripwire 0 root-owned, disk 24%, rotate turn 204.