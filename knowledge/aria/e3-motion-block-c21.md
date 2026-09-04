# e3 motion block -- cycle 21 findings (2026-09-04 ~07:35 UTC, glm-5.3-flash)

Instrument: frigate.db recordings table, motion column (0-255 score),
1-min bins = SUM(motion). Host python3 on sophon. This is the c14-pinned
instrument (NOT reviewsegment counts -- the c20 lesson).

## Finding 1: the block is clock-locked at 03:00Z, every night

1-min bins across the 02:40-03:20Z window, four nights:

- Sep 1: 500-2200/bin through 02:59, 03:01=526, 03:02=162 -> baseline ~100-200
- Sep 2: 400-1600/bin through 02:59, 03:00=447, 03:01=599, 03:02=204 -> baseline
- Sep 3: 560-1480/bin through 02:59, 03:00=1245, 03:01=879, 03:02=154 -> baseline
- Sep 4 (tonight): same shape. 03:00=1245, 03:01=879, 03:02=154.

The cutoff is CLOCK-ALIGNED at 03:00Z to within one 1-min bin, four
nights running. Edge-resolution law satisfied (1-min bins). This is not
an astronomical event (dusk/dawn drift) -- it is a scheduled or
timer-driven change at exactly 03:00 UTC (00:00 Argentina local, since
Argentina is UTC-3 year-round: 03:00Z == midnight local).

MIDNIGHT LOCAL. The block ends at midnight local time. That reframes
the whole anomaly: whatever produces the band stops (or turns off) at
midnight local, sharp, every night.

## Finding 2: tonight's post-03Z state is a NEW plateau, on e3 AND e4

After the 03:02 drop, e3 did NOT return to the ~100-200/min baseline of
previous nights. It stepped to a flat ~800/5-min-bin plateau (~160/min),
stable 03:30-07:30Z (00:30-04:30 local), no decay, no structure.

Control check: e4 tonight 03:30-07:30Z = 41463/4h ~= 170/min. e3 = 40652/4h
~= 170/min. The cameras are at the SAME level. The 4-5x e3/e4 differential
that defines the block is GONE after 03Z tonight. What remains is a shared,
moderate elevation on both outdoor cameras (baseline for both was ~100-200/min
post-block on prior nights).

Shared + flat + both cameras = global cause candidates: wind (vegetation
in both frames), rain, insects, or a lighting change affecting both
(moonrise, a floodlight). NOT the e3-local emitter -- the emitter's
signature is the differential, and the differential is gone.

## Finding 3: the band is present in e3's daylight frame

Live grab 07:32Z (previews -> container ffmpeg -> gemma3:4b): the eye
confirms a bright horizontal band across the middle, attributes it to a
streetlight shining down onto pavement, brighter than surroundings.
Consistent with c13's daylight naming (dark wall + vertical elements,
emitter below/left outside frame). The band is a STANDING feature of
e3's scene, visible day and night; the BLOCK is the nocturnal
amplification of it (or of its source).

## Updated picture (flag 380)

- The emitter is e3-local, below/left of frame (c12/c13).
- It runs from dusk (~21-22Z, dusk-anchored) to EXACTLY 03:00Z
  (midnight local), sharp cutoff, every night.
- Tonight after 03Z: emitter off, but a shared e3=e4 plateau (~4x
  baseline) persists -- separate phenomenon, global cause, watch it.
- Physical glance at e3's view remains the only remaining
  discriminator for the emitter's identity. The ask stands (for-nacho 408).

## Next-cycle hooks

- Check whether the shared plateau persists tonight (Sep 4 22Z onward)
  and whether e1/e2/e5 also elevated (global-cause test).
- If plateau recurs nightly after 03Z, it deserves its own flag.
- Moonrise check (internet almanac) as a cheap hypothesis test for the
  plateau: moonrise Sep 4 was ~03Z-ish local? Verify before claiming.