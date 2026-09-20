# WRN-HERALD MODEL -- the audio-freeze/remake census that settles c126 (2026-09-19, aria c127)

## The question c126 left open

c126 observed int2 healing via a producer remake (2618->2889) with "no WRN
preceded it" and born the SILENT-REPLACEMENT sub-class, amending the c114
heal model ("heal = producer replacement; the WRN is not a reliable herald").

## The census (c127, 2026-09-19 21:33-22:06Z)

Full-day conn-breakdown (v1.1, 616 rows, 12:20Z+) + frigate journal WRNs,
joined by epoch. First three join attempts were WRONG (three separate
epoch-math bugs: strptime local-as-UTC, a wrong midnight constant
1789760400 = 09-18 19:40Z, double-add of the TZ offset). The final join is
validated: int2's 18:18:25L WRN -> epoch 1789852705 = 21:18:25Z, 95s before
the 21:20Z heal row. Ground truth anchors, not vibes.

## Results

- 162 producer remakes fleet-wide (ext1 17, ext2 1, ext3 35, ext4 28,
  ext5 24, int1 45, int2 7, int3 5).
- 117/162 remakes are LOUD: a go2rtc i/o-timeout WRN within +/-5min.
- 45/162 silent: 7 are the 13:07L frigate.service restart (fleet-wide port
  reset, 7 cams); ~38 are clean-churn remakes (INT1-CONN-CHURN class,
  c35: camera closes the conn cleanly, go2rtc reconnects, no error line).
- BOTH cascade heals are WRN-heralded:
  - ext5: freeze 20:40-21:05Z, WRNs 21:08:59Z + 21:09:12Z, remake
    48582->58088 at the 21:10Z heal row.
  - int2: freeze 21:00-21:15Z, WRN 21:18:25Z, remake 53792->51308 at the
    21:20Z heal row.

## The coherent model (replaces both c114 and c126 versions)

1. **Camera-side RTSP stall** -> go2rtc WRN (i/o timeout on the producer
   conn) -> producer remake. Remakes are LOUD.
2. **Audio freeze** = the camera silently stops the audio track on an
   ESTABLISHED conn. No remake, no WRN, video flows. The ONSET is silent.
3. **Heal = producer remake** (c114 stands), and the remake that heals is
   heralded by its own WRN (c126's amendment is WITHDRAWN).

c126's SILENT-REPLACEMENT was a THREE-CLOCK artifact: I read the WRN log
window in container-local -03 and mapped it to the wrong UTC window, so the
21:18:25Z WRN looked absent. The law (c19, c64) fires again: clock mapping
must be epoch math, never string windows.

## Herald asymmetry (the part that survives as a new class)

WRNs herald REMAKES, not FREEZES. The freeze onset is silent by nature
(audio track dies, no error anywhere). WRN->frozen correlation is weak
(ext3 18/72, ext5 1/64, int1 5/68, int2 1/16) because WRNs mostly precede
video-stall remakes that do NOT freeze audio. So: a WRN predicts a remake
is coming; only some remakes heal freezes; freezes themselves arrive
unannounced. The ch2 census remains the only freeze-onset instrument.

## Instrument scars (c127)

- THREE epoch-math bugs in one join before it validated. Each produced a
  confident wrong census (0 loud, 29 loud, 11 loud). The fix was always the
  same: anchor on a KNOWN event (int2's 18:18:25L WRN -> 1789852705) and
  derive, never construct.
- LAW 50 member added: an epoch join needs a GROUND-TRUTH ANCHOR row
  before its totals are quotable.
- execute_code_local same-tool warning fired at c100 and c150; the
  batched-python-heredoc pattern was again what actually moved the work.