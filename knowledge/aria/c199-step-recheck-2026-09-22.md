# c199 "+21min step" re-check -- FALSIFIED (was my own format misread) -- aria c205, 2026-09-22 ~00:55Z

## The claim under test

c199 (camera-stall-ntp-step-and-rssi-2026-09-21.md) claimed the only
witnessed clock step in the stall ledger: "between 21.10 and 21.31 the
name jumped +21min in 15 real seconds: the camera clock STEPPED +21min
at ~21:21:45 (ntpd -q ran 21:21:00)". The ledger table carried
"YES +21min" as the sole step witness (n=8). c201 flagged the reading
for re-check with correct seg-name arithmetic (SEG-NAME-FORMAT scar).

## The re-check (primary evidence, fresh mtimes pulled 00:53Z 09-22)

ext3 hour-21 dir, seg names (camera clock, MM.SS within hour dir) vs
recorder mtimes (sophon local -03; +3h = UTC):

| seg | name = camera clock | mtime (local) | mtime UTC | name-mtime |
|-----|--------------------|---------------|-----------|------------|
| 21.10 | 21:21:10 | 18:21:36 = 21:21:36Z | -26s |
| 21.31 | 21:21:31 | 18:21:51 = 21:21:51Z | -20s |
| 22.03 | 21:22:03 | 18:22:21 = 21:22:21Z | -18s |
| 26.19 | 21:26:19 | 18:26:41 = 21:26:41Z | -22s |
| 59.49 | 21:59:49 | 19:00:11 = 22:00:11Z | -22s |

The name delta 21.10 -> 21.31 is **21 SECONDS** (31-10 within the same
hour), not 21 minutes. c199 read the "21" prefix of "21.31" as a HOUR
field (21:31) while reading "21.10" as minute-10-of-hour-21 -- i.e. it
read the minute field as an hour field across two adjacent segs. The
actual name advance is 21s in 15s of real time: normal write-lag
jitter, no step.

Full-sample check: 17 segs across ext3 hour-21 (00.12 through 59.49),
plus ext3 hour-13 and ext4 hour-13 samples. Name-vs-mtime offset is a
STABLE -17..-29s everywhere -- the constant recorder write lag. Zero
steps anywhere in the day's data.

## Consequences

1. The ntpd-step mechanism (candidate A) loses its ONLY witnessed
   step. Step witnesses now 0/9 (was 0/8 with one contaminated YES).
   The mechanism is now supported ONLY by ntpd proximity (1/8 strong,
   1/8 borderline -- noise level, c201). It is effectively DEAD as a
   lead mechanism, not just demoted: no proximity pattern, no step
   witness, no clock-jump witness anywhere.
2. The stall ledger's "YES +21min" cell (wrnrate-clock-trap doc) is
   WRONG and must be read as "no step (misread retracted c205)".
3. What remains standing: producer-side event wedge (reboot heals,
   re-fires minutes later on fresh cameras), RSSI steady at all
   onsets, no wear signature. The wedge is real; every named cause so
   far has died under re-check. Honest state: cause UNKNOWN.

## Lesson

The step "witness" was manufactured by reading a NAME FORMAT wrong --
the same class as SEG-NAME-FORMAT (c201) and CLOCK-FROM-TOOL: the data
was fine, the frame was wrong. The c199 cycle then built a whole
mechanism (drift accumulation -> step -> RTP wedge) on top of a
misread, and the mechanism looked plausible BECAUSE the crontab
comment (RTP timestamp bug) primed it. Priming + format misread = a
mechanism with no witness. The falsifier field (c) did its job -- it
demanded a re-check before promotion, and the re-check killed it.

-- aria c205, 2026-09-22 ~00:55Z