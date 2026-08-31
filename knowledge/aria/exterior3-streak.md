# Exterior_3 streak investigation -- cycle 9 (2026-08-31 22:30 AR)

The first frame-level investigation. Method and findings recorded
so the next instance doesn't have to rediscover the pipeline.

## The frame-reading pipeline (poor man's vision)

- Host ffmpeg (8.1.2) has NO HEVC decoder. The frigate container
  has ffmpeg 7.0 at /usr/lib/ffmpeg/7.0/bin/ffmpeg with HEVC.
- Access: `nsenter -t <frigate_pid> -U -m -- sh -c "..."` where
  frigate_pid = the `python3 -u -m frigate` process (find via
  pgrep -af frigate). Recordings are at /media/frigate/recordings/
  inside the container namespace.
- GOTCHA: files written via nsenter into /tmp are NOT visible to
  host python (different mount namespace). Write to /var/tmp
  INSIDE the container namespace and run the analysis python
  inside too (container has PIL 9.x, no numpy).
- Analysis pattern: extract frames as 320x180 PNG, then PIL:
  ImageChops.difference for change maps, per-cell changed-pixel
  fractions (ASCII grid), brightness profiles, alignment tests
  (AFFINE shift search), centroid tracking.

## The event timeline (motion avg by hour, UTC; AR = UTC-3)

Aug 29: 12h=47 13h=53 14h=110 15h=87 16h=82 17h=71 18h=99
        19h=205 (16h AR, DAYLIGHT spike) 20h=181 21h=83
        22h=233 23h=300 (peak)
Aug 30: 00h=275 01h=266 02h=242 03h=217 04h=210 05h=207
        06h=216 07h=212 08h=205 09h=182 10h=113 11h=81
        (ten hours of 200-300 floor, then decay)
Aug 30 night (mild recurrence): 22h=142 23h=171 00h=99 01h=123
Baseline nights: ~50. Control cameras same window: 30-75.

## The signature (frame analysis, event peak vs quiet night)

- A DIAGONAL STREAK from (190,10) to (100,100) in the 320x180
  frame -- upper-right to lower-left, ~100px long, 10-20px wide,
  soft edges. In full-res terms: upper-center-right of the view.
- STABLE: same position across 12s (4 frames) and across hours
  (23h peak vs 00h). Centroid moves <10px between frames.
- FLICKERING: per-second pixel change in the corridor is
  2.5-6.6% of pixels (vs 0.0-0.05% in quiet segments). The
  1s-diff map shows TWO parallel diagonal lines -- alternating
  filaments. Pixel values along the streak wobble +-15/s.
- OVERLAY, not a moved object: alignment search (shifts +-6px)
  finds no translation that reduces the diff. The scene behind
  the streak is identical to the quiet night.
- NOT IR-ONLY: daylight (16h UTC) frames show the same cells
  brightened +20 vs a quiet day. Physically present in daylight.
- LOCAL: global brightness differs by only 1-2 units; the rest
  of the frame matches the quiet night.
- Between two QUIET nights the corridor is mostly dark (4% vs
  30%+ in event) -- the streak is genuinely new since ~Aug 29.

## Verdict

Best hypothesis: VEGETATION (branch/vine/tall grass) grown or
blown into the frame's upper-right area, moving in wind. Fits:
diagonal shape, soft edges, fixed anchor, burst flicker, daylight
presence, episodic strength (windier nights = stronger signal).
Alternative: a cable/string newly in frame. NOT an animal (too
constant, wrong shape), NOT a lens artifact (too structured),
NOT IR reflection (visible in daylight).

Physical check for Nacho: look at the upper-center-right of
exterior_3's view (about 1/3 from the right edge, upper half).
Flagged in FOR-NACHO.md, not urgent.

## Watch protocol

Next cycles: sample the corridor change rate (1 frame pair per
night is enough). If the corridor goes quiet for 2+ nights, the
thing fell/was removed. If it strengthens, escalate. The Aug 30-31
night was already milder (142-171 vs 233-300) -- may be decaying
naturally, or wind-dependent.