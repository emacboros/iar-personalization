# Camera clock race -- thingino fleet (root cause + fix, 2026-09-11)

## Symptom (the 0028 bug)

Frigate's record path (-c:v copy) persisted exterior_1 segments with
absurd duration metadata (measured 303546s-708265s = 3.5-8.2 days),
growing through the day. Detection fine (re-encodes = normalizes),
audio fine, fresh connections fine. fleet-check SEG-TAIL flapped on
the poisoned segments -> intermittent false FAIL=1 -> fear-organ
noise.

## Root cause (verified on camera .101 directly, ssh root@)

Thingino cameras have NO RTC. Boot sequence:

1. Clock starts at firmware build date (May 25 2026).
2. S31prudynt starts the RTSP stream -- BEFORE time sync.
3. S49ntpd runs a one-shot `ntpd -q -N &` (backgrounded) + the
   daemon. The one-shot loses the race when wifi/DNS is not ready
   and fails SILENTLY; the daemon's slow poll (max 4096s) then takes
   hours to sync.
4. While the clock is wrong, RTP timestamps carry the May-25 base;
   ffmpeg copy-path duration metadata explodes.

Every camera logs `time disparity of ~156342 minutes (108 days)
detected` at boot -- the whole fleet has the race; only .101's was
caught because fleet-check watches it.

Bug era on .101: 09-10 ~04h -> ~23h UTC (self-healed when the daemon
finally synced; no reboot involved). The 09-11 01:00 reboot + fast
sync (01:03) ended the current window. Earlier partial eras: 09-09
00h, 09-10 00h.

## Fix (aria-owned under the 0028 ownership grant)

Cron line on ALL 8 cameras (192.168.2.{101..105,201..203}), staggered
per camera so they don't collide: `ntpd -q -N` every 30 min
(13,43 / 17,47 / 23,53 / 27,57 / 31,01 / 35,05 / 39,09 / 21,51).
Idempotent -- instant no-op when the clock is already synced
(verified live: returns in <0.1s with offset ~0.05s). Forces sync
within 30min worst-case even when the boot one-shot loses the race.
Reboot crons left intact (Nacho's ruling: keep-or-disable is aria's;
kept -- bounds the bug window).

## Verification watch

Next nightly reboots (01:00/02:00/06:00 local etc.) must show sane
ext1 segment durations within ~30min of boot. If a segment is still
poisoned >30min after any reboot, the fix failed -- escalate. The
SEG-TAIL sawtooth watch can be withdrawn once 2-3 reboot cycles pass
clean.

## Laws

- A backgrounded one-shot that can silently fail is not a sync
  mechanism; it is a race with the network's readiness. (Sibling of
  law 3: silent error swallowing -- here the failure mode is silent
  NON-sync.)
- "Timestamps CANNOT be +24h because of the daily reboots" (Nacho's
  a priori bound) was right in kind but the mechanism was a 108-day
  base offset, not accumulation. The a priori bound was right about
  the class, wrong about the magnitude -- measure anyway.
