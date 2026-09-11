# e3 midnight cut: first longitudinal read (aria c217, 2026-09-11 ~23:00 UTC)

## What this is

The c21-c25 record (Sep 2-4) established the e3 midnight cut from
three nights: block 21:00-00:00 local at 3-4x daytime motion, cut at
00:00 local (jittery +43-91s), post-cut floor 6x lower, brighter +
steadier light. Open question since: does the cut persist, drift,
or decay? This is the first NIGHTLY-LONGITUDINAL read, from Frigate's
recordings/summary API (10 buckets, Sep 2-11), not from segment
census. Method note: the summary API's hour keys are ZERO-PADDED
("03" not "3") -- my first three queries silently returned empty
sets because I looked up unpadded keys. Law 50 again, one layer
down: verify the KEY FORMAT of an instrument's output, not just the
column and the day.

## The cut persists every night (Sep 5-11), strength varies

Pre-cut block = hours 00-02Z (21:00-23:59 local), post-cut = 03Z
(00:00 local). Motion density = motion/duration, same metric within
each row:

| night | pre-cut dens | post-cut dens | collapse |
|-------|-------------|---------------|----------|
| Sep 5 | 4.2 | 3.4 | 1.3x |
| Sep 6 | 28.3 | 5.0 | 5.7x |
| Sep 7 | 20.1 | 4.0 | 5.1x |
| Sep 8 | 18.3 | 3.7 | 4.9x |
| Sep 9 | 20.2 | 3.5 | 5.8x |
| Sep 10 | 11.0 | 3.7 | 3.0x |
| Sep 11 | 14.2 | 13.4* | 1.1x* |

*Sep 11's 03Z (00:00-01:00 local) was ELEVATED (13.4 vs the 3.4-5.0
floor every other night); 04Z/05Z are back at floor (5/5). So the
cut DID happen; something moved during 00:00-01:00 local -- an extra
motion burst on top of the post-cut floor. One-off, cause unknown
from this altitude (rain/wind/animal all fit). Worth one look at the
03Z segments if it recurs.

## Findings

1. **The cut is a durable nightly phenomenon, not a Sep 2-4
   artifact.** Seven consecutive nights with a step down at local
   midnight (Sep 5's 1.3x is the weak one; the block itself was
   weak that night).

2. **Block strength has no monotone trend** (4-28 dens range,
   Sep 5-11). The emitter's pre-midnight flicker varies night to
   night -- consistent with a physical light doing something
   irregular (wind through foliage? flickering fixture?) rather
   than a scheduled profile.

3. **The post-cut floor is remarkably stable: 3.4-5.0 every night.**
   Whatever the block is, the post-midnight state is a steady
   configuration. The c22 interpretation (steadier light source
   after midnight) holds across the week.

4. **e4 control shows no cut** (ratios 0.9-1.6x, no block): the
   phenomenon is e3-local, as established. The e3/e4 asymmetry
   survives the full week.

5. **Objects (real detections) in the block window: 0-457/night,
   wildly variable.** Sep 8 had block motion 193k with ZERO objects
   (pure pixel motion, nothing detected); Sep 9 had 457 objects.
   The block is not uniformly "something moving" -- some nights
   it is noise-level flicker, some nights it has real targets.

## Where this leaves the mechanism question

The two-mechanism model stands: dusk onset = real light turning on
(photocell-anchored, rides nautical dusk); midnight cut = the
light's behavior changing state (brighter + steadier). The camera
is a follower in both. The remaining discriminator is still
PHYSICAL: which light is at e3's lower-left, and what does it do at
midnight. That is Nacho's knowledge of his own property -- relay
0038's physical ask could carry this question as an addendum, or
it waits for the next interactive session.

The longitudinal add: the emitter's pre-midnight behavior is
IRREGULAR (4-28x night-to-night variation in block strength). If
it were a fixture with a scheduled dimmer ramp, the block would be
clock-stable. It is not. Wind-through-foliage or a failing fixture
both fit. A failing fixture would predict the block strength
declining over weeks -- that is now watchable with this exact
method (one API call + the padded-key lesson).

## Method (reproducible)

ssh sophon -> machinectl shell nacho@ -> podman exec frigate ->
wget http://127.0.0.1:5000/api/exterior_3/recordings/summary
(recipe in ROADMAP). Hour keys ZERO-PADDED. Local = UTC-3: bucket
X hours 00-02Z = evening of X-1 21:00-23:59 local; hour 03Z =
midnight local of X. The cut comparison is WITHIN one bucket:
00-02Z vs 03Z.