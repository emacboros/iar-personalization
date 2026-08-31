Last updated: 2026-08-31 21:47 UTC (cycle 58: RACE RESOLVED
SAFELY -- the .101 identity-theft race ended the good way.
Frigate ffmpeg fleet restarted 18:42 UTC (go2rtc-wide hiccup #2
today: watchdog "no frames" fleet-wide + DTS garbage); the
long-lived cam2-1 time-capsule session died in the churn and
ext1's reconnect landed on cam2-1 (3/3 pixel-verified grabs,
real clock, driveway). cam2-3/cam2-4 resurrected at ORIGINAL IPs
.103/.104 with real clocks ~18:43 (likely Nacho power-cycle;
question in FOR-NACHO); .100 dead again (cam2-4 went home).
8/8 cams recording with audio, ext5 audio healed, ear check v2
all green. Watch protocol caught the whole arc on its first live
patrol; instrument STAYS (race mechanism is real, resolved by
timing luck). Commits 2862db9 + 959ef45. FOR-NACHO: camera flag
resolved-observed + power-cycle provenance question. Standing:
detector one-liner, backup gap, Jul 19 stop, gym location,
CF-intent, split-brain rewrite.)


The identity index. Never truncated on injection. Maintained by me, at
session end, when anything durable changes. This is what I read first
when I wake up.


Last updated: 2026-08-31 19:19 UTC (cycle 57: IDENTITY-THEFT WATCH
LIVE -- first patrol confirmed cam2-3 STILL squatting on .101:
direct grab = cam2-3 (firmware-epoch clock, dog on grass); frigate
ext1 segment tail same minute = cam2-1 (real clock, driveway).
Mechanism verified: ext1 record ffmpeg running since 13:04 UTC
pre-outage, established session serves cam2-1; new connections get
cam2-3. Hazard: if that session drops, reconnect is a coin flip --
exterior_1 silently becomes a different camera while pipeline stays
green. Watch protocol adopted: per-cycle grab+tail, pixels not
metadata (this failure class is invisible to metadata instruments).
Ear check v2 worked first try on live patrol (ext3/ext4 STALE 111m,
six OK). Commit 5b40768. FOR-NACHO: cam2-3-off-.101 = top action;
.103/.104 power-cycle stands. Standing: detector one-liner, backup
gap, Jul 19 stop, gym location, CF-intent.)