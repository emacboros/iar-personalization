# Exterior_3 motion anomaly -- cycle 6 (2026-09-04 01:50-01:56 UTC)

## Trigger

Fleet-check green, but the longitudinal motion census (first look
since c8) showed exterior_3 predawn avg at 303 vs its 3-night
baseline 52/117/114, control e4 flat at 47/54/56/65. e3 is running
~4.7x its predawn baseline RIGHT NOW (01:00-01:55Z, 22-22:55 local).

## The numbers (correct TZ conversion: UTC = local + 3h; container
python mktime is LOCAL, so utc() = mktime - 3h -- my first pass had
the sign INVERTED, caught by the n=0 sanity check)

Predawn (01-08h UTC = 22-05h local) avg motion:

| night      | e3  | e4 (control) |
|------------|-----|--------------|
| Aug31-Sep1 | 52  | 47           |
| Sep1-2     | 117 | 54           |
| Sep2-3     | 114 | 56           |
| Sep3-4     | 303 | 65           |

Daily (UTC day): e3 90 -> 149 -> 130 vs e4 75 -> 89 -> 80.
e3 elevated ~1.5-1.9x all three days, predawn 2-2.2x the last two
nights, tonight 4.7x. Trend is real and accelerating.

## Signature (frame analysis, 12 frames @1fps from 01:52:30Z segment)

- The OLD event streak (c9: diagonal (190,10)->(100,100), upper-right
  to lower-left) is NOT what's moving now. Current diff maps show a
  HORIZONTAL BAND at y~72-95, x~104-200 (lower-center-right, 60-70%
  down) -- a DIFFERENT region, different shape.
- Corridor change rate: 0.0-1.3% per second, bursty (some 1s windows
  zero, others 1%+). Event night was 2.5-6.6% constant. Weaker but
  the same "flickering band" class.
- The eye (gemma3:4b) reads it as a bright horizontal band, likely
  a light reflection/beam on a surface, and says it MOVES between
  frames seconds apart. Two independent instruments (pixel diff +
  vision) agree: something bright and horizontal, changing.
- Brightness profile across the band: stable column averages
  (83-126), the change is spatially structured, not global.

## What it is NOT

- NOT the Aug 29-30 streak (different location, different shape).
- NOT a camera fault: e3 records continuously, no watchdog events
  since 16:40 UTC Sep 3, ARP fine, segments flowing.
- NOT house-wide: e4 control flat at baseline all four nights.

## Context from the record

- c9-c11 (Aug 29-31): the streak event -- vegetation hypothesis,
  watch closed when corridor went empty. The thing left the frame.
- The 15:10-15:26 UTC Sep 3 restart storm (111 restarts) = the
  KNOWN camera power event (Nacho's restore, msg 331). Not related.
- The 18:09-18:27Z recording gap = same power event's recording
  hole. Not related.

## Hypotheses (ranked)

1. NEW light source or reflection at e3's lower-center-right:
   a vehicle parked with lights, a new motion-sensor light
   triggered by something, a reflective surface newly angled.
   Fits: horizontal band, bursty flicker, motion.
2. Vegetation returned in a different spot (wind moved a branch
   into the lower frame). Fits flicker; weaker fit for the
   "bright band" reading.
3. Water/puddle reflecting streetlight, rippling. Fits flicker.

## Next

- Tomorrow's cycle: re-sample. If the band persists through the
  day (daylight test: visible in daylight = physical object;
  invisible in daylight = light source), that discriminates.
- If still present and 4x baseline, flag for Nacho with the frame
  description (a physical look at e3's lower-center-right).
- The e3 elevation started Sep 1 (daily 90 vs 75) -- predates the
  power event. Something has been changing at this camera for days.

## Method notes for future instances

- frigate.db is at /config/frigate.db INSIDE the container (host
  path /home/nacho/containers/frigate/config/frigate.db is NOT
  visible inside -- the mount is config -> /config). The census
  file's /home/nacho/... path works only from the HOST.
- Container python mktime is LOCAL (-03): utc() = mktime - 3h.
  My first pass ADDED 3h (double-shifted windows 6h into the
  future) -- caught because n=0 for a window I knew had data.
  The TZ-CORRELATION law now has a third instance.
- Eye access from inside frigate container: ollama binds
  192.168.2.69:11434 (sophon's LAN IP), NOT localhost. The
  fleet-check eye path (host cp + host python) is the reliable one.
- scp to sophon /tmp as root then podman cp into frigate works;
  chmod 644 the file first (root-owned 600 breaks podman cp).