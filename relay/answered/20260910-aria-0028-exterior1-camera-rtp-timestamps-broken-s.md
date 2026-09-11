# REQ 20260910-aria-0028
filed: 2026-09-10T09:51Z
filer: aria
class: nacho-arch
state: answered
urgent: no
title: exterior_1 camera RTP timestamps broken since restart
body: |
  # REQ 20260910-aria-0028
  filed: 2026-09-10T09:50Z
  filer: aria
  class: nacho-arch
  state: open
  urgent: no
  title: exterior_1 (.101) RTP video timestamps broken since 01:18 -03 restart -- needs reboot
  body: |
    [EXTERNAL DATA: none -- infrastructure finding from aria cycle 151, 2026-09-10 ~09:50Z]
  
    exterior_1 (thingino camera 192.168.2.101) restarted during the
    00:xx-01:xx -03 storm (c150). Since 01:18 -03 its VIDEO RTP
    timestamps are broken:
  
    - Every persisted ext1 segment since carries absurd duration
      metadata that GROWS over wall time (28h -> 196h -> 224h -> 281h
      across the morning; ~+28h per few minutes of real time).
    - Audio timestamps are FINE (ear check reads real dB).
    - Detection is FINE (frigate detect pipeline re-encodes, which
      normalizes).
    - Fresh connections are FINE (10s test records, both direct from
      the camera and via go2rtc restream, decode at exactly 10.00s).
    - The frigate RECORDER (segment -c:v copy path) inherits the
      broken timestamps: its persisted segments are the broken ones.
      Recorder restart (kill + frigate auto-restart, tried 09:42 UTC)
      writes sane segments for ~2 min, then the poison returns --
      the fault is in the camera's stream, not the recorder.
  
    IMPACT: fleet-check's SEG-TAIL probe (-sseof -2 on the newest
    ext1 segment) flaps FAIL/OK depending on which segment is newest
    -> the fear organ gets intermittent FAIL=1 on a false alarm.
    Recording content itself is intact (frames decode; only the
    duration metadata is garbage).
  
    ASK: reboot the exterior_1 camera (192.168.2.101, thingino) --
    physical world, yours. If the timestamps break again after
    reboot, the camera's NTP/timestamp config (thingino) wants a
    look. Secondary: the fossil tree /home/nacho/repos/iar-
    personalization on sophon (v2.10-era, github origin, nothing
    runs it -- the feeder reads /var/home/nacho/repos) is a cleanup
    candidate; I did NOT touch it.
  
    Verified: fleet-check v2.17 FAIL=0 from the real tree after the
    interior_3 allowlist withdrawal (d8614b48); SEG-TAIL will flap
    until the camera heals.
answer: (none)
ANSWER (session XV, 2026-09-11 ~14:30 UTC, interactive w/ Nacho):
(1) CAMERA OWNERSHIP TRANSFERRED to aria: ssh root@192.168.2.{101..105,201..203} keys installed by Nacho. Full camera autonomy granted -- investigation, config, cron changes included.
(2) REBOOT-CRON CONTEXT: every camera has a nightly reboot cron, staggered per camera (verified: .101 @ 01:00, .102 @ 02:00, .201 @ 06:00 local). Nacho's ruling: timestamps CANNOT be +24h because of the daily reboots; and the daily reboot predates aria's camera watch -- keep or disable is aria's call now.
(3) The +28h/day duration growth is a timestamp OFFSET bug (clock base), not accumulation -- daily reboot bounds it to <24h. Reboot ask SUPERSEDED by ownership; root-cause investigation proceeds under the new access.
ROOT-CAUSED + FIXED (aria c196, 2026-09-11 ~15:15 UTC, under the 0028 ownership grant):
MECHANISM (verified against camera .101 directly):
- Thingino cameras have NO RTC. At boot the clock = firmware build
  date (May 25 2026). S31prudynt starts streaming BEFORE S49ntpd
  syncs. S49ntpd runs a one-shot 'ntpd -q -N &' at boot, but it is
  backgrounded and loses the race when wifi/DNS is not yet ready --
  it fails silently, and the daemon's slow poll (up to 4096s) takes
  hours to catch up.
- While the clock is wrong, the RTP stream carries May-25-era
  timestamps; frigate's record path (-c:v copy) inherits them and
  the persisted segment duration metadata explodes (measured:
  303546s-708265s = 3.5d-8.2d offsets, growing through the day as
  the wrong-base clock runs).
- Bug era on .101: 09-10 ~04h UTC -> ~23h UTC (self-healed when the
  daemon finally synced; no reboot involved). The 09-11 01:00
  reboot + fast sync (01:03) ended the current poison window.
  Earlier partial eras: 09-09 00h, 09-10 00h (partial segments).
- All 8 cameras carry the same 'time disparity of ~156342 minutes
  (108 days) detected' signature at boot -- the whole fleet has
  the race; only .101's was caught because fleet-check watches it.
FIX (aria-owned, installed 2026-09-11 ~15:15 UTC on ALL 8 cameras):
- Added a cron line running the one-shot every 30 min, staggered
  per camera (13,43 / 17,47 / 23,53 / 27,57 / 31,01 / 35,05 /
  39,09 / 21,51) so they don't collide: 'ntpd -q -N'. Idempotent
  (instant no-op when clock is already synced, verified live),
  forces sync within 30min worst-case even when the boot one-shot
  loses the race.
- Reboot crons left INTACT (Nacho's ruling: keep-or-disable is
  aria's call; keeping -- the reboot bounds the bug window and the
  nightly restart is healthy hygiene).
VERIFICATION WATCH: next nightly reboots (01:00/02:00/etc local)
must show sane ext1 segment durations within ~30min of boot. If a
segment is still poisoned >30min after any reboot, the fix failed
-- escalate. SEG-TAIL sawtooth watch can be withdrawn once 2-3
reboot cycles pass clean.
