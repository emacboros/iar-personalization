# e3 Light Census (flag 380) -- Sep 4, aria cycle 22

## The question this cycle answered

Roadmap item: does e3's left-bottom tile brighten MORE than twilight
explains (local light) or does the whole frame move with it (camera
gain/IR)? Plus the dusk-onset shape across three nights.

## Method

- Frame grabs from recordings (720p main stream, 1280x720 gray),
  tiles: LB = x 0-320, y 360-720 (the c2/c3 anomalous tile, scaled
  4x from the 320x180 coordinates); RT = x 960-1280, y 0-360
  (control tile).
- Frames: e3 hour 13/18/21/22 (31.xx segments), plus targeted
  22:10 (pre-onset), 22:40 (post-onset), 23:30 (mid-block),
  03:30 Sep 4 (post-cut). Controls e4/e5 same hours.
- Motion census: 10-min and 2-min bins, three nights (Sep 1/2/3),
  controls e4/e5.

## Findings

1. **The LB tile brightens MONOTONICALLY through the evening:**
   96.1 (22:10, pre-onset) -> 104.3 (22:40) -> 111.0 (23:30) ->
   114.9 (00Z) -> 115.2 (02Z) -> 118.9 (03Z, post-cut). The tile is
   the brightest region of the frame all night (LB-FULL goes from
   -11.9 pre-onset to +22.7 post-cut). This is a LOCAL emitter, not
   camera gain: e4/e5 LB tiles show no such monotonic rise (e4 LB
   is FLAT 73-73-73-69 through 00-04Z; e5 drifts down).

2. **The emitter is visible from dusk onward and the eye sees it at
   every stage.** gemma3:4b (4 frames, same question): "bright light
   reflecting off the ground in the lower left corner" at 22:10,
   22:40, 23:30, and 03:30. No stage where the light is absent.
   (Eye reads corroborated by the tile census -- eye-noise law
   satisfied by the non-eye witness.)

3. **Onset is NAUTICAL-DUSK-anchored, not clock-anchored.** 2-min
   bins: Sep 1 onset 22:24Z (19:24 local, ~+27 min after sunset),
   Sep 2 onset 22:24-22:30Z, Sep 3 onset 22:24Z. Sunset Cordoba
   ~21:57Z these days; onset rides the twilight curve, drifting
   with it. NOT a fixed 22:30Z timer.

4. **The midnight cut is CLOCK-anchored** (00:00:43 to 00:01:53
   local across nights, jittery) and does the OPPOSITE of what a
   light-off would do: brightness steps UP (+4 YAVG in LB tile)
   while motion collapses 6x (avg 251-296 -> 46-51).

5. **The block motion is 3-4x the daytime floor, not a small
   perturbation:** e3 pre-onset avg 62-96, block avg 251-296,
   post-cut 46-51. Controls e4/e5: pre 78/150, block 71/130,
   post-cut 50/54 -- they DECLINE smoothly into night. e3 alone
   jumps UP at dusk and drops at midnight.

## Interpretation (current best)

TWO mechanisms, one emitter complex:
- A light near e3 (lower-left of frame, ground-level reflection)
  that turns ON at nautical dusk and stays on. Its light on a
  reflective/vegetated surface generates continuous motion score.
- At local midnight, something changes state: the light gets
  BRIGHTER (+4 YAVG) and STEADIER (motion collapses 6x). Fits a
  dimmer finishing a slow ramp, a second steadier light source
  activating, or a motion-triggered flood going from triggered-
  flicker to steady-on. The brightness step UP rules out "light
  turns off at midnight".

## Rival hypothesis still alive

Thingino day/night profile at 03:00Z (flag 270, camera API creds)
-- but the profile would affect the WHOLE frame, and the RT tile
does NOT step at midnight (99.6 -> 95.9, flat). The midnight step
is LB-tile-local. Camera-side profile is now WEAKENED for the cut;
still the only explanation candidate for the dusk ONSET anchor
(photocell vs camera IR transition -- the onset rides twilight,
which is what a photocell does AND what a camera IR switch does;
the tile census says the light itself turns on, because the tile
brightens locally while controls don't).

## Instrument notes (scars)

- Segment names must be VERIFIED by ls before ffmpeg (three failed
  grabs from assumed names; segment-name law re-learned: 15s cadence,
  start-of-minute, varies by camera).
- ffmpeg rawvideo .gray cannot be re-read by container ffmpeg
  directly -- wrap in PGM header for PNG conversion.
- ollama calls with big base64 must go through python urllib, not
  curl argv (E2BIG).
- The 320x180 tile coordinates scale 4x to 720p (x4, y4).