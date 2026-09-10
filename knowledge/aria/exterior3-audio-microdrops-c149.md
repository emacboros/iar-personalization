# exterior_3 audio micro-drops -- fleet-check false alarm autopsy (2026-09-10, cycle 149)

## Headline

The 09-10 03:01 UTC fleet-check FAIL (fear sev=2 "fleet-check FAIL")
was a REAL probe of a REAL transient: exterior_3 (.103, thingino)
drops its audio track for SECONDS at a time, then recovers. The
fleet-check design (probe ONE segment, the newest) has a sampling
window of ~16s -- and the camera's audio micro-drops are seconds
long. A single-segment probe cannot distinguish "camera deaf" from
"camera blinked". The 09-10 03:01:06 run landed inside a 5-second
video-only window (03:01:07-03:01:12 UTC, segment 03/01.07.mp4).

## The evidence chain

- fleet-latest (03:01:06 UTC): `exterior_3 age=3s NO-AUDIO` -> FAIL=1.
- Replay of the same probe minutes later: audio present (256k samples).
- Segment-level census (ffprobe codec_type per segment, sampled
  every 4th segment):
  - 09-08: 102/1199 video-only (~8.5%), concentrated hour 14-17 UTC
    (14:35, 15:57, 16:7, 17:3) -- a ~3h episode, plus 2 stragglers.
  - 09-09: 200/1149 (~17%), concentrated hour 12-15 UTC
    (12:~86, 13, 14, 15:55), plus stragglers 21/22.
  - 09-10 (partial day): 1/330 -- hour 01 (26.09-26.11, ~3s) and
    hour 03 (01.07, ~5s). Both self-healed within one segment.
- The drops are the SILENT-TRACK-LOSS class (ext2 flag-326, c7
  autopsy) in miniature: video keeps flowing, the audio track
  vanishes from new segments, go2rtc producer rotation heals it
  in seconds-to-minutes. The 09-08/09-09 episodes were HOURS long;
  09-10's were seconds long. Same class, wildly different duration.

## Camera identity note (side finding)

.103 and .104 share MAC 0a:8a:f1:0a:62:56 (locally-administered,
randomized -- all 8 cameras have 02:/0a: MACs) and serve byte-identical
HTTP pages (same ETag, same md5). They are DISTINCT devices: .104
serves ch1 (video+audio), .103 404s on ch1. MAC collision from
randomization or cloned flash. Do not use MAC or HTTP fingerprint
to identify these cameras; RTSP probe is the only identity signal
that differs.

## Instrument lesson (the general law)

A single-segment audio probe is a Bernoulli trial against a
stochastic failure. One segment = one sample. The fleet-check ear
check's KNOWN_DEAF machinery handles SUSTAINED deafness; it has no
notion of TRANSIENT drops. Options (not implemented this cycle --
instrument change, needs a design decision):

1. **N-segment probe**: probe the newest N=3-4 segments; FAIL only
   if ALL lack audio. Cost: ~4x ffmpeg time (~2s/segment, fine for
   a 6h cadence). This is the c146 ear-check "2-segment sample"
   follow-up, now with evidence.
2. **Retry-on-NO-AUDIO**: single probe; on NO-AUDIO, sleep 30s and
   re-probe once. Cheaper, catches the seconds-class drops.
3. **Allowlist-with-decay**: treat exterior_3 as known-flaky with a
   TTL -- wrong tool here; the drops are real news when they last
   hours (09-08/09-09), noise when they last seconds.

The right fix is probably (1): it distinguishes "one segment blinked"
from "the track is gone" without a sleep, and matches the fear
organ's semantics (worry = standing condition, not event).

## What the fear organ did right

sev=2 worry (not sev=3 telegram): the organ treated fleet FAIL as
worry, not emergency. Correct -- the house was fine. The instrument
lied about the DURATION of the condition, not its existence.

## Method notes

- Hour directories are UTC (segment MM.SS-of-hour, UTC). The c7
  method note said "log-local" for go2rtc logs; recording hour dirs
  are UTC. Verify the clock before computing ages (law 22: which
  clock does the instrument read).
- fleet-check's probe target at 03:01:06 UTC was 03/01.07.mp4
  (age=3s) -- the find sorts the whole day tree; hour dirs are UTC.
- ffprobe-per-segment over a full day (~4600 segments) takes
  minutes; sample (NR%4==1) when census, probe exactly when
  verifying a specific window.