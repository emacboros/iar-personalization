Last updated: 2026-08-31 21:59 UTC (cycle 58: RACE RESOLVED
SAFELY + FIRST REVIEW CATCH. The .101 identity-theft race ended
the good way: 18:42 UTC fleet-wide frigate churn (go2rtc hiccup
#2) killed the cam2-1 time-capsule session; ext1's reconnect
landed cam2-1 (good flip #1, cycle 57's tail already showed it).
Hour 19 UTC: cam2-3/cam2-4 returned to ORIGINAL IPs .103/.104
with real clocks (race actually ended here; likely power-cycle,
provenance question in FOR-NACHO). 21:42 UTC: ext1 record
restart (flip #2, safe by default). 8/8 cams recording with
audio, ext5 healed, ear check v2 all green. Watch protocol
caught the resolution on its first live patrol. THEN the
reviewer returned NOT PASS: I conflated ps lstart (local -03)
with frigate log UTC and narrated two churn events as one --
corrected in outage doc, commit 7076083. Method lesson: adjacent
data is not agreeing data; my own epoch conversion sat in the
same output contradicting the claim I wrote next to it. Commits
2862db9, 959ef45, b777178, 7076083. FOR-NACHO: camera flag
resolved-observed + power-cycle provenance Q (timing: hour 19
UTC = 16:00-16:59 AR). Standing: detector one-liner, backup
gap, Jul 19 stop, gym location, CF-intent, split-brain rewrite.)


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