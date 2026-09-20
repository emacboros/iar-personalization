# CLASS-B DECOMPOSED: four mechanisms, #2505 is a minority (aria c162, 2026-09-20)

## The question that opened the cycle

c161 decomposed the ats FAIL-LINEs into class A (producer freeze,
census-FROZEN) and class B (recorder-only, census-healthy) and claimed
class B = the #2505 remake-reconnect family: death 0-5min after a
producer-remake WRN, heal at the next remake. This cycle tested that
model fleet-wide: every class-B window in the 24h ats window (26
windows across 8 cams) joined against (a) ch2census rows, (b) the full
producer.go:170 WRN list (26h, 1443 WRNs), and (c) frigate watchdog
recorder-restart events.

## Method (batch-the-walk, mostly held)

- ab-table.sh: per-cam ats dead hours x census-frozen hours -> A/B split.
- wrn-join v3: ONE extract of 26h WRNs -> epoch+cam table -> nearest-WRN
  before/after each class-B window + WRN count inside window.
- Watchdog-restart windows pulled per cluster, not per window.
- Two instrument scars: the first ab-decomposer parsed ats hour labels
  wrong (trailing colon on $2 -> date parse fail; 3 calls to fix); the
  first wrn-join used paste on a grep -oE alternation that misaligned
  pairs (2164 pairs vs 1443 lines) -- v3 re-extracted per-line instead.
- The loop guard fired twice mid-cycle (same-tool chain >10); the
  batch-the-walk rule saved the second half: all joins after c110 ran
  as single sophon-side scripts.

## The falsifier FIRED: the c161 model is wrong fleet-wide

Of 26 class-B windows, only 5 (19%) fit the WRN-bracket model:

- ext5 h00 (WRN 00:48:27 -> death 00:51:28, +3min)
- ext5 h06 (WRN 06:00:16 -> 06:03:16, +3min; WRN 06:33:48 -> 06:34:13, +25s)
- ext5 h15 (WRN 15:30:07 -> 15:30:19, +12s)
- int1 h13-burst1 (WRN 12:56:31 -> 13:00:48, +4min)
- (int2 h01 and ext1 h01 initially fit but were reclassified B3, below)

Dense-WRN cams (ext4: 1816 WRNs/26h) make the bracket test vacuous --
random alignment is likely when there are 44 WRNs/hour. c342 applies:
a number that fits the hypothesis too well deserves re-derivation.

## The four mechanisms

**A -- producer freeze (census FROZEN).** 57% of dead hours. Unchanged
from c161. ext4's dead hours are almost all A.

**B1 -- remake-reconnect (#2505 family).** 5/26 windows (19%). Census
healthy, death 0-5min AFTER a producer-remake WRN. ext5 + int1 bursts.

**B3 -- recorder-restart dying tails (NEW, the dominant class-B
mechanism).** ~9/26 windows (35%). frigate's watchdog mass-restarts ALL
recorder ffmpegs in sync (fps-limit + no-frames storms); the DYING
recorder's last segments lose audio. Two fleet-synchronous clusters
verified: 01:42:34-42:39Z (ext1/ext2/int2/int3 segs 42.13-42.17) and
06:48:21-48:51Z (ext1/ext2/int3 segs 48.00-48.05), plus ext5 h12 solo
(recorder restart 12:49:23Z, seg death 12:48:47). The podman DISPLAY
times are LOCAL (-03): "22:42:34" and "03:48:21" in the log = 01:42Z
and 06:48Z. The clusters were invisible until the clock conversion --
law-50 re-earned.

**B4 -- census ARTIFACT-masked producer deaths (NEW).** ~5/26 windows
(19%). The census shows near-zero ch2 rows AT the death times but the
row is flagged ARTIFACT (reassembly failure), not FROZEN -- so the
window reads "census healthy" to the A/B split. ext3 h09/h12/h13
(census 2-5 rows at deaths), int1 h15 (census 20 at 15:41), int2 h22
(census 97 at 22:20, milder). The ARTIFACT guard (c132) is a censor
for these events: filter-vs-censor law (c315) fired again.

**TRUE-B (unexplained).** 1/26: int2 h22 -- no WRN, no restart, census
only mildly degraded (97). Genuinely open.

## Implications

1. The c161 claim "class B = #2505 family" holds for ~19% of windows.
   The #2505 fix would NOT close class B fleet-wide.
2. B3 is frigate-side, not go2rtc-side: mass-restart events (2 in 24h)
   are the trigger. The fps-limit mass-exit storm is the upstream
   signature to watch.
3. B4 means the ch2census ARTIFACT guard needs a near-zero-bytes
   sub-flag: ARTIFACT with ch2<=5 is probably a real freeze, not a
   reassembly failure. Candidate census v1.5 change (additive).
4. The ats FAIL-LINEs conflate A + B1 + B3 + B4. The decomposer belongs
   in fleet-check (next build), but the decomposition is now 4-way, not
   2-way: census-FROZEN -> A; census-ARTIFACT-near-zero -> B4; WRN
   bracket +-5min -> B1; recorder restart +-2min -> B3; else TRUE-B.

## Falsifiers for the revised model

- B1: a class-B window with a WRN bracket whose death PRECEDES the WRN
  by >5min (already have ext3 h09/h12/h13 as B4 candidates).
- B3: a mass-restart event whose dying tails are NOT audio-dead.
- B4: an ARTIFACT-near-zero row where the producer census (segcensus
  STALE-ALL) stays clean through the window.
- TRUE-B: int2 h22 recurring with neither WRN, restart, nor near-zero
  census row would confirm a fifth mechanism.