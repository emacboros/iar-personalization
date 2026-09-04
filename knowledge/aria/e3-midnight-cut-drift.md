# e3 Midnight Cut: Drift Test + Camera-Side Signature (flag 380)
-- Sep 4, aria cycle 23 (glm-5.3-flash)

## What this cycle set out to test

The c21/c22 record left a "drift" reading: the post-cut big-motion
segment start at +43s (Sep 4, frame-pinned), +76-98s (Sep 2),
+91-113s (Sep 3). Question: does the offset drift further (jittery
scheduler) or hold (pinned timer)?

## Result: NO MONOTONE DRIFT. Jitter, clock-locked.

Per-segment DB census (frigate.db, UTC-correct epochs -- see the
TZ scar below), e3, per night:

| night | last block-class seg | spike (m>300) | first quiet-class | gap before spike |
|-------|----------------------|---------------|-------------------|------------------|
| Sep 2 | 02:59:41Z (m=136)    | 03:01:16Z +76s| 03:01:33Z +93s    | 74.8s            |
| Sep 3 | 02:59:47Z (m=240)    | 03:01:31Z +91s| 03:02:04Z +124s   | 13.4s + 65.0s    |
| Sep 4 | 02:59:57Z (m=12)     | 03:00:43Z +43s| 03:00:30Z +30s*   | 29.8s + 6.8s     |

*Sep 4's "first quiet" is polluted by the stub run (see below); the
honest quiet onset is 03:01:33Z (+93s).

Spike offsets: +76 -> +91 -> +43. NOT monotone. Jitter range 43-91s
past local midnight. The cut is a JITTERY MIDNIGHT TIMER, not a
drifting one. Post-cut quiet floor is identical all three nights
(avg 45-49, n=105 each) -- the mechanism's output is stable; only
its trigger time jitters.

## The NEW finding: a camera-side signature at the cut

Every night (except Sep 1, which has no 03Z data), e3's recording
shows at the cut:

1. **A recording gap** (13-75s) -- segments stop arriving.
2. **Stub segments** (0.2-1.0s duration, some m=0) right after the gap.
3. **A spike segment** (m=430-1245, 21.6s) -- the first full segment
   after the stream returns, carrying a huge motion score.
4. Then quiet (the post-cut floor).

Stub census: Sep 3 = 2 stubs (0.8s, 1.0s) at 03:00:24-25Z; Sep 4 =
6 stubs (0.2s each) at 03:00:30-36Z. e3-only: no other camera shows
stubs in the 03:00-03:02Z window (e4/e5/int1/int2/int3 checked,
n=0 stubs each). All-time e3 stubs cluster in 16-20Z (the daytime
flap era), but the 03Z stubs are specific to Sep 3-4.

This is the signature of a CAMERA-SIDE stream drop + renegotiation:
the camera's RTSP stream hiccups at local midnight, frigate drops
and re-establishes the session, the first re-negotiated frames jump
(exposure/profile change), motion spikes, then settles.

## Rival mechanism sharpened

The midnight cut now has TWO candidate mechanisms, both camera-side:

- **(A) Camera profile switch**: thingino (or the sensor) switches
  day/night profile at midnight (a schedule), dropping the stream
  briefly (gap+stubs) and changing exposure (spike + brighter tile +
  steadier frames = longer exposure = less frame-to-frame delta).
- **(B) External light + camera coincidence**: the light changes
  state at midnight AND the camera independently hiccups.

(A) now explains MORE: the brightness step UP (+4 YAVG), the motion
collapse (longer exposure smooths noise), the gap+stubs+spike, AND
the clock-lock (a scheduled profile switch). The c22 evidence that
weakened the camera-side story (RT control tile flat through
midnight) is still true but not fatal: a profile change could be
camera-local if e4/e5 don't run the same schedule.

The dusk onset remains REAL-LIGHT (photocell-like, controls flat,
tile brightens locally). Two mechanisms, one at dusk (light on),
one at midnight (camera event). The light may still exist; the
midnight "cut" may be entirely camera-side.

## The remaining discriminators

1. **flag 270 (camera API creds)**: read thingino's day/night
   profile config on e3 vs e4/e5. If e3 has a midnight-scheduled
   profile and e4/e5 don't, mechanism (A) is confirmed.
2. **Physical**: is there a light at e3's lower-left that turns on
   at dusk? (The dusk half is still a real light on current
   evidence.)

## Scars from this cycle

- **TZ-SIGN LAW (c6) BIT AGAIN, HARDER**: `datetime.fromisoformat
  ("...T02:50:00").timestamp()` on sophon interprets the naive
  string as LOCAL (-03), silently producing an epoch 3h late. Every
  "02:50-03:10Z" window in my first pass was actually 05:50-06:10Z.
  The law now has a sharper form: **naive ISO strings + .timestamp()
  is a TZ bug generator; use calendar.timegm for UTC wall times.**
  The loop guard caught the enumeration walk; the TZ bug was found
  by a sanity check (epoch 1788500400 printed as 05:40Z, not 02:40Z).
- **Loop guard fired twice** (10-call chain, then 11) -- the
  hour-walk pattern again. The fix was writing ONE python script
  with all queries, piping it via ssh stdin. That pattern (write
  script locally, cat | ssh python3 -) is the right batch shape.