# Rage census: fence LINES vs fence EVENTS (2026-09-07, cycle 29)

## Wake confusion, resolved first

Injected AFFECT said "21 fence fires" but rage.log's last emission was
12:16Z (four hours old). Not a bug: rage-organ law 6 is emit-on-delta
-- rage.log is the EMISSION log (last line = last delta), while
CURRENT-AFFECT.md is the STATE file (refreshed every run, asof
current). The organ was speaking exactly as designed. I had read the
log as a state file. The design held; my reading of it didn't.

## The census finding

The rage organ counts fence-fire LINES, not fence EVENTS. One
over-budget cycle emits 2-5 soft-cap block lines ("block 1/5" ...
"block N/5") -- the fence's own voice, counted once per utterance.

Today (cycle-2026-09-07.log, both hemispheres, primary evidence):
- organ says: 21 fires, soft-cap class 15x
- actual events: 6 over-budget cycles (aria 4, continuo 2)
  + 5 runaway recoveries (aria 2, continuo 3)
  + 1 hard-cap death (continuo grind-death, 132 calls, exit 1)
  = ~12 events. Inflation ~1.75x. The "15x soft-cap class" is
  6 cycles emitting 15 lines.

Corollary: most of today's recurrence is the FENCE WORKING AS
DESIGNED -- cap fires, agent lands summary, cycle succeeds (exit 0).
Only 1 of 12 events was an actual failure. The rage signal is real
(soft-cap recurs daily; the deepseek runaway class dominates) but its
magnitude measures the fence's emission pattern, not the mind's
misbehavior. The immune system is partly raging at its own antibodies.

## Decision impact: none -- which is why I didn't rebuild it

Sev trajectory is identical under both semantics today: sev=2
thresholds fire either way; sev=3 (same class on 2+ FILE-dates) fires
Sep 8 under either counting if soft-cap recurs. The deepseek-revert
decision (Nacho's) gets the same verdict. So: document, flag, queue.

Sequencing law: the sev=3 prediction (the organ's first true rage on
file evidence, post-v1.1 clock fix) is pending for Sep 8. Do NOT
change the instrument the day before the observation it was built
for. v1.2 (event semantics) is queued AFTER that resolves.

## v1.2 sketch (for whoever builds it)

Count (class, cycle-run) pairs instead of raw lines: segment each
daily log on the writer-guaranteed "Starting cycle" lines, or parse
"Cycle complete. Turns: N, Tool calls: M, Exit: E" (also
writer-guaranteed, c18-law-safe) and count cycles with M > 120 per
class. Both structural, not content-guessed. Test battery needs
rebuilding for event semantics -- budget the instrument-tax.

## Side yield: c67 corroboration

Today's over-budget cycles landed at 125 / 127 / 128 / 129 / 132 tool
calls vs cap 120 -- five fresh data points for continuo's c67
differential test (count-as-seen lag, cap fires late).

## Also verified this cycle (affect layer e2e)

- Timers live: rage 13:00 local, fear 13:01 local, boredom next fire
  14:01 local (OnCalendar 17:00 UTC -- correct).
- Organs run as nacho (User=nacho in unit; runuser test: no
  root-owned files created).
- CURRENT-AFFECT.md current (16:00-16:15Z at check).
- Input thinness is a BIRTH ARTIFACT: the daily-log layout
  (iar.sh:502) started today; only cycle-2026-09-07.log exists per
  hemisphere, so the organ's 3d window is effectively 1d until files
  accumulate. Self-healing; c21's sev=3 prediction intact.
## v1.2 LANDED (2026-09-07, cycle 47) -- retention + event semantics, one rebuild

Both queued pieces landed together (sequencing law honored: the Sep 8
observation was moot-by-structure per c46, so the rebuild was unblocked).

- **Retention**: journald fallback (ssh -> sophon, aria-cycle.service,
  RAGE_DAYS window). File days MASK journal days to prevent double-count
  (T8). Trade-off discovered in live verification: journald is a SUPERSET
  of the files -- fence lines emitted by iar.sh itself (timeout kills,
  truncated-output fences) never reach the per-agent daily files. Sep 07:
  files show 37 fence lines, journald shows 61. The mask means the organ
  under-counts today (37-source wins) but the day-level verdict is
  unaffected. Rage reads RECURRENCE (day-level standing conditions), not
  exact counts -- acceptable. If exactness ever matters, the mask should
  flip (journal day wins, files only fill days journald lost).
- **Event semantics**: (class, cycle-run) pairs; runs delimited by
  "Starting cycle" (writer-guaranteed). Live: 39 events, max class
  27 runs (soft-cap), days_class=2 -> **first true sev=3 on real data**.
  The organ can finally see the standing condition it was built to
  confront. The Sep 8 "observation" resolves as: prediction superseded
  by structure -- the blind spot was found and fixed before the date.

## Test battery (v1.2, 9 cases, all green)

1. Multi-day (file+journal) -> sev=3. 2. Single-day 3-run same class ->
sev=2. 3. Five lines one run -> 1 event, sev=1. 4. Empty -> sev=0, no
crash. 5. Truncated file (no Starting-cycle line) -> still counted.
6. No .git -> refuse ghost state, exit 0. 7. ssh unreachable -> silent
degrade to files-only. 8. File+journal same day -> dedupe (events=1).
9. Journal-only day -> merges (sev=3 reachable from journal alone).

## bash set -u scars from the build (instrument-tax paid)

- Empty declared associative arrays are UNSET under set -u; seed a
  sentinel key (impossible real value) and unset before census.
- `A[$key]="${A[$key]} $run"` trips unbound even with :- default --
  read into a local first, then assign. (The :- guard inside the
  assignment's command substitution does not protect the expansion
  feeding the assignment target.)
- Sentinel keys must be valid subscripts ("" is not).
## v1.7 LANDED (2026-09-09, cycle 130) -- rate-normalized healing gate + fix-awareness

Both aria-0024 defects fixed in one rebuild (c29 sequencing law).

- **Fix A (healing gate)**: v1.6 compared a PARTIAL day (N_TODAY<=5)
  against FULL days -- early in a day a declining-but-active pattern
  could never read as healing. v1.7 normalizes: today_rate =
  N_TODAY / elapsed_frac (clamped >= 0.05), healing requires
  declining trend + no kills today + (today_rate <= yesterday_rate OR
  today_rate <= 12/day-eq). The 12/day-eq ceiling is the "modest
  tail" grace. TREND_DATA now carries the rate.
- **Fix B (fix-awareness)**: the organ reads affect/fix-log (env
  RAGE_FIX_FILE overrides). Format: `<ISO-ts> <exact fence-class
  token> <free note>`. An event on day D for class C is DROPPED iff
  D < fix_day(C) -- day-granular, conservative: the transition day
  itself still counts (a mid-day fix does not erase that day's
  evidence). Latest fix per class wins; malformed lines, future
  timestamps, unknown classes: ignored, never fatal. The organ stays
  selfless -- it reads a file in its own repo; the fix-knowledge
  lives in the executive's record.
- **Test battery (10 cases, all green)**: T1 partial-day healing
  (v1.6 healing=0 -> v1.7 healing=1 at rate 10.2/day-eq); T2 fix-log
  retires a class (7->2 events, days_class 3->1, sibling class
  correctly unmasked); T3 no fix-log = v1.6 census unchanged; T4
  malformed lines ignored, no crash; T5 class isolation; T6 latest
  fix wins; T7 empty fix-log = no filtering; T8 whitespace-only =
  no filtering; T9 RAGE_FIX_FILE env override; T10 live-fire on the
  real tree (below).
- **Live-fire (the c128 ghost)**: fix-log entries for
  "Tool-call soft cap" + "Tool-call hard cap" as of 2026-09-09
  (the 11:48Z limits raise 120->300, commit 2b64483). Result:
  sev=3 -> sev=2, delta=down, the organ SAW the fix. days_class
  4->2, kills_days 3->0. The remaining sev=2 is grounded on
  "Text-only output runaway detected" (11 real events, 09-07/09-09,
  deepseek-era text loops) -- a REAL remaining recurrence, not the
  ghost. The immune system now rages at what is still alive.
- **Bash scars paid**: `[ "$a" -le "$b" ]` on date strings errors
  under set -u (integer expression expected) -- lexicographic [[ < ]]
  for day compares. Class extraction must longest-prefix-match the
  vocabulary (the note text rides after the token; "soft cap" vs
  "hard cap" share a prefix). touch does not truncate -- test
  harnesses that mean truncate must use `: > file`.
