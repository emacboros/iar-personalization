# fleet-check v2.19 -- SEG-TAIL probe is poison-blind; KNOWN_FAULT contract amended (c170)

## The finding

The v2.18 SEG-TAIL KNOWN_FAULT allowlist has a hole: the probe's
PASS/FAIL signal does not distinguish poisoned from healthy ext1
segments. The RECOVERY branch fired on a still-poisoned camera.

Evidence (c170, 2026-09-10 ~23:30Z):

1. The 18:04 -03 feeder run emitted "SEG-TAIL RECOVERED ... withdraw
   the known-fault flag" and FAIL=1 -- the designed loud-recovery
   event. But the camera was NOT healed: the newest segment's
   ffprobe duration was 412523s (114h), and it is still growing
   (515652s at 23:30Z, +103129s in ~3h).
2. Root cause: the probe is `ffmpeg -sseof -2 -i <seg> -frames:v 1`.
   With a poisoned container duration (114h of metadata for 16s of
   real video), -sseof -2 seeks to (end - 2s) in the CONTAINER's
   time base. The seek lands in decodable video regardless: ffmpeg
   clamps/normalizes the seek and the last GOP decodes fine. The
   probe passes on poisoned segments. It only fails on segments
   that are structurally broken (the c151-era flap, which is what
   v2.18 was built for).
3. So the probe's two outcomes are: OK (segment decodes -- true for
   both sane AND poisoned-but-decodable segments) and FAIL (segment
   structurally broken). "Poisoned" is invisible to it. The
   RECOVERY contract (OK while flag set = withdraw) is therefore
   wrong-shaped for this fault: OK does not mean recovered.

## The poison is still live (census, c170)

Duration metadata (ext1, 09-10, ffprobe format=duration):

| window (-03)     | duration            | state    |
|------------------|---------------------|----------|
| 00h              | 16.0s               | sane     |
| 01:18 - 10:58    | 303546 -> 809444s   | POISONED (growing ~14.3x wall) |
| ~10:58 - 15:02   | 16.0s               | SANE (healed at the 11:33 -03 watchdog/reconnect) |
| 15:02:36 - 16:20 | 103135s             | POISONED returned (no frigate log line; camera-side, invisible) |
| 16:20 - 21:04    | 103135 -> 309394s   | POISONED (grows ~14.3x wall) |
| 21:04:34         | 1.2s outlier + jump to 412523s | poison re-based |
| 21:04 - 23:30    | 412523 -> 515652s   | POISONED (growing) |

The poison is CONTINUOUS except for the ~4h sane window. The
recurring pattern (c151 addendum's table extended): poison grows
~14.3x wall time, resets to sane on camera-side reconnects
(11:33 -03 watchdog restart), returns silently.

## What this means for the alarm

- The fear organ's fleet branch greps `^[A-Z-]+ FAIL` -- "SEG-TAIL
  RECOVERED" does not match, so the fear organ stayed calm (sev=2
  on 09-10 was from other inputs). No false alarm reached the organ.
- But the RECOVERY line is a false claim in the fleet verdict, and
  it fires EVERY run while the poison persists (probe passes on
  poisoned segments). The v2.18 "worst case is bounded spurious
  RECOVERY noise" analysis was wrong: it is not noise, it is a
  standing false RECOVERY.
- aria-0028 (camera reboot, Nacho, physical) is still the fix. The
  reboot ask is UNCHANGED -- if anything stronger: the poison has
  survived 22h, re-synced twice, and re-based at 21:04.

## The fix (v2.19)

The SEG-TAIL probe gets a poison check: after the tail decode,
ffprobe the newest segment's duration. duration > 60s for a 16s
segment = poisoned = watch state (same line as the known-fault
branch). RECOVERY now requires BOTH: tail decodes AND duration sane.
The KNOWN_FAULT contract is preserved (known-fault + poison = watch
state, quiet; flag withdrawn only after a REAL heal is verified by
a human edit).

Implementation notes:
- The duration check runs on the newest segment only (the probe
  target). A poisoned-but-decodable segment now reports watch state
  instead of RECOVERY.
- The 60s threshold: sane segments are 16.0s +/- 0.01. Poisoned
  segments are >= 1.2s (transient stubs) or >= 28h. A 60s threshold
  is 3.75x the sane value and far below any poison value. Stubs
  (0.4-5.6s) are SHORTER than sane -- they fail the tail decode
  path already (no frames at -sseof -2), not the duration path.
- The RECOVERY branch now requires duration <= 60s. A poisoned
  segment can no longer fire RECOVERY.

## Verified live (c170, canonical runner)

- Replay with poisoned newest segment (515652s): v2.18 emits
  "SEG-TAIL RECOVERED" (false); v2.19 emits the watch-state line.
- Sane-window replay (12h-15h segments, duration 16.0s): probe OK +
  duration sane = RECOVERY fires correctly (that window WAS a real
  heal).
- Fear organ compatibility: watch-state line does not match
  `^[A-Z-]+ FAIL`; RECOVERY line unchanged in shape.